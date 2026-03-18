import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type DonationStatusPayload = {
  anonymousId?: string;
  sessionId?: string;
};

type DonationStatusResponse = {
  hasDonated: boolean;
  latestDonation?: {
    stripe_session_id: string;
    amount_cents: number;
    currency: string;
    status: string;
    created_at: string;
  } | null;
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

denoServe();

function denoServe() {
  Deno.serve(async (req) => {
    console.log("[donation-status] request", {
      method: req.method,
      headers: Object.fromEntries(req.headers.entries()),
    });

    if (req.method !== "POST") {
      console.warn("[donation-status] rejected non-POST", req.method);
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    let payload: DonationStatusPayload;
    try {
      payload = await req.json();
    } catch (_) {
      console.warn("[donation-status] invalid JSON body");
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const anonymousId = sanitizeId(payload.anonymousId);
    if (!anonymousId) {
      console.warn("[donation-status] missing anonymousId", payload.anonymousId);
      return jsonResponse({ error: "anonymousId is required" }, 400);
    }

    const sessionId = sanitizeSessionId(payload.sessionId);

    const authHeader = req.headers.get("Authorization") ?? "";

    const supabaseUserClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    let userId: string | null = null;
    try {
      const { data, error } = await supabaseUserClient.auth.getUser();
      if (!error && data?.user) {
        userId = data.user.id;
        console.log("[donation-status] resolved user", userId);
      }
    } catch (error) {
      console.warn("getUser failed", error);
    }

    const supabaseServiceClient = createClient(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {},
    );

    console.log("[donation-status] querying donations", {
      filterByUser: Boolean(userId),
      anonymousId,
      sessionId,
    });

    let query = supabaseServiceClient
      .from("donations")
      .select(
        "stripe_session_id, amount_cents, currency, status, refunded_amount_cents, created_at",
        { count: "exact" },
      )
      .in("status", ["paid", "partially_refunded"])
      .order("created_at", { ascending: false })
      .limit(1);

    if (sessionId) {
      query = query.eq("stripe_session_id", sessionId);
    } else if (userId) {
      // Check both user_id and anonymous_id so legacy Stripe donations
      // (created before anonymous auth) are still found
      query = query.or(`user_id.eq.${userId},anonymous_id.eq.${anonymousId}`);
    } else {
      query = query.eq("anonymous_id", anonymousId);
    }

    const { data, count, error } = await query;
    if (error) {
      console.error("[donation-status] query failed", error);
      return jsonResponse({ error: "Unable to fetch donation status" }, 500);
    }

    const latest = data?.[0] ?? null;

    const response: DonationStatusResponse = {
      hasDonated: (count ?? data?.length ?? 0) > 0,
      latestDonation: latest ?? null,
    };

    console.log("[donation-status] response", response);
    return jsonResponse(response, 200);
  });
}

function sanitizeId(identifier?: string): string | null {
  if (!identifier || typeof identifier !== "string") return null;
  const trimmed = identifier.trim();
  if (trimmed.length < 6 || trimmed.length > 128) return null;
  return trimmed;
}

function sanitizeSessionId(identifier?: string): string | null {
  if (!identifier || typeof identifier !== "string") return null;
  const trimmed = identifier.trim();
  if (trimmed.length === 0) return null;
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
