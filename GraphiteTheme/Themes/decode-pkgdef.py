"""Decode a compiled VS theme .pkgdef so the colours can be read back.

A .vstheme is compiled into a .pkgdef by the VSSDK before it ships, and the
compiled form is what Visual Studio actually reads. Being able to decode it is
what makes "the theme says X" and "the installed package says X" two separate,
checkable claims rather than one assumption.

Each category's "Data" value is a binary blob:

    length(4) version(4) count(4) categoryGuid(16) colourCount(4)
    then per colour: nameLen(4) name backgroundType(1) [value(4)] foregroundType(1) [value(4)]

The type byte says whether a value follows, and colour values are stored R,G,B,A
- not the A,R,G,B order the .vstheme spells them in.

Usage:  python decode-pkgdef.py <file.pkgdef> [more.pkgdef ...]
        python decode-pkgdef.py --check <file.pkgdef>   compare against its .vstheme
"""
import binascii
import glob
import os
import re
import sys

KEY = re.compile(
    r"\[\$RootKey\$\\Themes\\\{[^}]+\}\\([^\]]+)\]\s*\r?\n\"Data\"=hex:([0-9a-fA-F,\\\s]+)"
)

# Colour value types, and how many bytes each carries after the type byte.
# CT_AUTOMATIC carries a value just as CT_RAW does - it is stored as 00000000
# rather than omitted - so treating "not CT_RAW" as "no bytes" desynchronises
# the reader partway through a category and every later name comes out as
# garbage.
VALUE_SIZES = {
    0x00: 0,  # absent: the .vstheme did not state this role
    0x01: 4,  # CT_RAW
    0x02: 4,  # CT_COLORINDEX
    0x03: 4,  # CT_SYSCOLOR
    0x04: 4,  # CT_VSCOLOR
    0x05: 4,  # CT_AUTOMATIC
    0x06: 4,  # CT_TRACK_BACKGROUND
    0x07: 4,  # CT_TRACK_FOREGROUND
    0x08: 4,  # CT_INVALID
}


class PkgdefError(Exception):
    """The blob did not decode cleanly, which means the format assumption is wrong."""


def parse(path):
    """Return {category name: raw blob} for every category in the file."""
    with open(path, encoding="utf-8-sig", errors="replace") as fh:
        text = fh.read()
    return {
        m.group(1): bytes.fromhex(re.sub(r"[^0-9a-fA-F]", "", m.group(2)))
        for m in KEY.finditer(text)
    }


def colours(blob, category):
    """Yield (name, background, foreground) for one category's blob.

    Background and foreground are "RRGGBB" for a stated colour, or None when the
    role carries no raw value. Raises PkgdefError rather than reading past the
    end, because a silent overrun produces plausible-looking nonsense.
    """
    def take(offset, count):
        if offset + count > len(blob):
            raise PkgdefError(
                "%s: needed %d byte(s) at offset %d but the blob is %d long"
                % (category, count, offset, len(blob))
            )
        return blob[offset:offset + count]

    pos = 12 + 16
    count = int.from_bytes(take(pos, 4), "little")
    pos += 4

    for index in range(count):
        name_length = int.from_bytes(take(pos, 4), "little")
        pos += 4
        name = take(pos, name_length).decode("ascii", "replace")
        pos += name_length

        values = []
        for _role in range(2):
            value_type = take(pos, 1)[0]
            pos += 1
            if value_type not in VALUE_SIZES:
                raise PkgdefError(
                    "%s: colour %d (%r) has unknown value type 0x%02X at offset %d"
                    % (category, index, name, value_type, pos - 1)
                )
            size = VALUE_SIZES[value_type]
            if size == 0:
                values.append(None)
                continue
            raw = take(pos, size)
            pos += size
            # Stored R,G,B,A. Only CT_RAW carries a colour worth reporting; the
            # rest carry a value that means something other than "this colour".
            values.append("%02X%02X%02X" % (raw[0], raw[1], raw[2]) if value_type == 0x01 else None)

        yield name, values[0], values[1]

    if pos != len(blob):
        raise PkgdefError(
            "%s: decoded %d of %d byte(s); the layout assumption is wrong"
            % (category, pos, len(blob))
        )


def read(path):
    """Return {category: {colour name: (background, foreground)}}."""
    out = {}
    for category, blob in parse(path).items():
        out[category] = {n: (bg, fg) for n, bg, fg in colours(blob, category)}
    return out


def theme_foregrounds(path):
    """Return {(category, colour name): "RRGGBB"} from a .vstheme source file."""
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    out = {}
    category = colour = None
    for line in text.splitlines():
        m = re.search(r'<Category Name="([^"]+)"', line)
        if m:
            category = m.group(1)
            continue
        m = re.search(r'<Color Name="([^"]+)"', line)
        if m:
            colour = m.group(1)
            continue
        m = re.search(r'<Foreground Type="CT_RAW" Source="[0-9A-F]{2}([0-9A-F]{6})"', line)
        if m and category and colour:
            out[(category, colour)] = m.group(1)
    return out


def check(pkgdef_path, theme_path):
    """Compare every stated foreground in the .vstheme against the .pkgdef."""
    compiled = read(pkgdef_path)
    expected = theme_foregrounds(theme_path)
    mismatches = []
    for (category, colour), want in sorted(expected.items()):
        got = compiled.get(category, {}).get(colour, (None, None))[1]
        if got != want:
            mismatches.append((category, colour, want, got))
    return len(expected), mismatches


def main(argv):
    if argv and argv[0] == "--check":
        failures = 0
        for pkgdef_path in argv[1:]:
            name = os.path.basename(pkgdef_path).replace(".pkgdef", "")
            matches = glob.glob(
                os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                             "**", name + ".vstheme"),
                recursive=True,
            )
            if not matches:
                print("%s: no matching .vstheme found" % name)
                failures += 1
                continue
            total, mismatches = check(pkgdef_path, matches[0])
            for category, colour, want, got in mismatches:
                print("  %s %s/%s expected %s but the package has %s"
                      % (name, category, colour, want, got))
            print("%-18s %3d foreground(s) checked, %d mismatch(es)"
                  % (name, total, len(mismatches)))
            failures += len(mismatches)
        return 1 if failures else 0

    for path in argv:
        print("=== %s ===" % os.path.basename(path))
        for category, entries in read(path).items():
            print("  [%s] %d colour(s)" % (category, len(entries)))
            for colour, (bg, fg) in entries.items():
                print("    %-32s bg=%-8s fg=%s" % (colour, bg or "-", fg or "-"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
