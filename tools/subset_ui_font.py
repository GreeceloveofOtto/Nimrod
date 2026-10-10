#!/usr/bin/env python3
"""Build the portable Korean UI font from the locally installed Noto KR face.

Requires fontTools. Regenerate after adding Korean dialogue or HUD strings:
    python tools/subset_ui_font.py
    python tools/subset_ui_font.py --font /path/to/NotoSansCJK-Regular.ttc
"""

from __future__ import annotations

import argparse
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


PROJECT_ROOT = Path(__file__).resolve().parents[1]
FONT_SOURCE = Path("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc")
COPYRIGHT_SOURCE = Path("/usr/share/doc/fonts-noto-cjk/copyright")
FONT_OUTPUT = PROJECT_ROOT / "assets/fonts/NimrodUIKorean-Regular.otf"
EXTRA_HINTS = "태초부터 다시 시작 후문 상호작용 별장 방향 니므롯 우루크 루갈성 사망"
FAMILY = "Nimrod UI Korean"
POSTSCRIPT_NAME = "NimrodUIKorean-Regular"


def game_characters(extra_text: str) -> set[int]:
    codepoints = set(range(32, 127))
    for folder, extensions in (
        ("scripts", {".gd"}),
        ("scenes", {".tscn"}),
        ("data", {".json"}),
    ):
        for path in sorted((PROJECT_ROOT / folder).rglob("*")):
            if path.suffix not in extensions:
                continue
            codepoints.update(ord(char) for char in path.read_text(encoding="utf-8") if char.isprintable())
    codepoints.update(ord(char) for char in EXTRA_HINTS + extra_text if char.isprintable())
    return codepoints


def rename_font(font: TTFont) -> None:
    names = {
        1: FAMILY,
        2: "Regular",
        3: "NimrodUIKorean-Regular-Subset",
        4: FAMILY + " Regular",
        6: POSTSCRIPT_NAME,
        16: FAMILY,
        17: "Regular",
    }
    for record in font["name"].names:
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    if "CFF " in font:
        cff = font["CFF "].cff
        cff.fontNames = [POSTSCRIPT_NAME]
        top_dict = cff.topDictIndex[0]
        top_dict.FullName = FAMILY + " Regular"
        top_dict.FamilyName = FAMILY


def save_license(path: Path) -> None:
    document = path.read_text(encoding="utf-8")
    copyright_paragraph = document.split("Files: *\n", 1)[1].split("\n\n", 1)[0]
    license_section = document.rsplit("\nLicense: SIL-1.1\n", 1)[1].split("\nLicense: GPL-3+", 1)[0]
    # Debian copyright paragraphs indent license lines and use dots for blanks.
    license_text = "\n".join("" if line.strip() == "." else line.removeprefix(" ") for line in license_section.splitlines())
    notice = (
        "Nimrod UI Korean Regular: a character subset of Noto Sans CJK KR Regular.\n"
        "The font family has been renamed. Original upstream: https://github.com/notofonts/noto-cjk\n"
        "Source copyright notice and font license: " + str(path) + "\n\n"
        + copyright_paragraph + "\n\n" + license_text.strip() + "\n"
    )
    (FONT_OUTPUT.parent / "FONT_LICENSE.txt").write_text(notice, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--font", type=Path, default=FONT_SOURCE)
    parser.add_argument("--face", type=int, default=1, help="Noto collection face 1 is Korean; ignored for standalone fonts.")
    parser.add_argument("--copyright", type=Path, default=COPYRIGHT_SOURCE)
    parser.add_argument("--extra-text", default="", help="Additional upcoming UI/dialogue characters.")
    args = parser.parse_args()
    if not args.font.is_file() or not args.copyright.is_file():
        parser.error("Provide an existing verified Noto font and its copyright/license file.")
    font = TTFont(args.font, fontNumber=args.face if args.font.suffix.lower() == ".ttc" else -1, recalcTimestamp=False)
    family = font["name"].getDebugName(1)
    if "CJK KR" not in str(family) and "Sans KR" not in str(family):
        parser.error(f"Expected the Korean Noto face, received {family!r}.")
    codepoints = game_characters(args.extra_text)
    missing = codepoints - set(font.getBestCmap())
    if missing:
        parser.error("Source font lacks requested characters: " + ", ".join(f"U+{value:04X}" for value in sorted(missing)))
    options = subset.Options()
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.layout_features = ["*"]
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=codepoints)
    subsetter.subset(font)
    rename_font(font)
    FONT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    font.save(FONT_OUTPUT)
    font.close()
    save_license(args.copyright)
    with TTFont(FONT_OUTPUT) as result:
        if not codepoints.issubset(result.getBestCmap()):
            raise RuntimeError("The saved font is missing a requested character.")
    print(f"Saved {FONT_OUTPUT.relative_to(PROJECT_ROOT)}: {len(codepoints)} characters, {FONT_OUTPUT.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
