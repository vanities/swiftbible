import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import Stripe from "npm:stripe@15.8.0";
import { initSentry, captureException } from "../_shared/sentry.ts";

type JsonResponseBody = Record<string, unknown> | null;

type DonationRecord = {
  stripe_session_id: string;
  stripe_payment_intent_id?: string | null;
  amount_cents: number;
  currency: string;
  status: string;
  refunded_amount_cents?: number;
  anonymous_id?: string | null;
  user_id?: string | null;
  donor_email?: string | null;
  metadata: Record<string, unknown>;
};

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const STRIPE_DONATION_WEBHOOK_SECRET =
  Deno.env.get("STRIPE_DONATION_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SUPABASE_SERVICE_KEY") ??
  "";

if (!STRIPE_SECRET_KEY) {
  throw new Error("Missing STRIPE_SECRET_KEY environment variable");
}

if (!STRIPE_DONATION_WEBHOOK_SECRET) {
  throw new Error("Missing STRIPE_DONATION_WEBHOOK_SECRET environment variable");
}

if (!SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY environment variable");
}

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {});

initSentry("stripe-donation-webhook");

Deno.serve(async (req) => {
  console.log("[stripe-donation-webhook] request", {
    method: req.method,
    headers: Object.fromEntries(req.headers.entries()),
  });

  if (req.method === "GET") {
    // simple health check
    return jsonResponse({ ok: true }, 200);
  }

  if (req.method !== "POST") {
    console.warn("[stripe-donation-webhook] rejected non-POST", req.method);
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    console.warn("[stripe-donation-webhook] missing stripe-signature header");
    return jsonResponse({ error: "Missing stripe-signature header" }, 400);
  }

  const body = await req.text();

  console.log("[stripe-donation-webhook] raw body length", body.length);

  const payload = new TextEncoder().encode(body);

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      payload,
      signature,
      STRIPE_DONATION_WEBHOOK_SECRET,
    );
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Webhook signature verification failed";
    console.error("[stripe-donation-webhook] verification failed", message);
    await captureException(error, {
      functionName: "stripe-donation-webhook",
      tags: { error_type: "signature_verification" },
    });
    return jsonResponse({ error: message }, 400);
  }

  console.log("[stripe-donation-webhook] event", {
    id: event.id,
    type: event.type,
    created: event.created,
  });

  try {
    switch (event.type) {
      case "checkout.session.completed":
      case "checkout.session.async_payment_succeeded": {
        const session = event.data.object as Stripe.Checkout.Session;
        console.log("[stripe-donation-webhook] processing success", {
          sessionId: session.id,
          paymentStatus: session.payment_status,
          amountTotal: session.amount_total,
        });
        await upsertDonationFromSession(session);
        break;
      }
      case "checkout.session.async_payment_failed": {
        const session = event.data.object as Stripe.Checkout.Session;
        console.warn("[stripe-donation-webhook] async payment failed", {
          sessionId: session.id,
          paymentStatus: session.payment_status,
        });
        await markDonationFailed(session, "async_payment_failed");
        break;
      }
      case "charge.refunded": {
        const charge = event.data.object as Stripe.Charge;
        await markDonationRefunded(charge);
        break;
      }
      default:
        console.log(`[stripe-donation-webhook] unhandled event type ${event.type}`);
    }
  } catch (error) {
    console.error("[stripe-donation-webhook] handler error", error);
    await captureException(error, {
      functionName: "stripe-donation-webhook",
      extra: { eventType: event.type, eventId: event.id },
    });
    return jsonResponse({ error: "Webhook processing failed" }, 500);
  }

  return jsonResponse({ received: true }, 200);
});

async function upsertDonationFromSession(
  session: Stripe.Checkout.Session,
): Promise<void> {
  console.log("[stripe-donation-webhook] upserting donation", {
    sessionId: session.id,
    paymentStatus: session.payment_status,
    anonymousId: session.client_reference_id,
    amountTotal: session.amount_total,
  });
  const metadata = session.metadata ?? {};
  const anonymousId =
    metadata.anonymous_id ?? session.client_reference_id ?? null;
  const userId = metadata.user_id ?? null;
  const currency = (session.currency ?? metadata.currency ?? "usd").toLowerCase();
  const amountCents = session.amount_total ??
    (typeof metadata.amount_cents === "string"
      ? Number.parseInt(metadata.amount_cents, 10)
      : Number(metadata.amount_cents ?? 0));

  if (!Number.isFinite(amountCents) || amountCents <= 0) {
    console.warn(
      "Skipping donation upsert due to invalid amount",
      amountCents,
      session.id,
    );
    return;
  }

  const paymentIntentId = extractPaymentIntentId(session.payment_intent);
  const status = session.payment_status ?? "unpaid";

  const donation: DonationRecord = {
    stripe_session_id: session.id,
    stripe_payment_intent_id: paymentIntentId,
    amount_cents: Math.round(amountCents),
    currency,
    status,
    refunded_amount_cents: 0,
    anonymous_id: anonymousId,
    user_id: userId,
    donor_email: session.customer_details?.email ?? session.customer_email ?? null,
    metadata,
  };

  const cleanedDonation = removeUndefined(donation);

  const { error } = await supabase
    .from("donations")
    .upsert(cleanedDonation, { onConflict: "stripe_session_id" });

  if (error) {
    console.error("[stripe-donation-webhook] upsert failed", error, donation);
    throw new Error(error.message);
  }

  console.log("[stripe-donation-webhook] upsert complete", donation);
}

async function markDonationFailed(
  session: Stripe.Checkout.Session,
  status: string,
): Promise<void> {
  console.log("[stripe-donation-webhook] marking failure", {
    sessionId: session.id,
    status,
  });
  const { error } = await supabase
    .from("donations")
    .update({ status })
    .eq("stripe_session_id", session.id);

  if (error) {
    console.error("[stripe-donation-webhook] failed to mark donation as failed", error, session.id);
    throw new Error(error.message);
  }
}

function extractPaymentIntentId(
  paymentIntent: string | Stripe.PaymentIntent | null,
): string | null {
  if (!paymentIntent) return null;
  if (typeof paymentIntent === "string") return paymentIntent;
  return paymentIntent.id;
}



async function markDonationRefunded(charge: Stripe.Charge): Promise<void> {
  const paymentIntentId = typeof charge.payment_intent === "string"
    ? charge.payment_intent
    : charge.payment_intent?.id ?? null;

  if (!paymentIntentId) {
    console.warn("[stripe-donation-webhook] charge refund missing payment_intent", charge.id);
    return;
  }

  const amountRefunded = charge.amount_refunded ?? 0;
  const currency = charge.currency ?? "usd";
  const refunds = charge.refunds?.data ?? [];
  const latestRefund = refunds.length > 0 ? refunds[refunds.length - 1] : null;
  const refundId = typeof latestRefund?.id === "string" ? latestRefund!.id : charge.id;
  const refundStatus = amountRefunded >= (charge.amount_captured ?? amountRefunded)
    ? "refunded"
    : "partially_refunded";

  const { data, error } = await supabase
    .from("donations")
    .select("metadata")
    .eq("stripe_payment_intent_id", paymentIntentId)
    .maybeSingle();

  if (error) {
    console.error("[stripe-donation-webhook] failed to fetch donation for refund", error);
    return;
  }

  const metadata = (data?.metadata ?? {}) as Record<string, unknown>;
  const existingRefunds = Array.isArray(metadata.refunds)
    ? metadata.refunds as Array<Record<string, unknown>>
    : [];

  existingRefunds.push({
    refund_id: refundId,
    amount_cents: amountRefunded,
    currency,
    processed_at: new Date().toISOString(),
  });

  metadata.refunds = existingRefunds;

  const updates = {
    status: refundStatus,
    refunded_amount_cents: amountRefunded,
    metadata,
  };

  const { error: updateError } = await supabase
    .from("donations")
    .update(updates)
    .eq("stripe_payment_intent_id", paymentIntentId);

  if (updateError) {
    console.error(
      "[stripe-donation-webhook] failed to mark donation as refunded",
      updateError,
      paymentIntentId,
    );
    throw new Error(updateError.message);
  }

  console.log("[stripe-donation-webhook] marked donation as refunded", {
    paymentIntentId,
    amountRefunded,
    refundStatus,
  });
}
function removeUndefined<T extends Record<string, unknown>>(value: T): T {
  const entries = Object.entries(value).filter(([, v]) => v !== undefined);
  return Object.fromEntries(entries) as T;
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
