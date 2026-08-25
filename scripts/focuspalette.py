"""The Focus palettes, and the colour maths that fills in what they imply.

One table for every platform. `gen-themes.py` (Visual Studio),
`vscode/gen-vscode.py` and `jetbrains/gen-jetbrains.py` all read this module, so
a hue changes in one place and the whole family follows. Nothing outside this
file should contain a literal colour.

Palettes come from the "Visual Studio ADHD color scheme" design explorations.
Every direction there supplies twelve named swatches, a regex sub-family and a
full editor mockup, so every syntax hue and the three surface depths (editor /
chrome / panel) are read straight from the design. Nothing here invents a colour:
the few values not drawn - raised surface, border, selection, line-number grey,
tag and brace pairs - are each a stated function of one that was.

Two `interface` hues are the exception, and deliberately so: the design tints
`class` for Signal and Nightdive, which left the two all but indistinguishable.
Both were rotated to a hue of their own instead.
"""
import colorsys

# Every dark theme falls back to the built-in VS Dark for anything it does not paint.
FALLBACK = "{1ded0138-47ce-435e-84ef-9ec1f439b749}"

# ---------------------------------------------------------------------------
# Contrast report
# ---------------------------------------------------------------------------
# Syntax hues are the designer's and are never auto-corrected here; the report
# exists so a palette that drops below AA is a decision rather than an accident.
#
# Comments and the gutter are held to 3.0 rather than 4.5 on purpose, and the
# report says so rather than quietly moving the goalposts: every direction in the
# design makes commentary recede, and lifting it to AA would put comments at the
# same weight as code. That is a deliberate deviation from AA for those two
# roles; each is still above the 3.0 that WCAG 1.4.11 asks of non-text UI.
AA = 4.5
RECESSIVE = 3.0


# ---------------------------------------------------------------------------
# Palettes
# ---------------------------------------------------------------------------
# Keys read from the design:
#   bg/chrome/panel   the three surface depths in each mockup (editor, tab strip, sidebar)
#   text/comment      plain text and the COMMENT swatch
#   linenum           the mockup's line-number grey, lifted to 3:1 below
#   accent            the hue the mockup's status bar and active-tab underline use
#   keyword..operator the twelve named swatches, on the shared role taxonomy
#   regex_text        the pattern text, drawn a shade below the string hue
#   regex_group       the grouping metacharacters, drawn as a light neutral
#   border            tint + alpha of the card's own 1px border, flattened onto bg
#
# The design separates all five C# type kinds. `class` carries each direction's
# primary type hue and `interface` a lighter tint of it, set in italic by
# FocusEmphasis.cs - same family, unmistakable at a glance. `record`, `struct`
# and `enum` each take a hue of their own, because a data shape and a state name
# are not the same kind of thing as a service. Roslyn ships a separate
# classification for each of the five, so all of it is reachable from Fonts and
# Colors; only the italic needs the MEF component.
#
# Two roles are drawn as tints of another rather than as hues of their own, and
# that is a decision rather than a shortage of hues:
#
#   variable   the direction's own plain-text hue, desaturated. Names are the
#              most frequent thing on screen, so a sixth full-strength hue there
#              would make every line compete with itself. They read as text.
#   operator   the keyword hue, lightened. An operator is syntax, like a keyword,
#              so it stays in that family - but it recurs several times per line,
#              so it recedes rather than shouts.
#
# Both therefore sit within a few degrees of what they tint, and the separation
# report at the end of every run measures hue only. That is why it reports rather
# than fails: for those two pairs, saturation and lightness are the channels
# doing the work.

PALETTES = [
    {
        "name": "Focus Voltage",
        "file": "FocusVoltage.vstheme",
        "guid": "{407ed56e-7d85-4ca7-a39c-1a6fe2e1e5c4}",
        "desc": "Hot pink keywords against cyan types - the two loudest hues sit at\n"
                "       opposite ends of the wheel, so structure pops before you read a word.\n"
                "       Reference types stay cool (cyan class, mint italic interface) and value\n"
                "       types go warm (lime record, amber struct, orange enum), so the\n"
                "       cool/warm split alone says what you are looking at.",
        "bg": "090B10", "chrome": "0D1017", "panel": "0B0E14",
        "text": "D6E1F2", "comment": "5A6A85", "linenum": "2E3949",
        "accent": "FF2E88",
        "keyword": "FF2E88",
        "class": "3BE8FF", "interface": "6FFFD1",
        "record": "B6FF3D", "struct": "FFD24D", "enum": "FF7A1A",
        "method": "9B8CFF", "variable": "AEBED6", "operator": "FF9EC4",
        "string": "4ADE80", "number": "FFF275",
        "regex_text": "2F8551", "regex_group": "CAD5E4",
        "border": ("3BE8FF", 0.14),
    },
    {
        "name": "Focus Ultraviolet",
        "file": "FocusUltraviolet.vstheme",
        "guid": "{98a42f1e-36d1-44fe-b654-66b24f138651}",
        "desc": "A violet ground with magenta classes, sky records and mint structs -\n"
                "       behaviour and data occupy different temperature zones, so a DTO never\n"
                "       reads as a service.",
        "bg": "0B0714", "chrome": "120C1F", "panel": "0E0918",
        "text": "E4DAFF", "comment": "6E5A8C", "linenum": "3A2B52",
        "accent": "C77DFF",
        "keyword": "C77DFF",
        "class": "FF6EC7", "interface": "FFB3E3",
        "record": "6BE1FF", "struct": "5CFFB1", "enum": "FF9060",
        "method": "FFD166", "variable": "B7ABD4", "operator": "E0BFFF",
        "string": "A3FF6B", "number": "FFF3A3",
        "regex_text": "639746", "regex_group": "D0C8E3",
        "border": ("C77DFF", 0.18),
    },
    {
        "name": "Focus Reactor",
        "file": "FocusReactor.vstheme",
        "guid": "{a8858c8c-f0f6-4eed-a195-6ef36f084400}",
        "desc": "A green-black ground reads calmer than a blue one, which lets a single\n"
                "       orange accent carry all the urgency. Aqua class, pale-aqua italic\n"
                "       interface, violet record, pink struct, azure enum - five type kinds,\n"
                "       five clearly separated hues, with literals kept in one chartreuse\n"
                "       family so they never compete with declarations.",
        "bg": "06100E", "chrome": "0A1715", "panel": "081310",
        "text": "D8F3EC", "comment": "4E6E68", "linenum": "23403A",
        "accent": "FF7A1A",
        "keyword": "FF7A1A",
        "class": "2EF2C2", "interface": "9FFFE3",
        "record": "A78BFA", "struct": "FF6EA9", "enum": "63D8FF",
        "method": "FFE066", "variable": "A9C7C0", "operator": "FFB27A",
        "string": "C6FF4D", "number": "E8FF9E",
        "regex_text": "759B33", "regex_group": "C7DBD6",
        "border": ("2EF2C2", 0.16),
    },
    {
        "name": "Focus Arcade",
        "file": "FocusArcade.vstheme",
        "guid": "{85295a98-be43-456a-8e26-703f5a7742e2}",
        "desc": "The loudest of the six: five saturated hues at near-equal weight. Nothing\n"
                "       recedes except comments, which is the point - every token class claims\n"
                "       its own hue rather than sharing one. With five type kinds in play that\n"
                "       puts real pressure on the yellow family.",
        "bg": "0D0912", "chrome": "150F1C", "panel": "100B16",
        "text": "F2E9FF", "comment": "6B5E7A", "linenum": "322A3D",
        "accent": "FF3D7F",
        "keyword": "FF3D7F",
        "class": "FFE94E", "interface": "FFF9C4",
        "record": "FF9F1C", "struct": "3DFFC9", "enum": "C084FC",
        "method": "4DA8FF", "variable": "C0B4D1", "operator": "FF9CC0",
        "string": "9FFF6B", "number": "D9FFB3",
        "regex_text": "629846", "regex_group": "D6CEE1",
        "border": ("FF3D7F", 0.18),
    },
    {
        "name": "Focus Signal",
        "file": "FocusSignal.vstheme",
        "guid": "{c75de096-4883-426b-beab-cfb9ef10843c}",
        "desc": "The restrained option. A neutral grey-black ground, one orange-red accent\n"
                "       for keywords, cooler hues for everything else. All five type kinds still\n"
                "       separate cleanly - blue class, periwinkle italic interface, violet record,\n"
                "       teal struct, pink enum - but nothing shouts. The safest pick for\n"
                "       eight-hour days.",
        "bg": "101116", "chrome": "16181F", "panel": "13151B",
        "text": "E6E8EF", "comment": "6B7280", "linenum": "383B45",
        "accent": "FF5C39",
        "keyword": "FF5C39",
        "class": "35C2FF", "interface": "6E9BFF",
        "record": "C084FC", "struct": "2DD4BF", "enum": "F472B6",
        "method": "FBBF24", "variable": "B4BAC7", "operator": "FF9E85",
        "string": "4ADE80", "number": "A3E635",
        "regex_text": "328853", "regex_group": "CED2DB",
        "border": ("E6E8EF", 0.12),
    },
    {
        "name": "Focus Nightdive",
        "file": "FocusNightdive.vstheme",
        "guid": "{0b7b71a8-4b99-4b29-9507-3a290bc80a13}",
        # The only direction whose accent is not its keyword hue. The design puts
        # coral on keywords but keeps the teal that marks classes on the status bar
        # and the active-tab underline, so accent and keyword part company here.
        "desc": "Deep teal-black with coral keywords, chartreuse records and lavender\n"
                "       structs - complementary pairs, so declarations never blur together in\n"
                "       dense files. The only direction whose accent is not its keyword hue:\n"
                "       the teal that marks classes carries the chrome instead.",
        "bg": "040F14", "chrome": "08171D", "panel": "061319",
        "text": "D2ECF2", "comment": "4A6B75", "linenum": "1E3A42",
        "accent": "4DE1C1",
        "keyword": "FF6B6B",
        "class": "4DE1C1", "interface": "4DF2A0",
        "record": "C6FF4D", "struct": "B39BFF", "enum": "FF9BD2",
        "method": "59B8FF", "variable": "A3BFC7", "operator": "FFA8A8",
        "string": "FFC24D", "number": "FFE3A8",
        "regex_text": "967735", "regex_group": "C3D5DB",
        "border": ("4DE1C1", 0.16),
    },
]

# ---------------------------------------------------------------------------
# Colour maths
# ---------------------------------------------------------------------------
def rgb(hex6_):
    return tuple(int(hex6_[i:i + 2], 16) for i in (0, 2, 4))


def to_hex(triple):
    return "".join("%02X" % max(0, min(255, int(round(c)))) for c in triple)


def mix(a, b, t):
    """Blend hex a toward hex b by t (0..1)."""
    ra, rb = rgb(a), rgb(b)
    return to_hex(tuple(ra[i] + (rb[i] - ra[i]) * t for i in range(3)))


def to_hsl(hex_):
    """(hue 0-360, saturation 0-1, lightness 0-1)."""
    r, g, b = [c / 255.0 for c in rgb(hex_)]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return h * 360.0, s, l


def hue_gap(a, b):
    """Shortest angular distance between two hues, in degrees."""
    d = abs(a - b) % 360.0
    return min(d, 360.0 - d)


def luminance(hex_):
    def chan(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = rgb(hex_)
    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def contrast(fg, bg):
    a, b = luminance(fg) + 0.05, luminance(bg) + 0.05
    return max(a, b) / min(a, b)


def lift(fg, bg, toward, target):
    """Blend fg toward `toward` until it clears `target`:1 against bg."""
    for step in range(0, 101):
        candidate = mix(fg, toward, step / 100.0)
        if contrast(candidate, bg) >= target:
            return candidate
    return toward


def derive(p):
    """Fill in the values the design states as a function of another."""
    bg, text = p["bg"], p["text"]
    tint, alpha = p["border"]
    d = dict(p)
    d["fallback"] = FALLBACK
    d["border"] = mix(bg, tint, alpha)
    d["raised"] = mix(p["chrome"], text, 0.08)
    d["sel"] = mix(bg, text, 0.20)
    d["isel"] = mix(bg, text, 0.11)
    # The mockups' line-number grey is dimmer than a real gutter can afford;
    # keep its hue but lift it until it is legible.
    d["muted"] = lift(p["linenum"], bg, text, RECESSIVE)

    d["punct"] = p["comment"]
    # Constants and escape sequences ride with numbers.
    d["constant"] = p["number"]
    # An XML/XAML/HTML element name is a type name in another spelling.
    d["tag"] = p["class"]
    # Nested brace pairs cycle through the three loudest non-keyword hues. The
    # keyword hue is reserved: a mismatched brace uses it, and that warning only
    # reads as a warning if nothing else on the line is already wearing it.
    d["brace1"], d["brace2"], d["brace3"] = p["class"], p["method"], p["string"]
    d["regex"] = regex_block(p)
    return d


# Roslyn splits the inside of a regex literal into nine classifications. The
# design draws the sub-family directly - "the pattern text sits a shade below the
# string hue so the metacharacters are the part that pops" - and every mockup
# renders the same two sample patterns, so the nine are read from the design
# rather than chosen here.
#
# Four of them turn out to be roles this palette already has. That is the
# design's own doing, not a shortcut: a quantifier is syntax like a keyword, an
# anchor is positional like a method call, a character class names a set the way
# an enum names one, and an escape is a literal wearing a metacharacter's clothes
# the way a struct is a value wearing a type's. Only two values are outside the
# existing roles, and those are the two each palette states as swatches:
# regex_text and regex_group.
#
# `regex - comment` - the `(?#...)` form - is not in the mockups, because nobody
# writes them. It takes the direction's comment hue, which is what it is.
REGEX_ROLES = (
    ("text", "regex_text"),                     # the literal characters matched
    ("grouping", "regex_group"),                # ( ) (?<name> )
    ("quantifier", "keyword"),                  # * + ? {4,6}
    ("alternation", "keyword"),                 # |
    ("anchor", "method"),                       # ^ $ \b
    ("character class", "enum"),                # \d \w [A-Z]
    ("self escaped character", "struct"),       # \. \+ - a metacharacter made literal
    ("other escape", "struct"),                 # \n \t é
    ("comment", "comment"),                     # (?#...)
)


def regex_block(p):
    """The nine `regex - *` entries for one palette."""
    missing = [key for _part, key in REGEX_ROLES if key not in p]
    if missing:
        raise SystemExit("%s: palette is missing %s" % (p["name"], ", ".join(missing)))
    return "      <!-- Regex literal internals -->\n" + "".join(
        '      <Color Name="regex - %s">\n'
        '        <Foreground Type="CT_RAW" Source="FF%s"/>\n'
        '      </Color>\n' % (part, p[key]) for part, key in REGEX_ROLES)

REPORTED = [
    ("text", "plain text", AA),
    ("keyword", "keyword", AA),
    ("class", "class", AA),
    ("interface", "interface", AA),
    ("record", "record", AA),
    ("struct", "struct", AA),
    ("enum", "enum", AA),
    ("method", "method", AA),
    ("variable", "variable", AA),
    ("operator", "operator", AA),
    ("string", "string", AA),
    ("number", "number", AA),
    ("regex_group", "regex group", AA),
    ("comment", "comment", RECESSIVE),
    ("muted", "gutter", RECESSIVE),
    # Recessive for the same reason as comment, and stated by the design rather
    # than chosen here: the pattern text sits a shade below the string hue so the
    # metacharacters are what pops. Lifting it to AA would flatten the sub-family
    # back into one green and lose the distinction the design is making.
    ("regex_text", "regex text", RECESSIVE),
]

# The design's first rule is that no two token classes read alike, so the syntax
# hues are measured against each other rather than trusted. This used to gate the
# run, because two of them were synthesised here and a collision was this
# script's bug. Every hue is now drawn, so a tight pair is the direction's own
# trade-off and the run only reports it.
#
# `interface` is left out on purpose. The design keeps it in the `class` family
# deliberately -- a lighter tint of it in some directions, a rotation off it at
# full chroma in others -- so it lands close by construction and would drown out
# the pairs worth looking at. Italic, not hue, is what separates it.
SEPARATED = ("keyword", "class", "record", "struct", "enum", "method",
             "variable", "operator", "string", "number")
CLOSEST_REPORTED = 3


# ---------------------------------------------------------------------------
# Roles the other two platforms need
# ---------------------------------------------------------------------------
# Visual Studio asks a theme for colour in one place: named colour entries. VS
# Code and the JetBrains IDEs ask for more - diagnostic severities, diff gutters,
# git decorations, and sixteen ANSI slots for the built-in terminal. None of that
# is a new hue. Each is a stated function of a role the design already drew, on
# the same rule the rest of this file follows: a colour is either read from the
# design or derived from one that was.
#
# The severity mapping is the one the .vstheme already makes for inline
# diagnostics (`inline diagnostics - syntax error` takes the keyword hue,
# `- compiler warning` takes the enum hue); it is repeated here so VS Code's
# squiggles, problem badges and JetBrains' inspection stripes agree with the
# Visual Studio editor rather than each having their own idea of "error red".

SEVERITY_ROLES = (
    ("error", "keyword"),      # each direction's loudest hue
    ("warning", "enum"),       # warm everywhere, without being the alarm colour
    ("info", "class"),         # the primary type hue, informational
    ("success", "string"),     # green or near-green in all six
    ("hint", "comment"),       # the editor talking, not the code
)

# Diff and version control. Added rides with strings and removed with the error
# hue, so a diff reads with the same vocabulary as a diagnostic. `modified` takes
# the method hue: it is the third-loudest role and is not already spoken for.
VCS_ROLES = (
    ("added", "string"),
    ("removed", "keyword"),
    ("modified", "method"),
    ("ignored", "muted"),
    ("conflict", "enum"),
)

# The sixteen terminal slots. Six of the eight chromatic names land on a named
# swatch; `magenta` takes `record` because it is the remaining saturated hue in
# every direction, and `white`/`black` are the plain-text and chrome surfaces the
# design already states. The bright half is each base lifted a quarter of the way
# to white - one function, applied eight times, rather than eight more choices.
ANSI_ROLES = (
    ("Black", "chrome"),
    ("Red", "keyword"),
    ("Green", "string"),
    ("Yellow", "number"),
    ("Blue", "method"),
    ("Magenta", "record"),
    ("Cyan", "class"),
    ("White", "text"),
)
BRIGHTEN = 0.25


def alpha(hex_, a):
    """VS Code's #RRGGBBAA. Note the order: Visual Studio writes AARRGGBB."""
    return "#%s%02X" % (hex_, max(0, min(255, int(round(a * 255)))))


def derive_extended(p):
    """`derive()` plus the roles only VS Code and JetBrains ask for."""
    d = derive(p)
    for role, source in SEVERITY_ROLES + VCS_ROLES:
        d[role] = d[source]
    for name, source in ANSI_ROLES:
        d["ansi" + name] = d[source]
        d["ansiBright" + name] = mix(d[source], "FFFFFF", BRIGHTEN)

    # Two more surface depths. VS Code layers dropdowns, hovers and the command
    # palette above the panel, and a theme that leaves them at the panel colour
    # loses the edge between the overlay and what it covers.
    d["overlay"] = mix(p["chrome"], p["text"], 0.12)
    d["shadow"] = mix(p["bg"], "000000", 0.60)
    # The caret and the current-line band. Both are stated relative to the
    # selection the design already implies rather than picked.
    d["caret"] = p["accent"]
    d["currentline"] = mix(p["bg"], p["text"], 0.05)
    # A found match has to be visible against the selection band without being
    # mistaken for it, so it takes the accent at low alpha rather than a grey.
    d["findmatch"] = mix(p["bg"], p["accent"], 0.30)
    d["findmatchOther"] = mix(p["bg"], p["accent"], 0.16)
    # Same idea for the "other occurrences of this symbol" highlight.
    d["wordhighlight"] = mix(p["bg"], p["class"], 0.18)
    return d
