// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const BIBLE_API_URL = "https://bible-api.com/?random=verse&translation=kjv";
const LAMBDA_LABS_URL = "https://api.lambdalabs.com/v1/chat/completions";

Deno.serve(async (req) => {
  if (Deno.env.get("SUPABASE_URL") == req.headers.get("SuperSecret")) {
    return { statusCode: 403, body: "External calls are not allowed" };
  }

  const verseData = await fetchRandomVerse();
  console.log(
    `Selected Verse: ${verseData.reference} - ${verseData.text.trim()}`
  );

  // Step 2: Format today's date
  const formattedDate = getFormattedDate();
  console.log(`Date: ${formattedDate}`);

  // Step 3: Create the prompt
  const prompt = createPrompt(verseData, formattedDate);
  // Uncomment the line below to see the prompt
  // console.log('Prompt:', prompt);

  // Step 4: Generate the devotional
  const devotional = await generateDevotional(prompt);
  console.log("Generated Devotional:\n", devotional);

  saveDevotional(devotional, req);

  return new Response(devotional, {
    headers: { "Content-Type": "text/plain" },
  });
});

async function fetchRandomVerse() {
  try {
    const response = await fetch(BIBLE_API_URL);

    if (!response.ok) {
      throw new Error(
        `Bible API request failed with status ${response.status}`
      );
    }

    return await response.json();
  } catch (error) {
    console.error("Error fetching verse:", error.message);
    throw error;
  }
}

function getFormattedDate() {
  const today = new Date();
  return today.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

function createPrompt(verseData: any, formattedDate: string): string {
  const verse = verseData.verses[0];
  return `
Create a daily devotional for a Bible app based on the following Bible verse from the King James Version (KJV):

**${verse.book_name} ${verse.chapter}:${verse.verse}** - "${verse.text.trim()}"

Date: ${formattedDate}

Please provide a thoughtful and inspiring devotional using markdown syntax for formatting.
`;
}

async function generateDevotional(prompt: string): Promise<string> {
  try {
    const response = await fetch(LAMBDA_LABS_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${Deno.env.get("LAMBDA_API_KEY")}`,
      },
      body: JSON.stringify({
        model: "hermes-3-llama-3.1-405b-fp8", // You can change this to the model you prefer
        messages: [{ role: "user", content: prompt }],
        temperature: 0.8,
        max_tokens: 750,
      }),
    });
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(
        `OpenAI API request failed with status ${
          response.status
        }: ${JSON.stringify(errorData)}`
      );
    }

    const data = await response.json();
    const devotional = data.choices[0].message.content.trim();
    return devotional;
  } catch (error) {
    console.error(
      "Error generating devotional:",
      error.response ? error.response.data : error.message
    );
    throw error;
  }
}

async function saveDevotional(message: string, req: any): Promise<void> {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: { headers: { Authorization: req.headers.get("Authorization")! } },
    }
  );
  const { error } = await supabase.from("Daily Devotional").insert({ message });
  if (error) throw error;
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/daily-devotional' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
