"""Decode a compiled VS theme .pkgdef so the colours can be read back.

Each category's "Data" value is a binary blob:
  len(4) version(4) count(4) categoryGuid(16) colourCount(4)
  then per colour: nameLen(4) name bgType(1) [BGRA(4)] fgType(1) [BGRA(4)]
Type 1 means CT_RAW; anything else carries no bytes.
"""
import binascii
import re
import sys

KEY = re.compile(
    r"\[\$RootKey\$\\Themes\\\{[^}]+\}\\([^\]]+)\]\s*\r?\n\"Data\"=hex:([0-9a-fA-F,\\\s]+)"
)


def parse(path):
    txt = open(path, encoding="utf-8-sig", errors="replace").read()
    out = {}
    for m in KEY.finditer(txt):
        raw = re.sub(r"[^0-9a-fA-F]", "", m.group(2))
        out[m.group(1)] = bytes.fromhex(raw)
    return out


def colours(blob):
    p = 12 + 16
    n = int.from_bytes(blob[p:p + 4], "little")
    p += 4
    for _ in range(n):
        ln = int.from_bytes(blob[p:p + 4], "little")
        p += 4
        name = blob[p:p + ln].decode("ascii", "replace")
        p += ln
        vals = []
        for _role in range(2):
            t = blob[p]
            p += 1
            if t == 1:
                vals.append("#" + binascii.hexlify(blob[p:p + 4]).decode().upper())
                p += 4
            else:
                vals.append(f"t{t}")
        yield name, vals[0], vals[1]


WANT = {
    "Text Editor Language Service Items": ("Identifier", "XML Attribute"),
    "Text Editor MEF Items": (
        "keyword", "keyword - control", "local name", "field name",
        "method name", "string", "number", "class name",
    ),
}

for path, label in zip(sys.argv[1:3], ("DARK", "LIGHT")):
    cats = parse(path)
    print(f"=== {label} ===")
    for cat, names in WANT.items():
        if cat not in cats:
            print(f"  [{cat}] AUSENTE")
            continue
        for name, bg, fg in colours(cats[cat]):
            if name in names:
                print(f"  {cat:24} {name:22} bg={bg:9} fg={fg}")
