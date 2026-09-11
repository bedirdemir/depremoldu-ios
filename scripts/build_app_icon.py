#!/usr/bin/env python3
"""Rebuild the 1024px app icon from the web project's 512px brand icon.

The web asset is a flat cream tile with the primary-colored seismograph
stroke. This script classifies every pixel as stroke or background, scales the
mask to 1024px and composites the two exact brand colors, which keeps the
edges crisp for the App Store icon instead of blurring a raster upscale.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

BACKGROUND = (252, 255, 231)
STROKE = (235, 69, 95)


def classify(pixel: tuple[int, int, int, int]) -> int:
    red, green, blue, _ = pixel
    axis = tuple(s - b for s, b in zip(STROKE, BACKGROUND))
    delta = (red - BACKGROUND[0], green - BACKGROUND[1], blue - BACKGROUND[2])
    axis_length_squared = sum(component * component for component in axis)
    coverage = sum(d * a for d, a in zip(delta, axis)) / axis_length_squared
    return 255 if coverage >= 0.35 else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--size", type=int, default=1024)
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGBA")

    mask = Image.new("L", source.size)
    mask.putdata([classify(pixel) for pixel in source.getdata()])
    mask = mask.resize((args.size, args.size), Image.Resampling.LANCZOS)

    icon = Image.new("RGBA", (args.size, args.size), (*BACKGROUND, 255))
    stroke_layer = Image.new("RGBA", (args.size, args.size), (*STROKE, 255))
    icon = Image.composite(stroke_layer, icon, mask)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    icon.convert("RGB").save(args.output, format="PNG")
    print(f"Wrote {args.size}x{args.size} icon to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
