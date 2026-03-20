import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import Stripe from "npm:stripe@15.8.0";
import { initSentry, captureException } from "../_shared/sentry.ts";

type CreateDonationSessionPayload = {
  amountCents?: number;
  currency?: string;
  anonymousId?: string;
  source?: string;
};

type CreateDonationSessionResponse = {
  url: string;
  sessionId: string;
};

type JsonResponseBody = Record<string, unknown> | null;

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUCCESS_URL_TEMPLATE =
  Deno.env.get("DONATION_SUCCESS_URL") ??
  "https://am2.biz/swiftbible/donate/success?session_id={CHECKOUT_SESSION_ID}";
const CANCEL_URL =
  Deno.env.get("DONATION_CANCEL_URL") ??
  "https://am2.biz/swiftbible/donate/cancel";
const MIN_AMOUNT_CENTS = Number(
  Deno.env.get("DONATION_MIN_AMOUNT_CENTS") ?? "100",
);
const MAX_AMOUNT_CENTS = Number(
  Deno.env.get("DONATION_MAX_AMOUNT_CENTS") ?? "50000",
);

if (!STRIPE_SECRET_KEY) {
  throw new Error("Missing STRIPE_SECRET_KEY environment variable");
}

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

initSentry("create-donation-session");

Deno.serve(async (req) => {
  console.log("[create-donation-session] request", {
    method: req.method,
    headers: Object.fromEntries(req.headers.entries()),
  });

  if (req.method !== "POST") {
    console.warn("[create-donation-session] rejected non-POST", req.method);
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let payload: CreateDonationSessionPayload;
  try {
    payload = await req.json();
  } catch (_) {
    console.warn("[create-donation-session] invalid JSON body");
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  console.log("[create-donation-session] payload", payload);

  const amountCents = normalizeAmount(payload.amountCents);
  if (amountCents === null) {
    console.warn("[create-donation-session] amountCents invalid", payload.amountCents);
    return jsonResponse({
      error: `Missing or invalid amountCents. Minimum is $${(MIN_AMOUNT_CENTS / 100).toFixed(2)}.`,
    }, 400);
  }

  if (amountCents < MIN_AMOUNT_CENTS) {
    console.warn("[create-donation-session] amount below minimum", amountCents);
    return jsonResponse({
      error: `Donation must be at least $${(MIN_AMOUNT_CENTS / 100).toFixed(2)}.`,
    }, 400);
  }

  if (amountCents > MAX_AMOUNT_CENTS) {
    console.warn("[create-donation-session] amount above maximum", amountCents);
    return jsonResponse({
      error: `Donation cannot exceed $${(MAX_AMOUNT_CENTS / 100).toFixed(2)}.`,
    }, 400);
  }

  const anonymousId = sanitizeId(payload.anonymousId);
  if (!anonymousId) {
    console.warn("[create-donation-session] anonymousId missing", payload.anonymousId);
    return jsonResponse({ error: "anonymousId is required" }, 400);
  }

  const currency = sanitizeCurrency(payload.currency);
  const authHeader = req.headers.get("Authorization") ?? "";

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  console.log("[create-donation-session] fetching user", authHeader ? "auth header present" : "no auth header");
  let userId: string | null = null;
  let userEmail: string | undefined;
  try {
    const { data, error } = await supabase.auth.getUser();
    if (!error && data?.user) {
      userId = data.user.id;
      userEmail = data.user.email ?? undefined;
      console.log("[create-donation-session] user resolved", { userId, userEmail });
    }
  } catch (error) {
    console.warn("[create-donation-session] getUser failed", error);
  }

  const metadata: Record<string, string> = {
    app: "swiftbible",
    anonymous_id: anonymousId,
    amount_cents: String(amountCents),
    currency,
  };

  if (userId) {
    metadata.user_id = userId;
  }

  if (payload.source) {
    metadata.source = String(payload.source);
  }

  const successUrl = buildSuccessUrl(SUCCESS_URL_TEMPLATE);

  console.log("[create-donation-session] creating session", {
    amountCents,
    currency,
    anonymousId,
    userId,
    successUrl,
    cancelUrl: CANCEL_URL,
    metadata,
  });

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      submit_type: "donate",
      allow_promotion_codes: true,
      success_url: successUrl,
      cancel_url: CANCEL_URL,
      client_reference_id: anonymousId,
      customer_email: userEmail,
      metadata,
      payment_intent_data: { metadata },
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency,
            unit_amount: amountCents,
            product_data: {
              name: "swiftbible Donation",
              description:
                "Support swiftbible server hosting and Apple developer fees.",
            },
          },
        },
      ],
    });

    const response: CreateDonationSessionResponse = {
      url: session.url!,
      sessionId: session.id,
    };

    console.log("[create-donation-session] session created", response);
    return jsonResponse(response, 200);
  } catch (error) {
    console.error("[create-donation-session] Stripe session creation failed", error);
    await captureException(error, {
      functionName: "create-donation-session",
      extra: { amountCents, currency, anonymousId },
    });
    return jsonResponse({ error: "Unable to create donation session" }, 500);
  }
});

function normalizeAmount(value?: number): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }
  return Math.round(value);
}

function sanitizeCurrency(currency?: string): string {
  const fallback = "usd";
  if (!currency || typeof currency !== "string") return fallback;
  const trimmed = currency.trim().toLowerCase();
  return /^[a-z]{3}$/.test(trimmed) ? trimmed : fallback;
}

function sanitizeId(identifier?: string): string | null {
  if (!identifier || typeof identifier !== "string") return null;
  const trimmed = identifier.trim();
  if (trimmed.length < 6 || trimmed.length > 128) return null;
  return trimmed;
}

function buildSuccessUrl(template: string): string {
  if (template.includes("{CHECKOUT_SESSION_ID}")) {
    return template;
  }
  const separator = template.includes("?") ? "&" : "?";
  return `${template}${separator}session_id={CHECKOUT_SESSION_ID}`;
}

function jsonResponse(body: JsonResponseBody, status = 200): Response {
  return new Response(body ? JSON.stringify(body) : null, {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
