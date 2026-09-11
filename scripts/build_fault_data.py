#!/usr/bin/env python3
"""Convert the web project's AFEAD KMZ fault tiles into the bundled Faults.json.

Source: public/FaultData/*.kmz from the depremolduorg web repository (read-only).
The output keeps only what the map needs: fault name, confidence, rate and the
line geometry. Long scientific reference blocks are intentionally dropped to
keep the app bundle small; confidence and rate keep the exact web semantics
(A/B/C/D, 1/2/3) with the same C/3 fallbacks.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

KML_NAMESPACE = "{http://www.opengis.net/kml/2.2}"
CONFIDENCE_RE = re.compile(r"CONF=\s*<b>\s*([ABCD])\s*</b>", re.IGNORECASE)
RATE_RE = re.compile(r"RATE=\s*<b>\s*([123])\s*</b>", re.IGNORECASE)
NAME_RE = re.compile(r"^\s*<b>(.*?)</b>", re.IGNORECASE | re.DOTALL)

FALLBACK_CONFIDENCE = "C"
FALLBACK_RATE = 3


def parse_description(description: str | None) -> tuple[str | None, str, int]:
    if not description:
        return None, FALLBACK_CONFIDENCE, FALLBACK_RATE

    confidence_match = CONFIDENCE_RE.search(description)
    rate_match = RATE_RE.search(description)
    name_match = NAME_RE.search(description)

    confidence = confidence_match.group(1).upper() if confidence_match else FALLBACK_CONFIDENCE
    if confidence not in ("A", "B", "C", "D"):
        confidence = FALLBACK_CONFIDENCE

    rate = int(rate_match.group(1)) if rate_match else FALLBACK_RATE
    if rate not in (1, 2, 3):
        rate = FALLBACK_RATE

    name = None
    if name_match:
        name = re.sub(r"\s+", " ", name_match.group(1)).strip() or None

    return name, confidence, rate


def parse_coordinates(text: str | None) -> list[list[float]]:
    points: list[list[float]] = []
    if not text:
        return points
    for token in text.split():
        parts = token.split(",")
        if len(parts) < 2:
            continue
        try:
            longitude = round(float(parts[0]), 5)
            latitude = round(float(parts[1]), 5)
        except ValueError:
            continue
        if not (-180.0 <= longitude <= 180.0 and -90.0 <= latitude <= 90.0):
            continue
        points.append([longitude, latitude])
    return points


def parse_kmz(path: Path) -> list[dict]:
    lines: list[dict] = []
    with zipfile.ZipFile(path) as archive:
        kml_name = next(
            (name for name in archive.namelist() if name.lower().endswith(".kml")),
            None,
        )
        if kml_name is None:
            raise ValueError(f"{path.name}: no KML document inside")
        root = ET.fromstring(archive.read(kml_name))

    for placemark in root.iter(f"{KML_NAMESPACE}Placemark"):
        description = placemark.findtext(f"{KML_NAMESPACE}description")
        line_string = placemark.find(f"{KML_NAMESPACE}LineString")
        if line_string is None:
            continue
        coordinates = parse_coordinates(
            line_string.findtext(f"{KML_NAMESPACE}coordinates")
        )
        if len(coordinates) < 2:
            continue
        name, confidence, rate = parse_description(description)
        lines.append(
            {
                "name": name,
                "c": confidence,
                "r": rate,
                "p": coordinates,
            }
        )
    return lines


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        required=True,
        type=Path,
        help="Directory containing AFEAD_*.kmz files",
    )
    parser.add_argument(
        "--output",
        required=True,
        type=Path,
        help="Destination Faults.json path",
    )
    args = parser.parse_args()

    kmz_files = sorted(args.source.glob("*.kmz"))
    if not kmz_files:
        print(f"No .kmz files found under {args.source}", file=sys.stderr)
        return 1

    lines: list[dict] = []
    for path in kmz_files:
        lines.extend(parse_kmz(path))

    if not lines:
        print("No fault lines were extracted", file=sys.stderr)
        return 1

    payload = {
        "version": 1,
        "source": "GINRAS/AFEAD (2018 aktif fay verisi)",
        "lines": lines,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))

    point_count = sum(len(line["p"]) for line in lines)
    print(
        f"Wrote {len(lines)} fault lines ({point_count} points) to {args.output} "
        f"({args.output.stat().st_size / 1024:.0f} KiB)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
