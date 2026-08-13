-- Strip leaked <JESUS>...</JESUS> red-letter markup from published devotionals.
--
-- bible.json wraps Jesus's words in <JESUS> tags for red-letter rendering.
-- The Edge Function stripped them in lookupVerseText() (the holiday and
-- multi-verse paths), but selectRandomVerse() returned paragraph.text raw —
-- so ordinary single-verse devotionals inlined the tags straight into the
-- required verse blockquote. Readers saw, verbatim:
--
--   "<JESUS>I am that bread of life. </JESUS>" John 6:48
--
-- (Aug 12, 2026 — John 6:48, narrative track.) The generator now routes every
-- path through stripJesusTags(); this repairs the rows already published,
-- which the code fix cannot reach.
--
-- Only the tags go — never the whitespace hugging them. 418 KJV paragraphs
-- carry an inline verse number between two tags ("…against thee; </JESUS>5:24
-- <JESUS> Leave there…"), so eating the adjacent space would run words and
-- verse numbers together. That leaves one space inside the closing quote of an
-- affected blockquote, which renders as nothing; joining words would not.
--
-- The `prompt` column deliberately keeps its tags: it is the audit record of
-- the text actually sent to the model, not something a reader ever sees.
UPDATE public."Daily Devotional"
   SET message = regexp_replace(message, '</?JESUS>', '', 'g')
 WHERE message LIKE '%JESUS>%';
