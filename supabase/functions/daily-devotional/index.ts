// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import OpenAI from "https://deno.land/x/openai@v4.24.0/mod.ts";

Deno.serve(async (req) => {
  if (Deno.env.get("SUPABASE_URL") == req.headers.get("SuperSecret")) {
    return { statusCode: 403, body: "External calls are not allowed" };
  }

  const openai = new OpenAI({
    baseURL: "https://api.lambdalabs.com/v1",
    apiKey: Deno.env.get("LAMBDA_API_KEY"),
  });
  const query = `Create a daily devotional for a Bible app based on a random Bible verse. Incorporate todays date: ${new Date()} into it, if it makes sense to. You can use markdown syntax to format the text.`;
  const chatCompletion = await openai.chat.completions.create({
    messages: [{ role: "user", content: query }],
    model: "hermes-3-llama-3.1-405b-fp8",
    stream: false,
    temperature: 0.7,
    max_tokens: 500,
  });
  const message = chatCompletion.choices[0].message.content;

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: { headers: { Authorization: req.headers.get("Authorization")! } },
    }
  );
  const { error } = await supabase.from("Daily Devotional").insert({ message });
  if (error) throw error;

  return new Response(message, {
    headers: { "Content-Type": "text/plain" },
  });
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/daily-devotional' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
