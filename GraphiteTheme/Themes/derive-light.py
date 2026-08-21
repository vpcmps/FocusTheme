"""Derive the light .vstheme from the Andromeda dark one.

Andromeda is dark-only, so the light variant keeps Andromeda's hues and its
cool-violet grey cast, but darkens every accent until it clears WCAG AA (4.5:1)
against the white editor surface. Surfaces invert per-token, because Andromeda's
chrome and editor share one flat colour (#23262E) that must split in two on light.
"""
import re
import sys

SRC = sys.argv[1]
DST = sys.argv[2]

# Andromeda dark value -> derived light value.
COLOR_MAP = {
    "FFFFFFFF": "FF000000",  # CommandBarTextHover flips
    "FF23262E": "FFF5F4F8",  # default chrome surface (editor split out below)
    "FF20232A": "FFEDECF2",
    "FF2B303B": "FFE9E7F0",
    "FF333844": "FFD3D0DC",
    "FF3D4352": "FFD5D2E2",  # selection
    "FF746F77": "FF6E6A78",
    "FFD5CED9": "FF23262E",  # primary text
    "B2D5CED9": "B223262E",
    "CCA0A1A7": "FF5F5B6B",  # comment: opaque on light, the 80% alpha fell to 4.1:1
    "FFA0A1A7": "FF5F5B6B",  # same grey, opaque (Roslyn classifications)
    "FF00E8C6": "FF007D6A",  # cyan
    "E500E8C6": "E5007D6A",
    "CC00E8C6": "CC007D6A",
    "FFC74DED": "FF7E28C9",  # purple
    "FFFFE66D": "FF8A6D00",  # yellow
    "FF96E072": "FF4A7F2C",  # green
    "FFF39C12": "FF9A5C00",  # orange
    "FFEE5D43": "FFC0341C",  # red
    "FFF92672": "FFC4105A",  # pink
    "FFFF00AA": "FFC00080",  # magenta (control flow)
    "FF7CB7FF": "FF1D6BC4",  # blue (types)
    "FFE36480": "FF8C1D3F",  # bordeaux. On dark it has to be lifted to clear AA
                             # (a true #8C1D3F is only 1.7:1 there); on white the
                             # deep value works and reads as proper burgundy.
    "61000000": "61FFFFFF",
}

# (category, colour name) pairs that are the document surface, not chrome.
EDITOR_SURFACES = {
    ("Environment", "Window"),
    ("Environment", "BrandedUIBackground"),
    ("ShellInternal", "EnvironmentBody"),
    ("Output Window", "Plain Text"),
    ("Find Results", "Plain Text"),
    ("Immediate Window", "Plain Text"),
    ("Command Window", "Plain Text"),
    ("Text Editor Text Manager Items", "Plain Text"),
}


def luminance(hex6):
    def chan(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = (int(hex6[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def contrast_on_white(hex6):
    return 1.05 / (luminance(hex6) + 0.05)


category = None
color = None
out = []
unmapped = set()

for line in open(SRC, encoding="utf-8"):
    m = re.search(r'<Category Name="([^"]+)"', line)
    if m:
        category = m.group(1)
    m = re.search(r'<Color Name="([^"]+)"', line)
    if m:
        color = m.group(1)

    m = re.search(r'Source="([0-9A-Fa-f]{8})"', line)
    if m:
        src = m.group(1).upper()
        if src == "00000000":  # CT_AUTOMATIC sentinel
            dst = src
        elif (category, color) in EDITOR_SURFACES and "<Background" in line:
            dst = "FFFFFFFF"
        elif src in COLOR_MAP:
            dst = COLOR_MAP[src]
        else:
            unmapped.add(f"{category}/{color} = {src}")
            dst = src
        line = line.replace(f'Source="{m.group(1)}"', f'Source="{dst}"')

    out.append(line)

text = "".join(out)

text = re.sub(
    r"<!-- Graphite Dark.*?-->",
    """<!-- Graphite Light - derived from the Andromeda palette, which ships dark-only.
       Hues are Andromeda's; every accent is darkened until it clears WCAG AA
       (4.5:1) on the white editor surface. Greys keep Andromeda's violet cast.
       Surfaces: editor #FFFFFF / chrome #F5F4F8 / raised #E9E7F0 / border #D3D0DC -->""",
    text,
    flags=re.S,
)
text = text.replace(
    '<Theme Name="Graphite Dark" GUID="{1dbdce6a-e099-467e-b4c9-a1033f13dc0c}" '
    'FallbackId="{1ded0138-47ce-435e-84ef-9ec1f439b749}">',
    '<Theme Name="Graphite Light" GUID="{b6caf99b-d958-4e0a-9a53-bf099ede1b48}" '
    'FallbackId="{de3dbbcd-f642-433c-8353-8f1df4370aba}">',
)

open(DST, "w", encoding="utf-8", newline="\n").write(text)

if unmapped:
    print("UNMAPPED (left as-is):")
    for u in sorted(unmapped):
        print("  ", u)
else:
    print("all colours mapped")

print("\ncontrast of derived accents on #FFFFFF (AA needs 4.5):")
for dark, light in COLOR_MAP.items():
    if light[:2] not in ("FF",) or light in ("FFFFFFFF", "FF000000"):
        continue
    ratio = contrast_on_white(light[2:])
    if ratio < 20:  # skip the near-black text tokens
        flag = "ok " if ratio >= 4.5 else "LOW"
        print(f"  {flag} #{dark[2:]} -> #{light[2:]}  {ratio:.2f}:1")
