#!/usr/bin/env python3
"""Génère les icônes de rechange de l'application, une par thème de couleurs.

Aucune dépendance : le PNG est écrit à la main (zlib + struct), et le dessin
est décrit par des fonctions de distance signée. Le rendu se fait à 720 px
puis est réduit par moyenne de blocs — 720 étant divisible par 4 et par 6, on
obtient exactement les 180 px (@3x) et 120 px (@2x) qu'iOS demande pour une
icône de 60 pt, avec un lissage qui vient de la réduction elle-même.

Le motif est celui de l'icône principale : une touche unique portant un A, et
la traînée de deux touches fantômes — la course de la main qui vient chercher
la touche. Seules les couleurs changent, reprises telles quelles des thèmes de
`Shared/KeyboardTheme.swift`.

    python3 tools/make_icons.py
"""

from __future__ import annotations

import math
import pathlib
import struct
import sys
import zlib

# Les sept thèmes de Shared/KeyboardTheme.swift : fond des touches, lettres.
# « Encre sur sable » est l'icône principale, livrée dans le catalogue : elle
# n'a pas de version de rechange, `setAlternateIconName(nil)` y revient.
THEMES = [
    ("Nuit", "3A3A3E", "F2EBDE"),
    ("ContrasteMaximal", "FFFFFF", "000000"),
    ("JauneSurNoir", "141414", "FFD400"),
    ("NoirSurJaune", "FFD400", "141414"),
    ("BleuProfond", "12284B", "F5F7FA"),
    ("VertDEau", "E8F1EC", "16352B"),
    # Fantaisistes. Les noms restent en ASCII : ils servent de nom de fichier
    # et de clé dans Info.plist.
    ("Neon", "0B0B12", "39FF14"),
    ("TerminalAmbre", "0D1F0D", "FFB000"),
    ("Bonbon", "FFD9E8", "4A0E2E"),
    ("Agrume", "FFB703", "3A1F04"),
    ("Lavande", "EDE7FF", "2E1065"),
    ("Prune", "2A0A3D", "F3D9FF"),
]
# « Automatique » n'a pas d'icône : il a deux palettes, et une icône de
# rechange iOS n'en a qu'une.

RENDER = 720
SIZES = {2: 120, 3: 180}


# --- Couleurs ---------------------------------------------------------------

def from_hex(value: str) -> tuple[float, float, float]:
    n = int(value, 16)
    return ((n >> 16 & 0xFF) / 255, (n >> 8 & 0xFF) / 255, (n & 0xFF) / 255)


def blend(a, b, amount):
    return tuple(x + (y - x) * amount for x, y in zip(a, b))


# --- Distances signées ------------------------------------------------------

def rounded_box(px, py, cx, cy, hw, hh, radius):
    dx = abs(px - cx) - hw + radius
    dy = abs(py - cy) - hh + radius
    outside = math.hypot(max(dx, 0.0), max(dy, 0.0))
    return outside + min(max(dx, dy), 0.0) - radius


def rotated_box(px, py, cx, cy, hw, hh, radius, angle):
    s, c = math.sin(angle), math.cos(angle)
    dx, dy = px - cx, py - cy
    return rounded_box(dx * c + dy * s, -dx * s + dy * c, 0, 0, hw, hh, radius)


def capsule(px, py, ax, ay, bx, by, radius):
    """Segment à extrémités arrondies : le A est tracé de trois d'entre eux,
    sans dépendre d'une police, pour un rendu identique partout."""
    pax, pay = px - ax, py - ay
    bax, bay = bx - ax, by - ay
    denominator = bax * bax + bay * bay
    h = 0.0 if denominator == 0 else max(0.0, min(1.0, (pax * bax + pay * bay) / denominator))
    return math.hypot(pax - bax * h, pay - bay * h) - radius


# --- Le motif, en coordonnées normalisées ----------------------------------

# Ces valeurs ne sont pas dessinées d'après une intention : elles sont
# relevées sur l'icône livrée (Uniclav/Assets.xcassets/…/AppIcon-1024.png),
# pixel par pixel, puis divisées par 1024. Une première version approximative
# s'en écartait de 15,45/255 en moyenne — les variantes n'étaient donc pas
# « la même icône, d'autres couleurs », comme je l'avais écrit.

KEY = (0.57178, 0.44092, 0.23779, 0.23779, 0.06348)   # centre x, y, demi-côtés, rayon
GHOSTS = [                                            # centre x, y, demi-côté, rayon, angle, mélange
    (0.32666, 0.65234, 0.08203, 0.02188, -0.31, 0.218),
    (0.18262, 0.77148, 0.07813, 0.02090, -0.31, 0.129),
]
STROKE = 0.02734
LETTER = [                                            # les trois traits du A
    (0.57178, 0.31406, 0.47168, 0.56641),
    (0.57178, 0.31406, 0.67188, 0.56641),
    (0.50771, 0.47559, 0.63584, 0.47559),
]
# Le fond est un dégradé vertical. Sur l'icône livrée il va de F2EBDE à
# D8CDB8 — la paire « sable » de l'identité, qui n'est pas un mélange uniforme
# du fond des touches vers l'encre. Pour un thème quelconque, aucune paire de
# ce genre n'existe : on descend donc de 16 % vers la couleur des lettres, ce
# qui est la moyenne des trois canaux relevée sur l'icône livrée.
GROUND_BLEND = 0.16


def shade(x: float, y: float, face, text, ground):
    """Couleur d'un point, du fond vers l'avant."""
    colour = blend(ground[0], ground[1], y)

    for cx, cy, half, radius, angle, amount in GHOSTS:
        if rotated_box(x, y, cx, cy, half, half, radius, angle) < 0:
            colour = blend(colour, text, amount)

    cx, cy, hw, hh, radius = KEY
    if rounded_box(x, y, cx, cy, hw, hh, radius) < 0:
        colour = text
        for ax, ay, bx, by in LETTER:
            if capsule(x, y, ax, ay, bx, by, STROKE) < 0:
                # La lettre reprend le haut du fond, pas le fond des touches :
                # c'est ce que fait l'icône livrée.
                colour = ground[0]
    return colour


# --- Rendu et écriture ------------------------------------------------------

def ground_for(face, text):
    """Le dégradé de fond d'un thème."""
    return (face, blend(face, text, GROUND_BLEND))


def render(face, text, ground=None) -> list[list[tuple[float, float, float]]]:
    ground = ground or ground_for(face, text)
    rows = []
    for j in range(RENDER):
        y = (j + 0.5) / RENDER
        rows.append([shade((i + 0.5) / RENDER, y, face, text, ground) for i in range(RENDER)])
    return rows


def downsample(rows, size):
    factor = RENDER // size
    weight = factor * factor
    out = bytearray()
    for j in range(size):
        out.append(0)  # filtre PNG « None »
        for i in range(size):
            totals = [0.0, 0.0, 0.0]
            for dj in range(factor):
                row = rows[j * factor + dj]
                for di in range(factor):
                    pixel = row[i * factor + di]
                    for channel in range(3):
                        totals[channel] += pixel[channel]
            for channel in totals:
                out.append(min(255, max(0, round(channel / weight * 255))))
    return bytes(out)


def write_png(path: pathlib.Path, raw: bytes, size: int) -> None:
    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (struct.pack(">I", len(payload)) + kind + payload
                + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF))

    # Bit depth 8, type 2 (RVB sans alpha) : l'App Store refuse la
    # transparence sur une icône, et une icône de rechange suit la même règle.
    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def main() -> int:
    destination = pathlib.Path(__file__).resolve().parent.parent / "Uniclav" / "AlternateIcons"
    destination.mkdir(parents=True, exist_ok=True)

    for name, face_hex, text_hex in THEMES:
        face, text = from_hex(face_hex), from_hex(text_hex)
        rows = render(face, text)
        for scale, size in SIZES.items():
            path = destination / f"AppIcon-{name}@{scale}x.png"
            write_png(path, downsample(rows, size), size)
            print(f"{path.relative_to(destination.parent.parent)}  {size}×{size}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
