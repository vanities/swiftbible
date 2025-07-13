// Generate verse information using LLM and store it
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const LAMBDA_LABS_URL = "https://api.lambdalabs.com/v1/chat/completions";

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    const { book, chapter, starting_verse, version, text } = body;

    const prompt = createPrompt(book, chapter, starting_verse, text);
    const info = await generateInfo(prompt);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { error } = await supabase
      .from("Verse Info")
      .upsert(
        {
          version,
          book,
          chapter,
          starting_verse,
          info,
        },
        { onConflict: "version,book,chapter,starting_verse" }
      );
    if (error) throw error;

    return new Response(info, { headers: { "Content-Type": "text/plain" } });
  } catch (error) {
    console.error("Error generating verse info:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }
});

function createPrompt(
  book: string,
  chapter: number,
  verse: number,
  text: string
): string {
  return `You are a Bible commentary generator.\n1. Summarize the words and themes.\n2. Define uncommon words.\n3. Reference Greek or Hebrew words depending on testament.\n\n${book} ${chapter}:${verse} - "${text.trim()}"`;
}

async function generateInfo(prompt: string): Promise<string> {
  const response = await fetch(LAMBDA_LABS_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${Deno.env.get("LAMBDA_API_KEY")}`,
    },
    body: JSON.stringify({
      model: "hermes-3-llama-3.1-405b-fp8",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.7,
      max_tokens: 800,
    }),
  });
  if (!response.ok) {
    const data = await response.json();
    throw new Error(`LLM request failed: ${response.status} ${JSON.stringify(data)}`);
  }
  const data = await response.json();
  return data.choices[0].message.content.trim();
}
