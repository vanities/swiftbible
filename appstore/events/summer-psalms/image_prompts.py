"""GPT Image 2 prompts for the "Summer in the Psalms" In-App Event.

Consumed by appstore/gen_event_images.py. The palm trees double as a summer
cue and a gentle pun on Psalms. Brand palette: gold + peridot-green + cyan,
deep-navy shadows (see CLAUDE.md "Brand Palette").
"""

_TAG = "This is for my SwiftBible Bible app: https://github.com/vanities/swiftbible"

CARD_PROMPT = (
    "A peaceful summer scene at golden hour: tall palm trees beside a calm, "
    "mirror-still lake, warm sunlight glowing through the fronds, soft green "
    "hills beyond. A mood of rest, refuge, and quiet praise. Painterly and "
    "luminous, in a warm palette of gold and peridot-green with a soft cyan "
    "sky and deep-navy shadows. No text, no people, no logos, no watermarks. "
    "Wide cinematic landscape composition. " + _TAG
)

DETAIL_PROMPT = (
    "An open antique leather Bible resting on warm sunlit grass, framed by "
    "graceful palm fronds, golden morning light spilling across the open "
    "pages, a few wildflowers nearby, calm summer stillness. Painterly and "
    "inviting; warm gold and peridot-green palette with cyan sky accents and "
    "deep-navy depth. The pages show no readable text. No logos, no "
    "watermarks, no people. Tall vertical composition. " + _TAG
)
