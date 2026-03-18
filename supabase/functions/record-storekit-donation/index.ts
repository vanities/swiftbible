import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type StoreKitDonationPayload = {
  transactionId: string;
  productId: string;
  amountCents: number;
  currency: string;
  purchaseDate: string;
  anonymousId: string;
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

Deno.serve(async (req) => {
  console.log("[record-storekit-donation] request", { method: req.method });

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let payload: StoreKitDonationPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { transactionId, productId, amountCents, currency, purchaseDate, anonymousId } = payload;

  if (!transactionId || !amountCents || !anonymousId) {
    return jsonResponse({ error: "transactionId, amountCents, and anonymousId are required" }, 400);
  }

  if (amountCents <= 0) {
    return jsonResponse({ error: "amountCents must be positive" }, 400);
  }

  const sanitizedAnonId = anonymousId.trim();
  if (sanitizedAnonId.length < 6 || sanitizedAnonId.length > 128) {
    return jsonResponse({ error: "Invalid anonymousId" }, 400);
  }

  // Resolve authenticated user if available
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabaseUserClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  let userId: string | null = null;
  try {
    const { data, error } = await supabaseUserClient.auth.getUser();
    if (!error && data?.user) {
      userId = data.user.id;
    }
  } catch (_) {
    // Non-critical
  }

  const sessionKey = `appstore_${transactionId}`;

  const supabaseServiceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {});

  // Upsert to handle duplicate transaction IDs (idempotent)
  const { data, error } = await supabaseServiceClient
    .from("donations")
    .upsert(
      {
        stripe_session_id: sessionKey,
        user_id: userId,
        anonymous_id: sanitizedAnonId,
        amount_cents: amountCents,
        currency: (currency || "usd").toLowerCase(),
        status: "paid",
        metadata: {
          source: "storekit",
          product_id: productId,
          purchase_date: purchaseDate,
        },
      },
      { onConflict: "stripe_session_id" }
    )
    .select("stripe_session_id, amount_cents, currency, status, created_at")
    .single();

  if (error) {
    console.error("[record-storekit-donation] upsert failed", error);
    return jsonResponse({ error: "Failed to record donation" }, 500);
  }

  console.log("[record-storekit-donation] recorded", {
    sessionKey,
    amountCents,
    userId,
    anonymousId: sanitizedAnonId,
  });

  return jsonResponse({ success: true, donation: data }, 200);
});

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
