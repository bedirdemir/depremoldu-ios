#!/usr/bin/env python3
"""Build the 1024px App Store icon from the product's 2048px brand icon.

Source: depremolduorg-nuxtjs/public/depremolduappicon.png (2048x2048 RGBA).
The icon renders with the cream brand background; the alpha channel is
flattened over that background so the App Store asset stays opaque.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

BACKGROUND = (252, 255, 231)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--size", type=int, default=1024)
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGBA")
    background = Image.new("RGBA", source.size, (*BACKGROUND, 255))
    flattened = Image.alpha_composite(background, source).convert("RGB")
    icon = flattened.resize((args.size, args.size), Image.Resampling.LANCZOS)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    icon.save(args.output, format="PNG")
    print(f"Wrote {args.size}x{args.size} icon to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
