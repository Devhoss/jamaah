"""Cuts the static font weights the app bundles from Google Fonts' variable files.

Horizon spec §2.1 bundles only a few weights per family. Google publishes these
families as variable fonts only, so this script pins every axis and writes one
static TTF per weight into assets/fonts/. Fraunces is also pinned to an optical
size close to the size it is drawn at (browsers do this automatically).

Usage (needs `pip install fonttools`):
    python tool/make_font_instances.py <dir with the downloaded variable TTFs>

Source: github.com/google/fonts (ofl/fraunces, ofl/instrumentsans,
ofl/notonaskharabic, ofl/notosansarabic), all SIL Open Font License 1.1.
See docs/font-licence.md.
"""

import pathlib
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "fonts"

# (source file, output file, axis values, style name)
INSTANCES = [
    # Fraunces: 300 for the hero time (drawn at ~108), 400 for titles (~40),
    # 400 italic for prayer names and section titles (~22-26).
    ("Fraunces[SOFT,WONK,opsz,wght].ttf", "Fraunces-Light.ttf",
     {"wght": 300, "opsz": 96, "SOFT": 0, "WONK": 0}, "Light"),
    ("Fraunces[SOFT,WONK,opsz,wght].ttf", "Fraunces-Regular.ttf",
     {"wght": 400, "opsz": 40, "SOFT": 0, "WONK": 0}, "Regular"),
    ("Fraunces-Italic[SOFT,WONK,opsz,wght].ttf", "Fraunces-Italic.ttf",
     {"wght": 400, "opsz": 24, "SOFT": 0, "WONK": 0}, "Italic"),
    ("InstrumentSans[wdth,wght].ttf", "InstrumentSans-Regular.ttf",
     {"wght": 400, "wdth": 100}, "Regular"),
    ("InstrumentSans[wdth,wght].ttf", "InstrumentSans-Medium.ttf",
     {"wght": 500, "wdth": 100}, "Medium"),
    ("InstrumentSans[wdth,wght].ttf", "InstrumentSans-SemiBold.ttf",
     {"wght": 600, "wdth": 100}, "SemiBold"),
    ("NotoNaskhArabic[wght].ttf", "NotoNaskhArabic-Medium.ttf",
     {"wght": 500}, "Medium"),
    ("NotoNaskhArabic[wght].ttf", "NotoNaskhArabic-SemiBold.ttf",
     {"wght": 600}, "SemiBold"),
    ("NotoSansArabic[wdth,wght].ttf", "NotoSansArabic-Regular.ttf",
     {"wght": 400, "wdth": 100}, "Regular"),
    ("NotoSansArabic[wdth,wght].ttf", "NotoSansArabic-Medium.ttf",
     {"wght": 500, "wdth": 100}, "Medium"),
    ("NotoSansArabic[wdth,wght].ttf", "NotoSansArabic-SemiBold.ttf",
     {"wght": 600, "wdth": 100}, "SemiBold"),
]


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    src = pathlib.Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    for source, output, axes, _style in INSTANCES:
        font = TTFont(src / source)
        known = {a.axisTag for a in font["fvar"].axes}
        static = instancer.instantiateVariableFont(
            font,
            {tag: value for tag, value in axes.items() if tag in known},
            updateFontNames=False,
        )
        path = OUT / output
        static.save(path)
        print(f"{output}: {path.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
