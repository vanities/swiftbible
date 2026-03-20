// Lightweight Sentry client for Supabase Edge Functions.
// Uses the Sentry HTTP envelope API directly — no SDK dependencies.

const SENTRY_DSN = Deno.env.get("SENTRY_DSN") ?? "";

let sentryEnabled = false;
let sentryPublicKey = "";
let sentryHost = "";
let sentryProjectId = "";

export function initSentry(functionName: string): void {
  if (!SENTRY_DSN) {
    console.warn(`[${functionName}] SENTRY_DSN not set — error reporting disabled`);
    return;
  }
  try {
    const url = new URL(SENTRY_DSN);
    sentryPublicKey = url.username;
    sentryHost = `${url.protocol}//${url.host}`;
    sentryProjectId = url.pathname.replace(/\//g, "");
    sentryEnabled = true;
  } catch {
    console.warn(`[${functionName}] Invalid SENTRY_DSN`);
  }
}

export async function captureException(
  error: unknown,
  context?: {
    functionName?: string;
    tags?: Record<string, string>;
    extra?: Record<string, unknown>;
  },
): Promise<void> {
  const err = error instanceof Error ? error : new Error(String(error));

  if (!sentryEnabled) {
    console.error("[sentry] disabled, error:", err.message);
    return;
  }

  const eventId = crypto.randomUUID().replace(/-/g, "");
  const timestamp = Date.now() / 1000;

  const event = {
    event_id: eventId,
    timestamp,
    platform: "javascript" as const,
    level: "error" as const,
    server_name: "supabase-edge",
    environment: Deno.env.get("ENVIRONMENT") ?? "production",
    exception: {
      values: [
        {
          type: err.name,
          value: err.message,
          stacktrace: err.stack
            ? { frames: parseStack(err.stack) }
            : undefined,
        },
      ],
    },
    tags: {
      runtime: "deno",
      ...(context?.functionName ? { function: context.functionName } : {}),
      ...context?.tags,
    },
    extra: context?.extra ?? {},
  };

  const envelopeHeader = JSON.stringify({
    event_id: eventId,
    dsn: SENTRY_DSN,
    sent_at: new Date().toISOString(),
  });
  const itemHeader = JSON.stringify({
    type: "event",
    content_type: "application/json",
  });
  const envelope = `${envelopeHeader}\n${itemHeader}\n${JSON.stringify(event)}`;

  const ingestUrl = `${sentryHost}/api/${sentryProjectId}/envelope/`;

  try {
    const resp = await fetch(ingestUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-sentry-envelope",
        "X-Sentry-Auth": `Sentry sentry_version=7, sentry_key=${sentryPublicKey}`,
      },
      body: envelope,
    });
    if (!resp.ok) {
      console.warn("[sentry] ingest responded", resp.status);
    }
  } catch (e) {
    console.error("[sentry] failed to send event:", e);
  }
}

function parseStack(
  stack: string,
): Array<{ filename: string; function: string; lineno?: number; colno?: number }> {
  return stack
    .split("\n")
    .slice(1)
    .map((line) => {
      const match = line.match(/at\s+(.+?)\s+\((.+?):(\d+):(\d+)\)/);
      if (match) {
        return {
          function: match[1],
          filename: match[2],
          lineno: Number(match[3]),
          colno: Number(match[4]),
        };
      }
      const simpleMatch = line.match(/at\s+(.+?):(\d+):(\d+)/);
      if (simpleMatch) {
        return {
          function: "<anonymous>",
          filename: simpleMatch[1],
          lineno: Number(simpleMatch[2]),
          colno: Number(simpleMatch[3]),
        };
      }
      return { function: "<unknown>", filename: line.trim() };
    })
    .reverse();
}
