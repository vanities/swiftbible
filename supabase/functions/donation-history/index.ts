import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { initSentry, captureException } from "../_shared/sentry.ts";

type DonationHistoryPayload = {
  anonymousId?: string;
};

type DonationHistoryResponse = {
  totalPaidCents: number;
  totalRefundedCents: number;
  netDonatedCents: number;
  donations: Array<DonationHistoryItem>;
};

type DonationHistoryItem = {
  stripe_session_id: string;
  amount_cents: number;
  currency: string;
  status: string;
  refunded_amount_cents: number;
  created_at: string;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SUPABASE_SERVICE_KEY") ??
  "";

if (!SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY environment variable");
}

initSentry("donation-history");

Deno.serve(async (req) => {
  console.log("[donation-history] request", {
    method: req.method,
    headers: Object.fromEntries(req.headers.entries()),
  });

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let payload: DonationHistoryPayload;
  try {
    payload = await req.json();
  } catch (_) {
    console.warn("[donation-history] invalid JSON body");
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const anonymousId = sanitizeId(payload.anonymousId);
  if (!anonymousId) {
    console.warn("[donation-history] missing anonymousId", payload.anonymousId);
    return jsonResponse({ error: "anonymousId is required" }, 400);
  }

  const authHeader = req.headers.get("Authorization") ?? "";

  const supabaseUserClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  let userId: string | null = null;
  try {
    const { data, error } = await supabaseUserClient.auth.getUser();
    if (!error && data?.user) {
      userId = data.user.id;
      console.log("[donation-history] resolved user", userId);
    }
  } catch (error) {
    console.warn("[donation-history] getUser failed", error);
  }

  const supabaseServiceClient = createClient(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    {},
  );

  let query = supabaseServiceClient
    .from("donations")
    .select(
      "stripe_session_id, amount_cents, currency, status, refunded_amount_cents, created_at",
    )
    .order("created_at", { ascending: false });

  if (userId) {
    // Check both user_id and anonymous_id so legacy Stripe donations
    // (created before anonymous auth) are still found
    query = query.or(`user_id.eq.${userId},anonymous_id.eq.${anonymousId}`);
  } else {
    query = query.eq("anonymous_id", anonymousId);
  }

  const { data, error } = await query;
  if (error) {
    console.error("[donation-history] query failed", error);
    await captureException(new Error(error.message), {
      functionName: "donation-history",
      extra: { anonymousId, userId },
    });
    return jsonResponse({ error: "Unable to fetch donation history" }, 500);
  }

  const donations = data ?? [];
  const totalPaidCents = donations.reduce((sum, item) => sum + item.amount_cents, 0);
  const totalRefundedCents = donations.reduce(
    (sum, item) => sum + (item.refunded_amount_cents ?? 0),
    0,
  );
  const netDonatedCents = totalPaidCents - totalRefundedCents;

  const response: DonationHistoryResponse = {
    totalPaidCents,
    totalRefundedCents,
    netDonatedCents,
    donations,
  };

  console.log("[donation-history] response", {
    donationCount: donations.length,
    totalPaidCents,
    totalRefundedCents,
    netDonatedCents,
  });

  return jsonResponse(response, 200);
});

function sanitizeId(identifier?: string): string | null {
  if (!identifier || typeof identifier !== "string") return null;
  const trimmed = identifier.trim();
  if (trimmed.length < 6 || trimmed.length > 128) return null;
  return trimmed;
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
