import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { captureException, initSentry } from "../_shared/sentry.ts";

type ClientPlatform = "ios" | "android";

type GetDailyDevotionalPayload = {
  forDate?: string;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SUPABASE_SERVICE_KEY") ??
  "";
const DEVOTIONAL_READ_SECRET = Deno.env.get("DEVOTIONAL_READ_SECRET") ?? "";

const DEFAULT_IOS_BUNDLE_IDS = ["com.vanities.swiftbible"];
const DEFAULT_ANDROID_PACKAGE_IDS = ["biz.am2.swiftbible"];

const ALLOWED_IOS_BUNDLE_IDS = parseCsvEnv(
  "ALLOWED_IOS_BUNDLE_IDS",
  DEFAULT_IOS_BUNDLE_IDS,
);
const ALLOWED_ANDROID_PACKAGE_IDS = parseCsvEnv(
  "ALLOWED_ANDROID_PACKAGE_IDS",
  DEFAULT_ANDROID_PACKAGE_IDS,
);

const PUBLIC_SELECT_COLUMNS = [
  "id",
  "message",
  "for_date",
  "devotional_type",
  "series_name",
  "series_part",
  "holiday_name",
  "holiday_url",
  "anchor_verse",
  "verses",
  "model",
  "track",
].join(",");

if (!SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY environment variable");
}

initSentry("get-daily-devotional");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const appCheck = validateAppHeaders(req.headers);
  if (!appCheck.ok) {
    console.warn("[get-daily-devotional] rejected app check", appCheck.reason);
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  try {
    const payload = await parsePayload(req);
    const forDate = payload.forDate?.trim() || todayISO();

    if (!isValidISODate(forDate)) {
      return jsonResponse({ error: "Invalid forDate" }, 400);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data, error } = await supabase
      .from("Daily Devotional")
      .select(PUBLIC_SELECT_COLUMNS)
      .eq("for_date", forDate)
      .single();

    if (error || !data) {
      if (error) {
        console.warn("[get-daily-devotional] lookup failed", error.message);
      }
      return jsonResponse({ error: "Not found" }, 404);
    }

    return jsonResponse(data as unknown as Record<string, unknown>, 200, {
      "Cache-Control": "public, max-age=300",
    });
  } catch (error) {
    console.error("[get-daily-devotional] handler error", error);
    await captureException(error, { functionName: "get-daily-devotional" });
    return jsonResponse({ error: "Failed to fetch devotional" }, 500);
  }
});

async function parsePayload(req: Request): Promise<GetDailyDevotionalPayload> {
  try {
    const body = await req.json();
    return typeof body === "object" && body !== null ? body : {};
  } catch (_) {
    return {};
  }
}

function validateAppHeaders(headers: Headers):
  | { ok: true; platform: ClientPlatform; appId: string }
  | { ok: false; reason: string } {
  if (DEVOTIONAL_READ_SECRET) {
    const providedSecret = headers.get("x-swiftbible-client-key") ?? "";
    if (providedSecret !== DEVOTIONAL_READ_SECRET) {
      return { ok: false, reason: "missing_or_invalid_client_key" };
    }
  }

  const platform = headers.get("x-swiftbible-platform")?.toLowerCase();
  if (platform !== "ios" && platform !== "android") {
    return { ok: false, reason: "missing_or_invalid_platform" };
  }

  const headerName = platform === "ios"
    ? "x-swiftbible-bundle-id"
    : "x-swiftbible-package-name";
  const appId = headers.get(headerName)?.trim() ?? "";
  const allowedIds = platform === "ios"
    ? ALLOWED_IOS_BUNDLE_IDS
    : ALLOWED_ANDROID_PACKAGE_IDS;

  if (!allowedIds.includes(appId)) {
    return { ok: false, reason: `unrecognized_${platform}_app_id` };
  }

  return { ok: true, platform, appId };
}

function parseCsvEnv(name: string, fallback: string[]): string[] {
  const raw = Deno.env.get(name) ?? "";
  const parsed = raw
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  return parsed.length > 0 ? parsed : fallback;
}

function todayISO(): string {
  return new Date().toISOString().slice(0, 10);
}

function isValidISODate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(parsed.getTime()) &&
    parsed.toISOString().slice(0, 10) === value;
}

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders(),
      ...extraHeaders,
      "Content-Type": "application/json",
    },
  });
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": [
      "authorization",
      "content-type",
      "x-client-info",
      "apikey",
      "x-swiftbible-platform",
      "x-swiftbible-bundle-id",
      "x-swiftbible-package-name",
      "x-swiftbible-client-key",
    ].join(", "),
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}
