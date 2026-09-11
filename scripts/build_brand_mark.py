#!/usr/bin/env python3
"""Build the BrandMark raster template icons from the 2048px product icon.

The brand mark is the seismograph line of depremolduappicon.png without the
cream background. iOS 26's glass tab bar misrenders vector (SVG) template
images, so the asset catalog uses anti-aliased PNG scales instead. The original
SVG is kept under docs/assets/brand-mark.svg for provenance.

Outputs (template rendering, black):
    BrandMark.png     30x28   @1x
    BrandMark@2x.png  60x56   @2x
    BrandMark@3x.png  90x84   @3x
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

BACKGROUND = (252, 255, 231)
STROKE = (235, 69, 95)
BASE_WIDTH = 30
BASE_HEIGHT = 28


def coverage(pixel: tuple[int, int, int, int]) -> float:
    red, green, blue, _ = pixel
    axis = tuple(s - b for s, b in zip(STROKE, BACKGROUND))
    delta = (red - BACKGROUND[0], green - BACKGROUND[1], blue - BACKGROUND[2])
    axis_length_squared = sum(component * component for component in axis)
    ratio = sum(d * a for d, a in zip(delta, axis)) / axis_length_squared
    return min(max(ratio, 0.0), 1.0)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGBA")
    width, height = source.size

    alpha = Image.new("L", source.size)
    alpha.putdata([round(coverage(pixel) * 255) for pixel in source.getdata()])

    mark = Image.new("RGBA", source.size, (0, 0, 0, 0))
    mark.putalpha(alpha)

    bounding_box = mark.getbbox()
    if bounding_box is None:
        raise SystemExit("Brand mark could not be located in the source icon")
    padding = 24
    left = max(bounding_box[0] - padding, 0)
    top = max(bounding_box[1] - padding, 0)
    right = min(bounding_box[2] + padding, width)
    bottom = min(bounding_box[3] + padding, height)
    cropped = mark.crop((left, top, right, bottom))

    args.output_dir.mkdir(parents=True, exist_ok=True)
    scales = [
        ("BrandMark.png", 1),
        ("BrandMark@2x.png", 2),
        ("BrandMark@3x.png", 3),
    ]
    for name, scale in scales:
        target = (BASE_WIDTH * scale, BASE_HEIGHT * scale)
        resized = cropped.resize(target, Image.Resampling.LANCZOS)
        resized.save(args.output_dir / name, format="PNG")
        print(f"Wrote {target[0]}x{target[1]} {name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
