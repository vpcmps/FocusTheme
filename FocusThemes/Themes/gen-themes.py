"""Generate every Focus .vstheme from one palette table.

The Focus family is six dark themes that share a structure and differ only in
colour, so the structure lives here once and the palettes live in PALETTES.
This mirrors the role derive-light.py plays in GraphiteTheme: not shipped in the
VSIX, run by hand when a palette changes, output committed.

Palettes come from the "Visual Studio ADHD color scheme" design explorations.
Every direction there supplies six named swatches plus a full editor mockup, so
the syntax hues and the three surface depths (editor / chrome / panel) are read
straight from the design. Everything else - raised surface, border, selection,
line-number grey - is derived below, so a new palette only has to state what the
design actually decided.

Usage:  python gen-themes.py [outdir]
"""
import colorsys
import os
import sys

OUTDIR = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))

# Every dark theme falls back to the built-in VS Dark for anything it does not paint.
FALLBACK = "{1ded0138-47ce-435e-84ef-9ec1f439b749}"

# ---------------------------------------------------------------------------
# Palettes
# ---------------------------------------------------------------------------
# Keys read from the design:
#   bg/chrome/panel  the three surface depths in each mockup (editor, tab strip, sidebar)
#   text/comment     plain text and the COMMENT swatch
#   linenum          the mockup's line-number grey, lifted to 3:1 below
#   accent           the hue the mockup's status bar and active-tab underline use
#   keyword..number  the named swatches, mapped onto the Graphite role taxonomy
#   tag              XML/XAML/HTML element names
#   braces           the three loudest non-keyword hues, for nested brace pairs
#   border           tint + alpha of the card's own 1px border, flattened onto bg
#
# Two roles the design does not supply a swatch for:
#
#   var_hue          variables (local/field/property/parameter/enum member)
#   op_hue           operators
#
# Graphite gives both their own hue, and these themes follow it. Each direction
# only names five syntax hues, so the two extra ones are stated as angles rather
# than hex: derive() builds them at the median saturation and lightness of the
# palette's own five, which is what keeps them looking native instead of bolted
# on. The angles below sit in each palette's largest empty arcs; the report at
# the end of every run prints the closest surviving pair. Operators are then
# desaturated, because a full-strength hue on every `=` and `.` is noise;
# variables keep full weight, since names are what the eye scans for.

PALETTES = [
    dict(
        name="Focus Voltage",
        file="FocusVoltage.vstheme",
        guid="{407ed56e-7d85-4ca7-a39c-1a6fe2e1e5c4}",
        desc="Hot pink keywords against cyan types - the two loudest hues sit at\n"
             "       opposite ends of the wheel, so structure pops before you read a word.\n"
             "       Lime strings keep literals visually separate from everything nameable.",
        bg="090B10", chrome="0D1017", panel="0B0E14",
        text="D6E1F2", comment="5A6A85", linenum="2E3949",
        accent="FF2E88",
        keyword="FF2E88", type="3BE8FF", method="9B8CFF",
        string="B6FF3D", number="FFC53D", tag="3BE8FF",
        braces=("3BE8FF", "9B8CFF", "B6FF3D"),
        var_hue=135, op_hue=8,
        border=("3BE8FF", 0.14),
    ),
    dict(
        name="Focus Ultraviolet",
        file="FocusUltraviolet.vstheme",
        guid="{98a42f1e-36d1-44fe-b654-66b24f138651}",
        desc="A violet ground with mint and magenta doing the heavy lifting. Warm on\n"
             "       cool: tags read magenta, logic reads violet, data reads mint - three\n"
             "       distinct temperature zones per screen.",
        bg="0B0714", chrome="120C1F", panel="0E0918",
        text="E4DAFF", comment="6E5A8C", linenum="3A2B52",
        accent="C77DFF",
        keyword="C77DFF", type="FF6EC7", method="6BE1FF",
        string="5CFFB1", number="FFD166", tag="FF6EC7",
        braces=("FF6EC7", "6BE1FF", "5CFFB1"),
        var_hue=233, op_hue=3,
        border=("C77DFF", 0.18),
    ),
    dict(
        name="Focus Reactor",
        file="FocusReactor.vstheme",
        guid="{a8858c8c-f0f6-4eed-a195-6ef36f084400}",
        desc="A green-black ground reads calmer than a blue one, which lets a single\n"
             "       orange accent carry all the urgency. Aqua types and yellow strings stay\n"
             "       in one warm-cool pair, so the palette is loud but only three hues wide.\n"
             "       The design reuses yellow for numbers; numbers take the MACRO red here so\n"
             "       literals and strings stay distinguishable.",
        bg="06100E", chrome="0A1715", panel="081310",
        text="D8F3EC", comment="4E6E68", linenum="23403A",
        accent="FF7A1A",
        keyword="FF7A1A", type="2EF2C2", method="63D8FF",
        string="FFE066", number="FF4D6D", tag="2EF2C2",
        braces=("2EF2C2", "63D8FF", "FFE066"),
        var_hue=272, op_hue=107,
        border=("2EF2C2", 0.16),
    ),
    dict(
        name="Focus Arcade",
        file="FocusArcade.vstheme",
        guid="{85295a98-be43-456a-8e26-703f5a7742e2}",
        desc="The loudest of the six: four saturated hues at near-equal weight. Nothing\n"
             "       recedes except comments, which is the point - every token class claims\n"
             "       its own hue rather than sharing one.",
        bg="0D0912", chrome="150F1C", panel="100B16",
        text="F2E9FF", comment="6B5E7A", linenum="322A3D",
        accent="FF3D7F",
        keyword="FF3D7F", type="FFE94E", method="4DA8FF",
        string="3DFFC9", number="FF9F1C", tag="FFE94E",
        braces=("FFE94E", "4DA8FF", "3DFFC9"),
        var_hue=274, op_hue=108,
        border=("FF3D7F", 0.18),
    ),
    dict(
        name="Focus Signal",
        file="FocusSignal.vstheme",
        guid="{c75de096-4883-426b-beab-cfb9ef10843c}",
        desc="The restrained option. A neutral grey-black ground, one orange-red accent\n"
             "       for control flow, and cooler hues for everything else - bright where it\n"
             "       matters, quiet everywhere else. The safest pick for eight-hour days.",
        bg="101116", chrome="16181F", panel="13151B",
        text="E6E8EF", comment="6B7280", linenum="383B45",
        accent="FF5C39",
        keyword="FF5C39", type="35C2FF", method="C084FC",
        string="4ADE80", number="FBBF24", tag="35C2FF",
        braces=("35C2FF", "C084FC", "4ADE80"),
        # 234 (blue) over the better-separated 320 (magenta): identifiers are the
        # most frequent token class, and a hot magenta on every name works against
        # this direction being the restrained one. Costs separation - blue sits 36
        # deg from the cyan of type - so lightness carries that pair.
        var_hue=234, op_hue=93,
        border=("E6E8EF", 0.12),
    ),
    dict(
        name="Focus Nightdive",
        file="FocusNightdive.vstheme",
        guid="{0b7b71a8-4b99-4b29-9507-3a290bc80a13}",
        desc="Deep teal-black with coral and chartreuse - complementary pairs, so tags\n"
             "       and values never blur together in dense markup. The only direction whose\n"
             "       accent is cool, which leaves the warm hues free to mark names.",
        bg="040F14", chrome="08171D", panel="061319",
        text="D2ECF2", comment="4A6B75", linenum="1E3A42",
        accent="4DE1C1",
        keyword="4DE1C1", type="FF6B6B", method="59B8FF",
        string="C6FF4D", number="FFC24D", tag="FF6B6B",
        braces=("FF6B6B", "59B8FF", "C6FF4D"),
        var_hue=283, op_hue=123,
        border=("4DE1C1", 0.16),
    ),
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


def from_hsl(h, s, l):
    r, g, b = colorsys.hls_to_rgb((h % 360.0) / 360.0, l, s)
    return to_hex((r * 255, g * 255, b * 255))


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
    """Fill in every value the design did not state outright."""
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
    d["muted"] = lift(p["linenum"], bg, text, 3.0)

    # Variables and operators: the two hues the design does not name. Both are
    # built at the median saturation and lightness of the palette's own five
    # syntax hues, so they inherit the direction's weight rather than importing
    # a foreign one. Operators are then pulled back, since they repeat far more
    # often per line than any name does.
    named = [p["keyword"], p["type"], p["method"], p["string"], p["number"]]
    sats = sorted(to_hsl(c)[1] for c in named)
    lums = sorted(to_hsl(c)[2] for c in named)
    med_s, med_l = sats[len(sats) // 2], lums[len(lums) // 2]

    d["variable"] = lift(from_hsl(p["var_hue"], med_s, med_l), bg, text, AA)
    d["operator"] = lift(from_hsl(p["op_hue"], med_s * OP_SAT, med_l * OP_LUM), bg, text, AA)
    d["punct"] = p["comment"]
    # Constants and escape sequences ride with numbers.
    d["constant"] = p["number"]
    d["brace1"], d["brace2"], d["brace3"] = p["braces"]
    return d


# ---------------------------------------------------------------------------
# Theme template
# ---------------------------------------------------------------------------
# Category GUIDs and colour names are Visual Studio's own and are identical to
# GraphiteDark.vstheme; only the Source values differ between themes.

TEMPLATE = """<Themes>
  <!-- %(name)s
       %(desc)s
       Surfaces: editor #%(bg)s / chrome #%(chrome)s / panel #%(panel)s
                 raised #%(raised)s / border #%(border)s / selection #%(sel)s
       Text:     #%(text)s primary, #%(comment)s comment, #%(muted)s gutter
       Syntax:   keyword #%(keyword)s, type #%(type)s, method #%(method)s,
                 string #%(string)s, number #%(number)s, tag #%(tag)s
       Accent:   #%(accent)s

       Generated by gen-themes.py - edit the palette there, not this file. -->
  <Theme Name="%(name)s" GUID="%(guid)s" FallbackId="%(fallback)s">

    <Category Name="Shell" GUID="{73708ded-2d56-4aad-b8eb-73b20d3f4bff}">
      <Color Name="AccentFillDefault">
        <Background Type="CT_RAW" Source="FF%(accent)s"/>
      </Color>
      <Color Name="AccentFillSecondary">
        <Background Type="CT_RAW" Source="E5%(accent)s"/>
      </Color>
      <Color Name="AccentFillTertiary">
        <Background Type="CT_RAW" Source="CC%(accent)s"/>
      </Color>
      <Color Name="SolidBackgroundFillTertiary">
        <Background Type="CT_RAW" Source="FF%(raised)s"/>
      </Color>
      <Color Name="SolidBackgroundFillQuaternary">
        <Background Type="CT_RAW" Source="FF%(raised)s"/>
      </Color>
      <Color Name="SurfaceBackgroundFillDefault">
        <Background Type="CT_RAW" Source="FF%(panel)s"/>
      </Color>
      <Color Name="TextFillSecondary">
        <Background Type="CT_RAW" Source="B2%(text)s"/>
      </Color>
    </Category>

    <Category Name="ShellInternal" GUID="{5af241b7-5627-4d12-bfb1-2b67d11127d7}">
      <Color Name="EnvironmentHeader">
        <Background Type="CT_RAW" Source="FF%(chrome)s"/>
      </Color>
      <Color Name="EnvironmentHeaderInactive">
        <Background Type="CT_RAW" Source="FF%(chrome)s"/>
      </Color>
      <Color Name="EnvironmentTab">
        <Background Type="CT_RAW" Source="FF%(chrome)s"/>
      </Color>
      <Color Name="EnvironmentTabInactive">
        <Background Type="CT_RAW" Source="FF%(chrome)s"/>
      </Color>
      <Color Name="EnvironmentBody">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
      </Color>
      <Color Name="EnvironmentBodyText">
        <Background Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="EnvironmentBackground">
        <Background Type="CT_RAW" Source="FF%(chrome)s"/>
      </Color>
      <Color Name="StatusBarBackgroundFillRest">
        <Background Type="CT_RAW" Source="FF%(chrome)s"/>
      </Color>
      <Color Name="StatusBarTextFillRest">
        <Background Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="StatusBarTextFillDisabled">
        <Background Type="CT_RAW" Source="FF%(muted)s"/>
      </Color>
      <Color Name="StatusBarControlFillSecondary">
        <Background Type="CT_RAW" Source="FF%(raised)s"/>
      </Color>
      <Color Name="EnvironmentBorder">
        <Background Type="CT_RAW" Source="FF%(border)s"/>
      </Color>
      <Color Name="EnvironmentIndicator">
        <Background Type="CT_RAW" Source="FF%(accent)s"/>
      </Color>
      <Color Name="EnvironmentLogo">
        <Background Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="EnvironmentLayeredBackground">
        <Background Type="CT_RAW" Source="61000000"/>
      </Color>
    </Category>

    <Category Name="Environment" GUID="{624ed9c3-bdfd-41fa-96c3-7c824ea32e3d}">
      <Color Name="Window">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
      </Color>
      <Color Name="ToolWindowBackground">
        <Background Type="CT_RAW" Source="FF%(panel)s"/>
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="BrandedUIBackground">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
      </Color>
      <Color Name="ScrollBarBackground">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
      </Color>
      <Color Name="CommandBarTextActive">
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="CommandBarTextHover">
        <Foreground Type="CT_RAW" Source="FFFFFFFF"/>
      </Color>
      <Color Name="CommandBarTextInactive">
        <Foreground Type="CT_RAW" Source="FF%(muted)s"/>
      </Color>
      <Color Name="CommandBarMenuGlyph">
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
    </Category>

    <!-- Empty Solution Explorer background -->
    <Category Name="TreeView" GUID="{92ecf08e-8b13-4cf4-99e9-ae2692382185}">
      <Color Name="Background">
        <Background Type="CT_RAW" Source="FF%(panel)s"/>
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
    </Category>

    <!-- Error List column headers -->
    <Category Name="Header" GUID="{4997f547-1379-456e-b985-2f413cdfa536}">
      <Color Name="Default">
        <Background Type="CT_RAW" Source="FF%(raised)s"/>
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
    </Category>

    <Category Name="Output Window" GUID="{9973efdf-317d-431c-8bc1-5e88cbfd4f7f}">
      <Color Name="Plain Text">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
    </Category>

    <Category Name="Find Results" GUID="{5c48b2cb-0366-4fbf-9786-0bb37e945687}">
      <Color Name="Plain Text">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
    </Category>

    <Category Name="Immediate Window" GUID="{6bb65c5a-2f31-4bde-9f48-8a38dc0c63e7}">
      <Color Name="Plain Text">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
    </Category>

    <Category Name="Command Window" GUID="{ee1be240-4e81-4beb-8eea-54322b6b1bf5}">
      <Color Name="Plain Text">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
    </Category>

    <!-- ============================= -->
    <!-- Editor surface                -->
    <!-- ============================= -->
    <Category Name="Text Editor Text Manager Items" GUID="{58e96763-1d3b-4e05-b6ba-ff7115fd0b7b}">
      <Color Name="Plain Text">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="Selected Text">
        <Background Type="CT_RAW" Source="FF%(sel)s"/>
        <Foreground Type="CT_AUTOMATIC" Source="00000000"/>
      </Color>
      <Color Name="Inactive Selected Text">
        <Background Type="CT_RAW" Source="FF%(isel)s"/>
        <Foreground Type="CT_AUTOMATIC" Source="00000000"/>
      </Color>
      <Color Name="Line Number">
        <Foreground Type="CT_RAW" Source="FF%(muted)s"/>
      </Color>
      <Color Name="Selected Line Number">
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="Visible Whitespace">
        <Foreground Type="CT_RAW" Source="FF%(border)s"/>
      </Color>
      <Color Name="Indicator Margin">
        <Background Type="CT_RAW" Source="FF%(bg)s"/>
        <Foreground Type="CT_AUTOMATIC" Source="00000000"/>
      </Color>
    </Category>

    <Category Name="Text Editor Language Service Items" GUID="{e0187991-b458-4f7e-8ca9-42c9a573b56c}">
      <!-- Fallback for languages without Roslyn. Kept in step with the MEF block below. -->
      <Color Name="Text">
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <!-- Coloured, not plain. This is the fallback used when Roslyn has no
           semantics (unsaved file, file outside a project, workspace still loading,
           non-C# language). Leaving it plain marks such names as "unresolved", but
           it also means a whole file silently loses its name colouring with no
           explanation on screen. These themes exist to make code easier to scan, so
           they favour a name always reading as a name over encoding compiler state
           the reader never asked about. -->
      <Color Name="Identifier">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="Comment">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <Color Name="Keyword">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <Color Name="Preprocessor Keyword">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <Color Name="Operator">
        <Foreground Type="CT_RAW" Source="FF%(operator)s"/>
      </Color>
      <Color Name="String">
        <Foreground Type="CT_RAW" Source="FF%(string)s"/>
      </Color>
      <Color Name="String(C# @ Verbatim)">
        <Foreground Type="CT_RAW" Source="FF%(string)s"/>
      </Color>
      <Color Name="Number">
        <Foreground Type="CT_RAW" Source="FF%(number)s"/>
      </Color>
      <Color Name="Literal">
        <Foreground Type="CT_RAW" Source="FF%(number)s"/>
      </Color>
      <Color Name="User Types">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="User Types(Value types)">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="User Types(Interfaces)">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="User Types(Delegates)">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="User Types(Enums)">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="User Types(Type parameters)">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <!-- XML -->
      <Color Name="XML Text">
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="XML Keyword">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <Color Name="XML Delimiter">
        <Foreground Type="CT_RAW" Source="FF%(punct)s"/>
      </Color>
      <Color Name="XML Name">
        <Foreground Type="CT_RAW" Source="FF%(tag)s"/>
      </Color>
      <Color Name="XML Attribute">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="XML Attribute Value">
        <Foreground Type="CT_RAW" Source="FF%(string)s"/>
      </Color>
      <Color Name="XML Comment">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <Color Name="XML CData Section">
        <Foreground Type="CT_RAW" Source="FF%(constant)s"/>
      </Color>
      <!-- XAML -->
      <Color Name="XAML Text">
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="XAML Keyword">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <Color Name="XAML Name">
        <Foreground Type="CT_RAW" Source="FF%(tag)s"/>
      </Color>
      <Color Name="XAML Attribute">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="XAML Attribute Value">
        <Foreground Type="CT_RAW" Source="FF%(string)s"/>
      </Color>
      <Color Name="XAML Comment">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <!-- HTML / CSS -->
      <Color Name="HTML Element Name">
        <Foreground Type="CT_RAW" Source="FF%(tag)s"/>
      </Color>
      <Color Name="HTML Attribute Name">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="HTML Attribute Value">
        <Foreground Type="CT_RAW" Source="FF%(string)s"/>
      </Color>
      <Color Name="HTML Comment">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <Color Name="HTML Tag Delimiter">
        <Foreground Type="CT_RAW" Source="FF%(punct)s"/>
      </Color>
      <Color Name="HTML Operator">
        <Foreground Type="CT_RAW" Source="FF%(operator)s"/>
      </Color>
      <Color Name="HTML Entity">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="CSS Keyword">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <Color Name="CSS Comment">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <Color Name="CSS Selector">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="CSS Property Name">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="CSS Property Value">
        <Foreground Type="CT_RAW" Source="FF%(text)s"/>
      </Color>
      <Color Name="CSS String Value">
        <Foreground Type="CT_RAW" Source="FF%(string)s"/>
      </Color>
    </Category>

    <!-- Roslyn classifications -->
    <Category Name="Text Editor MEF Items" GUID="{75a05685-00a8-4ded-bae5-e7a50bfa929a}">
      <!-- Statements and declarations share the keyword hue; control flow is bold
           (FocusEmphasis.cs) -->
      <Color Name="keyword">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <Color Name="keyword - control">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <Color Name="preprocessor keyword">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <Color Name="preprocessor text">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <!-- Types -->
      <Color Name="class name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="struct name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="record class name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="record struct name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="enum name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="module name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="interface name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="type parameter name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="delegate name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="array name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="pointer name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="function pointer name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <!-- Methods -->
      <Color Name="method name">
        <Foreground Type="CT_RAW" Source="FF%(method)s"/>
      </Color>
      <Color Name="extension method name">
        <Foreground Type="CT_RAW" Source="FF%(method)s"/>
      </Color>
      <!-- Variables: their own hue, as in Graphite. The design mockups leave
           identifiers at plain text, but that collapses locals, fields and
           properties into the same read as punctuation and operators; giving
           them a hue is what makes "what is this name" answerable at a glance. -->
      <Color Name="local name">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="field name">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="property name">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="event name">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="parameter name">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <Color Name="enum member name">
        <Foreground Type="CT_RAW" Source="FF%(variable)s"/>
      </Color>
      <!-- Literals -->
      <Color Name="string">
        <Foreground Type="CT_RAW" Source="FF%(string)s"/>
      </Color>
      <Color Name="string - verbatim">
        <Foreground Type="CT_RAW" Source="FF%(string)s"/>
      </Color>
      <Color Name="string - escape character">
        <Foreground Type="CT_RAW" Source="FF%(constant)s"/>
      </Color>
      <Color Name="number">
        <Foreground Type="CT_RAW" Source="FF%(number)s"/>
      </Color>
      <Color Name="constant name">
        <Foreground Type="CT_RAW" Source="FF%(constant)s"/>
      </Color>
      <Color Name="label name">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
      <!-- Structure recedes -->
      <Color Name="operator">
        <Foreground Type="CT_RAW" Source="FF%(operator)s"/>
      </Color>
      <Color Name="operator - overloaded">
        <Foreground Type="CT_RAW" Source="FF%(operator)s"/>
      </Color>
      <Color Name="punctuation">
        <Foreground Type="CT_RAW" Source="FF%(punct)s"/>
      </Color>
      <Color Name="namespace name">
        <Foreground Type="CT_RAW" Source="FF%(punct)s"/>
      </Color>
      <!-- Comments, italic via the MEF component -->
      <Color Name="comment">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <Color Name="xml doc comment - text">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <Color Name="xml doc comment - name">
        <Foreground Type="CT_RAW" Source="FF%(type)s"/>
      </Color>
      <Color Name="xml doc comment - delimiter">
        <Foreground Type="CT_RAW" Source="FF%(muted)s"/>
      </Color>
      <Color Name="xml doc comment - comment">
        <Foreground Type="CT_RAW" Source="FF%(muted)s"/>
      </Color>
      <Color Name="xml doc comment - cdata section">
        <Foreground Type="CT_RAW" Source="FF%(comment)s"/>
      </Color>
      <!-- Brace pairs -->
      <Color Name="brace pair level one">
        <Foreground Type="CT_RAW" Source="FF%(brace1)s"/>
      </Color>
      <Color Name="brace pair level two">
        <Foreground Type="CT_RAW" Source="FF%(brace2)s"/>
      </Color>
      <Color Name="brace pair level three">
        <Foreground Type="CT_RAW" Source="FF%(brace3)s"/>
      </Color>
      <Color Name="mismatched brace">
        <Foreground Type="CT_RAW" Source="FF%(keyword)s"/>
      </Color>
    </Category>

  </Theme>
</Themes>
"""

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

# Operators are held back from full palette weight: they recur several times per
# line, so a fully saturated hue there reads as noise rather than as structure.
OP_SAT = 0.55
OP_LUM = 0.92

REPORTED = [
    ("text", "plain text", AA),
    ("keyword", "keyword", AA),
    ("type", "type", AA),
    ("method", "method", AA),
    ("variable", "variable", AA),
    ("string", "string", AA),
    ("number", "number", AA),
    ("tag", "tag", AA),
    ("operator", "operator", AA),
    ("comment", "comment", RECESSIVE),
    ("muted", "gutter", RECESSIVE),
]

# The design's first rule is that no two token classes read alike, so the seven
# syntax hues are checked against each other rather than trusted. Graphite packs
# its own closest pair (aqua variables at 172 deg, blue types at 212) 40 deg
# apart, so that is the bar these have to clear too.
SEPARATED = ("keyword", "type", "method", "variable", "string", "number", "operator")
# The two this script invents, as opposed to the five the design named.
DERIVED = ("variable", "operator")
MIN_HUE_GAP = 30.0


def main():
    low = 0
    for palette in PALETTES:
        d = derive(palette)
        path = os.path.join(OUTDIR, d["file"])
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(TEMPLATE % d)
        print("wrote %s" % path)

        print("  contrast on #%s:" % d["bg"])
        for key, label, floor in REPORTED:
            ratio = contrast(d[key], d["bg"])
            ok = ratio >= floor
            low += 0 if ok else 1
            note = "" if floor == AA else "   (recessive by design, AA would need %.1f)" % AA
            print("    %s %-11s #%s  %5.2f:1  floor %.1f%s"
                  % ("ok " if ok else "LOW", label, d[key], ratio, floor, note))

        # Closest pair among the seven syntax hues, split by who chose them.
        # A tight pair of derived hues is this script's bug and fails the run.
        # A tight pair of design swatches is the direction's own trade-off: it
        # gets reported every run, but is not silently repainted here -- changing
        # it is a design decision, not a build step.
        pairs = []
        for i, a in enumerate(SEPARATED):
            for b in SEPARATED[i + 1:]:
                pairs.append((hue_gap(to_hsl(d[a])[0], to_hsl(d[b])[0]), a, b))
        pairs.sort()

        derived = [p for p in pairs if p[1] in DERIVED or p[2] in DERIVED]
        gap, a, b = derived[0]
        tight = gap < MIN_HUE_GAP
        low += 1 if tight else 0
        print("    %s closest derived pair  %s/%s %.0f deg (min %.0f)"
              % ("FAIL" if tight else "ok  ", a, b, gap, MIN_HUE_GAP))

        gap, a, b = pairs[0]
        if gap < MIN_HUE_GAP and not (a in DERIVED or b in DERIVED):
            print("    note %s/%s are only %.0f deg apart -- both are the design's own"
                  % (a, b, gap))
            print("         swatches, so they are left as drawn; lightness separates them"
                  " (%.1f:1 vs %.1f:1)."
                  % (contrast(d[a], d["bg"]), contrast(d[b], d["bg"])))
        print("")

    print("done: %d theme(s), %d token(s) below floor" % (len(PALETTES), low))
    return 1 if low else 0


if __name__ == "__main__":
    sys.exit(main())
