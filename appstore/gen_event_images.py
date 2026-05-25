#!/usr/bin/env python3
"""Generate App Store In-App Event images via OpenAI gpt-image-2.

Reads CARD_PROMPT / DETAIL_PROMPT from appstore/events/<slug>/image_prompts.py,
generates with gpt-image-2 at a clean 16:9 / 9:16 frame, then resizes to the
exact App Store dimensions and writes into the event folder:

  <slug>_event.png          1920x1080  (EVENT_CARD, landscape)
  <slug>_event_details.png  1080x1920  (EVENT_DETAILS_PAGE, portrait)

gpt-image-2 requires width/height divisible by 16, so we request an exact
16:9 / 9:16 frame and downscale crisply (no aspect distortion).

Usage:
  uv run --with openai --with pillow python appstore/gen_event_images.py --event summer-psalms
  # one image only:
  uv run --with openai --with pillow python appstore/gen_event_images.py --event summer-psalms --only card

Needs OPENAI_API_KEY in the environment.
"""
from __future__ import annotations

import argparse
import base64
import importlib.util
import sys
from io import BytesIO
from pathlib import Path

from openai import OpenAI
from PIL import Image, ImageOps

EVENTS_DIR = Path(__file__).resolve().parent / "events"
RESAMPLE = getattr(Image, "Resampling", Image).LANCZOS

# kind -> (size requested from the API, final size written to disk, filename suffix)
SPECS = {
    "card":   {"gen": "2048x1152", "out": (1920, 1080), "suffix": "_event.png"},
    "detail": {"gen": "1152x2048", "out": (1080, 1920), "suffix": "_event_details.png"},
}


def load_prompts(slug: str) -> dict[str, str]:
    path = EVENTS_DIR / slug / "image_prompts.py"
    if not path.exists():
        sys.exit(f"No prompts file: {path} (expected CARD_PROMPT and DETAIL_PROMPT)")
    spec = importlib.util.spec_from_file_location(f"{slug}_image_prompts", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return {"card": mod.CARD_PROMPT, "detail": mod.DETAIL_PROMPT}


def generate(client: OpenAI, model: str, prompt: str, gen_size: str) -> Image.Image:
    result = client.images.generate(
        model=model,
        prompt=prompt,
        size=gen_size,
        quality="high",
        output_format="png",
        n=1,
    )
    raw = base64.b64decode(result.data[0].b64_json)
    return Image.open(BytesIO(raw))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--event", required=True, help="event slug (folder under appstore/events/)")
    ap.add_argument("--model", default="gpt-image-2")
    ap.add_argument("--only", choices=["card", "detail"], help="generate just one image")
    args = ap.parse_args()

    out_dir = EVENTS_DIR / args.event
    out_dir.mkdir(parents=True, exist_ok=True)
    prompts = load_prompts(args.event)
    client = OpenAI()

    for kind in ([args.only] if args.only else ["card", "detail"]):
        spec = SPECS[kind]
        print(f"[{kind}] generating {spec['gen']} via {args.model} ...", flush=True)
        img = generate(client, args.model, prompts[kind], spec["gen"])
        final = ImageOps.fit(img, spec["out"], method=RESAMPLE)
        out_path = out_dir / f"{args.event}{spec['suffix']}"
        final.save(out_path, "PNG")
        print(f"[{kind}] wrote {out_path}  ({final.width}x{final.height})", flush=True)


if __name__ == "__main__":
    main()
