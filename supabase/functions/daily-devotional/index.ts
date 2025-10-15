// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const BIBLE_API_URL = "https://bible-api.com/?random=verse&translation=kjv";
const OPENAI_CHAT_URL = "https://api.openai.com/v1/chat/completions";

Deno.serve(async (req) => {
  if (Deno.env.get("SUPABASE_URL") == req.headers.get("SuperSecret")) {
    return { statusCode: 403, body: "External calls are not allowed" };
  }

  const verseData = await fetchRandomVerse();
  console.log(
    `Selected Verse: ${verseData.reference} - ${verseData.text.trim()}`
  );

  // Step 2: Format today's date
  const { formatted, isoDate } = getFormattedDate();
  console.log(`Date: ${formatted}`);

  // Step 3: Create the prompt
  const prompt = createPrompt(verseData, formatted);
  // Uncomment the line below to see the prompt
  // console.log('Prompt:', prompt);
  //

  // Step 4: Generate the devotional
  const devotional = await generateDevotional(prompt);
  console.log("Generated Devotional:\n", devotional);

  saveDevotional(devotional, isoDate, req);

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

function getFormattedDate(): { formatted: string; isoDate: string } {
  const now = new Date();
  const formatted = now.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  const isoDate = now.toISOString().split("T")[0]; // YYYY-MM-DD
  return { formatted, isoDate };
}

function createPrompt(verseData: any, formattedDate: string): string {
  const verse = verseData.verses[0];
  return `
Create a daily devotional for a Bible app based on the following Bible verse from the King James Version (KJV):

${verse.book_name} ${verse.chapter}:${verse.verse} - "${verse.text.trim()}"

Date: ${formattedDate}

Devotional Guidelines:

1. Title as a Heading: Use # for the title at the very top. Include the date and passage reference in this title.

2. Subtitle (Context Summary Only): Provide a **bolded thematic summary** line immediately below the title that captures the main theme. DO NOT include the date or passage reference in this subtitle - only the theological/spiritual theme.

Example Markdown Structure

# October 5 - 2 Kings 2:3: A Season of Transition and Readiness

**Elijah's departure and Elisha's readiness to assume responsibility**

> "And the sons of the prophets that were at Bethel came forth to Elisha, and said unto him, Knowest thou that the LORD will take away thy master from thy head to day? And he said, Yea, I know it; hold ye your peace."
> **2 Kings 2:3**

2. Verse Block Formatting:
   - Place the verse text directly beneath the title and summary in a Markdown blockquote (using >) for emphasis, like this:
     > "${verse.text.trim()}"
     > **${verse.book_name} ${verse.chapter}:${verse.verse}**

3. Devotional Content Formatting:
   - Contextual Background: Begin the devotional with a natural flow, integrating the verse's background, add explicit section headers with ##.
   - Historical and Cultural Insights: Incorporate historical or cultural context within the devotional narrative, providing any relevant customs, events, or traditions to enrich understanding.
   - Linguistic and Translational Insights: Include key Hebrew or Greek words with their meanings and any nuances, seamlessly embedded in the text, to deepen the reader's understanding of the verse’s original intent.

4. Modern Relevance: Guide the reader to relate the passage to contemporary themes or challenges. Encourage them to see how the verse can be applied in their own lives, reflecting on universal themes like change, courage, or faithfulness.

5. Personal Reflection and Application:
   - Include reflective questions or journaling prompts at the end of the devotional, formatted in Markdown as a list for easy reading.
   - Example:
     - How does this verse resonate with a current season of transition in your life?
     - In what ways can you embody the faith or courage exemplified in this passage today?

6. Final Meditation:
   - Close with a short meditation or prayerful reflection to invite the reader into a moment of contemplation. Format this as a final paragraph in italics.
`;
}

async function generateDevotional(prompt: string): Promise<string> {
  try {
    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) throw new Error("Missing OPENAI_API_KEY env var");
    const model = "gpt-5-mini"; // reliable chat model

    const response = await fetch(OPENAI_CHAT_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: [
          {
            role: "system",
            content:
              "You are a Christian devotional writing assistant. Return well-structured Markdown only, no extra commentary.",
          },
          { role: "user", content: prompt },
        ],
        max_completion_tokens: 900,
      }),
    });

    if (!response.ok) {
      let errorText: string | undefined;
      try {
        const errorData = await response.json();
        errorText = JSON.stringify(errorData);
      } catch (_) {
        errorText = await response.text();
      }
      throw new Error(
        `OpenAI Chat Completions failed with status ${response.status}: ${errorText}`
      );
    }

    const data = await response.json();
    const content = data?.choices?.[0]?.message?.content;
    if (typeof content === "string" && content.trim().length > 0) {
      return content.trim();
    }
    // Try tool-less delta accumulation fallback
    const alt = data?.choices?.[0]?.text;
    if (typeof alt === "string" && alt.trim().length > 0) {
      return alt.trim();
    }
    throw new Error("Empty model output from Chat Completions API");
  } catch (error: any) {
    console.error("Error generating devotional:", error?.message ?? error);
    throw error;
  }
}

async function saveDevotional(
  message: string,
  forDate: string,
  req: any
): Promise<void> {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: { headers: { Authorization: req.headers.get("Authorization")! } },
    }
  );
  const { error } = await supabase
    .from("Daily Devotional")
    .upsert({ message, for_date: forDate }, { onConflict: "for_date" });
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
