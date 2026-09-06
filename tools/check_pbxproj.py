#!/usr/bin/env python3
"""Vérifie `Uniclav.xcodeproj/project.pbxproj`, qui est écrit à la main.

Le projet n'a pas de générateur : le fichier est modifié directement, et une
erreur de syntaxe ou une référence pendante ne se voit qu'au moment où Xcode
refuse d'ouvrir le projet — c'est-à-dire, ici, dans la CI, plusieurs minutes
plus tard. Ce script parle plus tôt.

Il analyse le format plist OpenStep, puis vérifie que :

- la syntaxe tient (parenthèses, accolades, points-virgules) ;
- tout identifiant cité correspond à un objet existant ;
- tout objet est atteignable depuis la racine — un objet orphelin est du
  travail à moitié fait, pas une erreur d'Xcode ;
- tout fichier référencé existe réellement sur le disque ;
- chaque cible a bien ses phases de compilation.

    python3 tools/check_pbxproj.py
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJECT = ROOT / "Uniclav.xcodeproj" / "project.pbxproj"

# Un identifiant d'objet Xcode : 24 caractères hexadécimaux.
IDENTIFIER = re.compile(r"^[0-9A-Fa-f]{24}$")


class Parser:
    """Analyseur du plist OpenStep, réduit à ce que produit un pbxproj."""

    def __init__(self, text: str) -> None:
        # Les commentaires /* … */ portent des noms lisibles, pas des données.
        self.text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
        self.index = 0

    def error(self, message: str):
        line = self.text.count("\n", 0, self.index) + 1
        return SyntaxError(f"ligne {line} : {message}")

    def skip(self) -> None:
        while self.index < len(self.text) and self.text[self.index].isspace():
            self.index += 1

    def parse(self):
        self.skip()
        if self.text[self.index : self.index + 2] == "//":  # en-tête !$*UTF8*$!
            self.index = self.text.index("\n", self.index)
        value = self.value()
        self.skip()
        if self.index != len(self.text):
            raise self.error("contenu inattendu après l'objet racine")
        return value

    def value(self):
        self.skip()
        if self.index >= len(self.text):
            raise self.error("fin de fichier prématurée")
        char = self.text[self.index]
        if char == "{":
            return self.dictionary()
        if char == "(":
            return self.array()
        if char == '"':
            return self.quoted()
        return self.bare()

    def dictionary(self) -> dict:
        self.index += 1  # {
        result = {}
        while True:
            self.skip()
            if self.index >= len(self.text):
                raise self.error("dictionnaire non refermé")
            if self.text[self.index] == "}":
                self.index += 1
                return result
            key = self.value()
            self.skip()
            if self.text[self.index] != "=":
                raise self.error(f"« = » attendu après la clé {key!r}")
            self.index += 1
            result[key] = self.value()
            self.skip()
            if self.text[self.index] != ";":
                raise self.error(f"« ; » attendu après la valeur de {key!r}")
            self.index += 1

    def array(self) -> list:
        self.index += 1  # (
        result = []
        while True:
            self.skip()
            if self.index >= len(self.text):
                raise self.error("liste non refermée")
            if self.text[self.index] == ")":
                self.index += 1
                return result
            result.append(self.value())
            self.skip()
            if self.text[self.index] == ",":
                self.index += 1

    def quoted(self) -> str:
        self.index += 1  # "
        out = []
        while self.text[self.index] != '"':
            if self.text[self.index] == "\\":
                self.index += 1
            out.append(self.text[self.index])
            self.index += 1
        self.index += 1
        return "".join(out)

    def bare(self) -> str:
        start = self.index
        while self.index < len(self.text) and self.text[self.index] not in "={}();,\"" \
                and not self.text[self.index].isspace():
            self.index += 1
        if start == self.index:
            raise self.error(f"caractère inattendu {self.text[self.index]!r}")
        return self.text[start : self.index]


def referenced_identifiers(value, objects) -> set:
    """Tout identifiant cité dans une valeur, à quelque profondeur que ce soit."""
    found = set()
    if isinstance(value, dict):
        for item in value.values():
            found |= referenced_identifiers(item, objects)
    elif isinstance(value, list):
        for item in value:
            found |= referenced_identifiers(item, objects)
    elif isinstance(value, str) and IDENTIFIER.match(value):
        found.add(value)
    return found


def resolve_path(objects, identifier, groups_by_child) -> pathlib.Path | None:
    """Chemin sur le disque d'un fichier, en remontant ses groupes parents."""
    parts = []
    current = identifier
    seen = set()
    while current is not None and current not in seen:
        seen.add(current)
        node = objects.get(current, {})
        tree = node.get("sourceTree")
        if tree in ("SDKROOT", "DEVELOPER_DIR", "BUILT_PRODUCTS_DIR", "SOURCE_ROOT", "<absolute>"):
            return None  # hors de l'arborescence du projet
        if node.get("path"):
            parts.append(node["path"])
        current = groups_by_child.get(current)
    return ROOT.joinpath(*reversed(parts)) if parts else None


def main() -> int:
    text = PROJECT.read_text(encoding="utf-8")
    try:
        project = Parser(text).parse()
    except SyntaxError as error:
        print(f"✗ syntaxe : {error}")
        return 1

    objects = project["objects"]
    root = project["rootObject"]
    problems: list[str] = []

    # Référence pendante : un identifiant cité qui ne désigne aucun objet.
    for identifier, node in objects.items():
        for cited in referenced_identifiers(node, objects):
            if cited not in objects:
                isa = node.get("isa", "?")
                problems.append(f"référence pendante {cited} depuis {identifier} ({isa})")
    if root not in objects:
        problems.append(f"rootObject {root} absent")

    # Objet orphelin : présent mais atteignable depuis nulle part.
    reachable = {root}
    frontier = [root]
    while frontier:
        current = frontier.pop()
        for cited in referenced_identifiers(objects.get(current, {}), objects):
            if cited in objects and cited not in reachable:
                reachable.add(cited)
                frontier.append(cited)
    for identifier in objects:
        if identifier not in reachable:
            problems.append(f"objet orphelin {identifier} ({objects[identifier].get('isa','?')})")

    # Chemins : chaque fichier référencé doit exister.
    groups_by_child = {}
    for identifier, node in objects.items():
        if node.get("isa") in ("PBXGroup", "PBXVariantGroup"):
            for child in node.get("children", []):
                groups_by_child[child] = identifier

    files = 0
    for identifier, node in objects.items():
        if node.get("isa") != "PBXFileReference":
            continue
        if node.get("sourceTree") == "BUILT_PRODUCTS_DIR":
            continue  # produit de compilation, pas un fichier source
        path = resolve_path(objects, identifier, groups_by_child)
        if path is None:
            continue
        files += 1
        if not path.exists():
            problems.append(f"fichier absent : {path.relative_to(ROOT)}")

    # Cibles : chacune doit avoir ses phases.
    targets = [n for n in objects.values() if n.get("isa") == "PBXNativeTarget"]
    for target in targets:
        phases = {objects[p].get("isa") for p in target.get("buildPhases", []) if p in objects}
        if "PBXSourcesBuildPhase" not in phases:
            problems.append(f"cible {target.get('name')} sans phase de compilation")

    sources = sum(len(n.get("files", []))
                  for n in objects.values() if n.get("isa") == "PBXSourcesBuildPhase")
    resources = sum(len(n.get("files", []))
                    for n in objects.values() if n.get("isa") == "PBXResourcesBuildPhase")

    if problems:
        for problem in problems:
            print(f"✗ {problem}")
        return 1

    print(f"✓ {len(objects)} objets, {len(targets)} cibles, {sources} fichiers compilés, "
          f"{resources} ressources, {files} fichiers résolus")
    return 0


if __name__ == "__main__":
    sys.exit(main())
