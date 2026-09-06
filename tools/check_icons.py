#!/usr/bin/env python3
"""Vérifie que les quatre listes d'icônes de rechange s'accordent.

Les noms d'icônes sont répétés à quatre endroits, sans qu'aucun compilateur
ne les rapproche :

- `tools/make_icons.py`, qui produit les fichiers ;
- `Uniclav/AlternateIcons/`, les fichiers eux-mêmes ;
- `Uniclav/Info.plist`, sous `CFBundleAlternateIcons` ;
- `Uniclav/AppIconChoice.swift`, qui les propose à l'utilisateur.

`UIImage(named:)` et `CFBundleIconFiles` sont des chaînes : une faute de
frappe ne se verrait qu'à l'écran, sur un appareil. Ce script est le seul
endroit où les quatre sont confrontées.

    python3 tools/check_icons.py
"""

from __future__ import annotations

import pathlib
import plistlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ICONS = ROOT / "Uniclav" / "AlternateIcons"
SCALES = (2, 3)


def from_generator() -> set[str]:
    text = (ROOT / "tools" / "make_icons.py").read_text(encoding="utf-8")
    block = text[text.index("THEMES = ["):text.index("]", text.index("THEMES = ["))]
    return set(re.findall(r'\(\s*"([A-Za-z]+)"\s*,', block))


def from_plist() -> set[str]:
    plist = plistlib.loads((ROOT / "Uniclav" / "Info.plist").read_bytes())
    return set(plist.get("CFBundleIcons", {}).get("CFBundleAlternateIcons", {}))


def from_swift() -> set[str]:
    text = (ROOT / "Uniclav" / "AppIconChoice.swift").read_text(encoding="utf-8")
    return set(re.findall(r'alternateName:\s*"([A-Za-z]+)"', text))


def from_disk() -> set[str]:
    return {p.name.split("@")[0].removeprefix("AppIcon-") for p in ICONS.glob("*.png")}


def main() -> int:
    sources = {
        "le générateur": from_generator(),
        "Info.plist": from_plist(),
        "AppIconChoice.swift": from_swift(),
        "les fichiers sur le disque": from_disk(),
    }
    problems: list[str] = []

    reference = sources["le générateur"]
    for name, names in sources.items():
        for missing in sorted(reference - names):
            problems.append(f"{missing} : absent de {name}")
        for extra in sorted(names - reference):
            problems.append(f"{extra} : présent dans {name}, mais pas dans le générateur")

    # Chaque icône déclarée doit exister aux deux échelles qu'iOS demande.
    for name in sorted(reference):
        for scale in SCALES:
            path = ICONS / f"AppIcon-{name}@{scale}x.png"
            if not path.exists():
                problems.append(f"fichier absent : {path.relative_to(ROOT)}")

    # Une icône ne doit porter aucune transparence : l'App Store la refuse.
    for path in sorted(ICONS.glob("*.png")):
        header = path.read_bytes()[24:26]
        if len(header) == 2 and header[1] not in (0, 2):
            problems.append(f"{path.name} : type de couleur {header[1]}, "
                            "attendu 0 ou 2 (sans canal alpha)")

    if problems:
        for problem in problems:
            print(f"✗ {problem}")
        return 1

    print(f"✓ {len(reference)} icônes de rechange, accordées entre les quatre listes, "
          f"{len(reference) * len(SCALES)} fichiers présents et opaques")
    return 0


if __name__ == "__main__":
    sys.exit(main())
