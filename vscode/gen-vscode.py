"""Generate every Focus VS Code / Cursor colour theme from the shared palette.

Cursor is a VS Code fork and loads these unchanged, so one extension covers both.
Not shipped: run by hand when a palette changes, output committed.

Three layers, and they are not interchangeable:

  colors              the workbench - editor surface, sidebar, tabs, terminal.
  semanticTokenColors what the language server knows. Wins where it fires, which
                      for C#, TypeScript, Python, Rust and Go is most of a file.
  tokenColors         TextMate scopes. The fallback, and the only layer for
                      languages with no semantic provider (Markdown, shell, SQL,
                      most config formats).

Both token layers are filled in, because a theme that only does semantics goes
grey the moment a file opens outside a project, and a theme that only does
TextMate throws away the one thing that separates a record from a class.

Usage:  python gen-vscode.py [outdir]
"""
import json
import os
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "scripts"))

from focuspalette import PALETTES, alpha, derive_extended  # noqa: E402

OUTDIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "themes")

# ---------------------------------------------------------------------------
# Workbench
# ---------------------------------------------------------------------------
# Each entry maps a VS Code colour key to a role, optionally with an alpha.
# The three surface depths are the design's own: the editor is bg, the tab strip
# and status bar are chrome, and every tool panel is panel - the same split the
# .vstheme makes between EnvironmentBody, EnvironmentTab and ToolWindowBackground,
# so the two editors read as the same theme when they sit side by side.
WORKBENCH = [
    # --- editor surface ---
    ("editor.background", "bg"),
    ("editor.foreground", "text"),
    ("editorLineNumber.foreground", "muted"),
    ("editorLineNumber.activeForeground", "text"),
    ("editorCursor.foreground", "caret"),
    ("editor.selectionBackground", "sel"),
    ("editor.inactiveSelectionBackground", "isel"),
    ("editor.selectionHighlightBackground", "isel"),
    ("editor.lineHighlightBackground", "currentline"),
    ("editor.findMatchBackground", "findmatch"),
    ("editor.findMatchHighlightBackground", "findmatchOther"),
    ("editor.wordHighlightBackground", "wordhighlight"),
    ("editor.wordHighlightStrongBackground", "wordhighlight"),
    ("editor.rangeHighlightBackground", "isel"),
    ("editorWhitespace.foreground", "border"),
    ("editorIndentGuide.background1", "border"),
    ("editorIndentGuide.activeBackground1", "muted"),
    ("editorRuler.foreground", "border"),
    ("editorBracketMatch.background", "isel"),
    ("editorBracketMatch.border", "accent"),
    ("editorLink.activeForeground", "accent"),
    ("editorCodeLens.foreground", "comment"),
    ("editorInlayHint.background", "raised"),
    ("editorInlayHint.foreground", "comment"),
    ("editorGhostText.foreground", "muted"),
    # Nested brace pairs cycle through the same three hues as the .vstheme, and
    # the keyword hue stays reserved for the unmatched one for the same reason:
    # a warning only reads as a warning if nothing else is already wearing it.
    ("editorBracketHighlight.foreground1", "brace1"),
    ("editorBracketHighlight.foreground2", "brace2"),
    ("editorBracketHighlight.foreground3", "brace3"),
    ("editorBracketHighlight.foreground4", "brace1"),
    ("editorBracketHighlight.foreground5", "brace2"),
    ("editorBracketHighlight.foreground6", "brace3"),
    ("editorBracketHighlight.unexpectedBracket.foreground", "keyword"),
    # --- diagnostics ---
    ("editorError.foreground", "error"),
    ("editorWarning.foreground", "warning"),
    ("editorInfo.foreground", "info"),
    ("editorHint.foreground", "hint"),
    ("problemsErrorIcon.foreground", "error"),
    ("problemsWarningIcon.foreground", "warning"),
    ("problemsInfoIcon.foreground", "info"),
    ("editorOverviewRuler.errorForeground", "error"),
    ("editorOverviewRuler.warningForeground", "warning"),
    ("editorOverviewRuler.infoForeground", "info"),
    ("editorOverviewRuler.border", "border"),
    # --- gutter and diff ---
    ("editorGutter.background", "bg"),
    ("editorGutter.addedBackground", "added"),
    ("editorGutter.deletedBackground", "removed"),
    ("editorGutter.modifiedBackground", "modified"),
    ("diffEditor.insertedTextBackground", ("added", 0.12)),
    ("diffEditor.removedTextBackground", ("removed", 0.12)),
    ("diffEditor.border", "border"),
    ("merge.currentHeaderBackground", ("modified", 0.30)),
    ("merge.incomingHeaderBackground", ("info", 0.30)),
    ("mergeEditor.conflict.unhandledUnfocused.border", "conflict"),
    # --- chrome: title bar, tabs, status bar ---
    ("titleBar.activeBackground", "chrome"),
    ("titleBar.activeForeground", "text"),
    ("titleBar.inactiveBackground", "chrome"),
    ("titleBar.inactiveForeground", "muted"),
    ("titleBar.border", "border"),
    ("editorGroupHeader.tabsBackground", "chrome"),
    ("editorGroupHeader.noTabsBackground", "chrome"),
    ("editorGroup.border", "border"),
    ("tab.activeBackground", "bg"),
    ("tab.activeForeground", "text"),
    ("tab.inactiveBackground", "chrome"),
    ("tab.inactiveForeground", "comment"),
    ("tab.border", "border"),
    ("tab.activeBorderTop", "accent"),
    ("tab.unfocusedActiveBorderTop", "muted"),
    ("tab.activeModifiedBorder", "modified"),
    ("statusBar.background", "chrome"),
    ("statusBar.foreground", "text"),
    ("statusBar.border", "border"),
    ("statusBar.noFolderBackground", "chrome"),
    ("statusBar.debuggingBackground", "accent"),
    ("statusBar.debuggingForeground", "bg"),
    ("statusBarItem.remoteBackground", "accent"),
    ("statusBarItem.remoteForeground", "bg"),
    ("statusBarItem.errorBackground", "error"),
    ("statusBarItem.warningBackground", "warning"),
    # --- panels and sidebar ---
    ("sideBar.background", "panel"),
    ("sideBar.foreground", "text"),
    ("sideBar.border", "border"),
    ("sideBarTitle.foreground", "comment"),
    ("sideBarSectionHeader.background", "chrome"),
    ("sideBarSectionHeader.foreground", "text"),
    ("activityBar.background", "chrome"),
    ("activityBar.foreground", "text"),
    ("activityBar.inactiveForeground", "muted"),
    ("activityBar.border", "border"),
    ("activityBarBadge.background", "accent"),
    ("activityBarBadge.foreground", "bg"),
    ("panel.background", "panel"),
    ("panel.border", "border"),
    ("panelTitle.activeForeground", "text"),
    ("panelTitle.inactiveForeground", "muted"),
    ("panelTitle.activeBorder", "accent"),
    ("badge.background", "accent"),
    ("badge.foreground", "bg"),
    ("progressBar.background", "accent"),
    # --- lists and trees ---
    ("list.activeSelectionBackground", "sel"),
    ("list.activeSelectionForeground", "text"),
    ("list.inactiveSelectionBackground", "isel"),
    ("list.hoverBackground", "raised"),
    ("list.highlightForeground", "accent"),
    ("list.errorForeground", "error"),
    ("list.warningForeground", "warning"),
    ("tree.indentGuidesStroke", "border"),
    # --- git decorations ---
    ("gitDecoration.addedResourceForeground", "added"),
    ("gitDecoration.deletedResourceForeground", "removed"),
    ("gitDecoration.modifiedResourceForeground", "modified"),
    ("gitDecoration.untrackedResourceForeground", "added"),
    ("gitDecoration.ignoredResourceForeground", "ignored"),
    ("gitDecoration.conflictingResourceForeground", "conflict"),
    # --- overlays: dropdowns, hovers, command palette ---
    ("dropdown.background", "overlay"),
    ("dropdown.foreground", "text"),
    ("dropdown.border", "border"),
    ("input.background", "overlay"),
    ("input.foreground", "text"),
    ("input.border", "border"),
    ("input.placeholderForeground", "muted"),
    ("inputOption.activeBorder", "accent"),
    ("inputValidation.errorBackground", "overlay"),
    ("inputValidation.errorBorder", "error"),
    ("editorWidget.background", "overlay"),
    ("editorWidget.border", "border"),
    ("editorHoverWidget.background", "overlay"),
    ("editorHoverWidget.border", "border"),
    ("editorSuggestWidget.background", "overlay"),
    ("editorSuggestWidget.border", "border"),
    ("editorSuggestWidget.selectedBackground", "sel"),
    ("editorSuggestWidget.highlightForeground", "accent"),
    ("quickInput.background", "overlay"),
    ("quickInput.foreground", "text"),
    ("quickInputList.focusBackground", "sel"),
    ("peekViewEditor.background", "panel"),
    ("peekViewResult.background", "panel"),
    ("peekView.border", "accent"),
    ("menu.background", "overlay"),
    ("menu.foreground", "text"),
    ("menu.selectionBackground", "sel"),
    ("notifications.background", "overlay"),
    ("notifications.border", "border"),
    ("notificationsErrorIcon.foreground", "error"),
    ("notificationsWarningIcon.foreground", "warning"),
    ("notificationsInfoIcon.foreground", "info"),
    ("widget.shadow", "shadow"),
    ("scrollbarSlider.background", ("text", 0.10)),
    ("scrollbarSlider.hoverBackground", ("text", 0.18)),
    ("scrollbarSlider.activeBackground", ("text", 0.26)),
    ("minimapSlider.background", ("text", 0.08)),
    # --- buttons and links ---
    ("button.background", "accent"),
    ("button.foreground", "bg"),
    ("button.secondaryBackground", "raised"),
    ("button.secondaryForeground", "text"),
    ("textLink.foreground", "class"),
    ("textLink.activeForeground", "accent"),
    ("focusBorder", "accent"),
    ("foreground", "text"),
    ("errorForeground", "error"),
    ("descriptionForeground", "comment"),
    ("icon.foreground", "text"),
    ("contrastBorder", "border"),
    # --- terminal ---
    ("terminal.background", "bg"),
    ("terminal.foreground", "text"),
    ("terminalCursor.foreground", "caret"),
    ("terminal.selectionBackground", "sel"),
    ("terminal.border", "border"),
]

# ---------------------------------------------------------------------------
# Semantic tokens
# ---------------------------------------------------------------------------
# The layer that makes these themes worth installing. A TextMate grammar can see
# that `Money` is capitalised; only the language server knows it is a struct.
# The five C# type kinds the design separates are reachable here and nowhere else.
#
# Entries are (selector, role, fontStyle). A selector may be a plain token type
# ("class"), a type with a modifier ("variable.readonly"), or a modifier alone
# ("*.declaration"). Emphasis mirrors FocusEmphasis.cs so the three platforms
# agree: interfaces italic, methods and control flow bold, comments upright.
# Comments carry
# their own hue and sit well below AA on purpose; slanting them as well made
# commentary the most visually distinct thing on screen rather than the least.
SEMANTIC = [
    # Types. Each of the five C# kinds keeps its own hue.
    ("class", "class", None),
    ("interface", "interface", "italic"),
    ("struct", "struct", None),
    ("enum", "enum", None),
    ("enumMember", "variable", None),
    ("type", "class", None),
    ("typeParameter", "class", "italic"),
    ("namespace", "punct", None),
    ("*.defaultLibrary", "class", None),
    # Methods.
    ("function", "method", "bold"),
    ("method", "method", "bold"),
    ("macro", "method", None),
    ("decorator", "method", None),
    ("event", "property", None),
    # Names.
    ("variable", "variable", None),
    ("parameter", "variable", None),
    ("property", "property", None),
    ("field", "property", None),
    ("variable.readonly", "constant", None),
    ("variable.constant", "constant", None),
    # Syntax.
    ("keyword", "keyword", None),
    ("keyword.controlFlow", "keyword", "bold"),
    ("modifier", "keyword", None),
    ("operator", "operator", None),
    ("string", "string", None),
    ("number", "number", None),
    ("regexp", "regex_text", None),
    ("comment", "comment", None),
    ("label", "keyword", None),
    # Markup.
    ("selfKeyword", "keyword", "italic"),
    ("*.deprecated", "muted", "strikethrough"),
]

# ---------------------------------------------------------------------------
# TextMate scopes
# ---------------------------------------------------------------------------
# The fallback, and the whole story for languages with no semantic provider.
# Ordered coarse to fine: VS Code applies the last matching rule, so a specific
# scope further down overrides a general one above it.
#
# Roles are the design's, unchanged. Where a language has a concept the C#
# taxonomy does not name, it lands on the nearest role rather than a new hue -
# a Rust trait is an interface, a Go struct is a struct, a Python decorator is a
# method call, and a Markdown heading is a declaration, so it takes the class hue.
TOKENS = [
    ("Comment", ["comment", "punctuation.definition.comment"], "comment", None),
    ("Documentation comment", ["comment.block.documentation"], "comment", None),
    ("Punctuation", [
        "punctuation",
        "punctuation.separator",
        "punctuation.terminator",
        "punctuation.accessor",
        "meta.brace",
    ], "punct", None),
    ("Plain text", ["source", "text"], "text", None),
    # --- keywords ---
    ("Keyword", [
        "keyword",
        "storage",
        "storage.type",
        "storage.modifier",
        "keyword.other",
    ], "keyword", None),
    ("Control flow", [
        "keyword.control",
        "keyword.control.flow",
        "keyword.control.conditional",
        "keyword.control.loop",
        "keyword.control.trycatch",
        "keyword.control.exception",
        "keyword.control.return",
    ], "keyword", "bold"),
    ("Import and export", [
        "keyword.control.import",
        "keyword.control.export",
        "keyword.control.from",
        "meta.import keyword",
    ], "keyword", None),
    ("Preprocessor", [
        "meta.preprocessor",
        "keyword.control.directive",
        "entity.name.function.preprocessor",
    ], "keyword", None),
    ("Operator", [
        "keyword.operator",
        "keyword.operator.assignment",
        "keyword.operator.arithmetic",
        "keyword.operator.logical",
        "keyword.operator.comparison",
        "keyword.operator.relational",
        "keyword.operator.ternary",
        "keyword.operator.spread",
        "keyword.operator.type.annotation",
    ], "operator", None),
    # --- literals ---
    ("String", [
        "string",
        "string.quoted",
        "punctuation.definition.string",
        "string.template",
    ], "string", None),
    ("String interpolation", [
        "meta.template.expression",
        "meta.embedded.line",
        "punctuation.definition.template-expression",
    ], "text", None),
    ("Escape sequence", [
        "constant.character.escape",
        "constant.other.placeholder",
        "constant.other.character-class.escape",
    ], "constant", None),
    ("Number", [
        "constant.numeric",
        "constant.numeric.integer",
        "constant.numeric.float",
    ], "number", None),
    ("Language constant", [
        "constant.language",
        "constant.language.boolean",
        "constant.language.null",
        "constant.other",
        "variable.other.constant",
        "support.constant",
    ], "constant", None),
    # --- regular expressions ---
    # Roslyn's nine regex classifications, spoken in TextMate. Same sub-family:
    # the pattern text sits below the string hue so the metacharacters pop.
    ("Regex text", ["string.regexp"], "regex_text", None),
    ("Regex group", [
        "punctuation.definition.group.regexp",
        "meta.group.regexp",
    ], "regex_group", None),
    ("Regex quantifier and alternation", [
        "keyword.operator.quantifier.regexp",
        "keyword.operator.or.regexp",
    ], "keyword", None),
    ("Regex anchor", ["keyword.control.anchor.regexp"], "method", None),
    ("Regex character class", [
        "constant.other.character-class.regexp",
        "constant.other.character-class.set.regexp",
    ], "enum", None),
    # --- types ---
    ("Type", [
        "entity.name.type",
        "entity.name.class",
        "entity.other.inherited-class",
        "support.class",
        "support.type",
        "entity.name.type.class",
        "entity.name.namespace",
        "entity.name.scope-resolution",
    ], "class", None),
    ("Interface and trait", [
        "entity.name.type.interface",
        "entity.name.type.trait",
        "entity.name.type.protocol",
    ], "interface", "italic"),
    ("Struct", [
        "entity.name.type.struct",
        "entity.name.type.value",
    ], "struct", None),
    ("Enum", [
        "entity.name.type.enum",
        "entity.name.type.enum-name",
    ], "enum", None),
    ("Type parameter", [
        "entity.name.type.parameter",
        "entity.name.type.type-parameter",
        "meta.type.parameters entity.name.type",
    ], "class", "italic"),
    ("Namespace and module", [
        "entity.name.section",
        "entity.name.type.module",
        "entity.name.type.namespace",
        "support.other.namespace",
    ], "punct", None),
    # --- callables ---
    ("Function and method", [
        "entity.name.function",
        "support.function",
        "meta.function-call",
        "meta.function-call.generic",
        "variable.function",
    ], "method", "bold"),
    ("Decorator", [
        "meta.decorator",
        "entity.name.function.decorator",
        "punctuation.decorator",
        "meta.attribute",
        "entity.name.function.attribute",
    ], "method", "italic"),
    # --- names ---
    ("Variable", [
        "variable",
        "variable.other",
        "variable.other.readwrite",
        "meta.definition.variable.name",
    ], "variable", None),
    ("Parameter", [
        "variable.parameter",
        "meta.parameter",
    ], "variable", None),
    ("Property", [
        "variable.other.property",
        "variable.other.object.property",
        "meta.object-literal.key",
        "support.variable.property",
    ], "property", None),
    ("Language variable", [
        "variable.language",
        "variable.language.this",
        "variable.language.self",
        "keyword.other.this",
    ], "keyword", "italic"),
    ("Invalid", ["invalid", "invalid.illegal"], "error", None),
    ("Deprecated", ["invalid.deprecated"], "muted", "strikethrough"),
    # --- markup: HTML, XML, XAML, JSX ---
    ("Tag name", [
        "entity.name.tag",
        "support.class.component",
    ], "tag", None),
    ("Tag delimiter", [
        "punctuation.definition.tag",
        "punctuation.definition.tag.begin",
        "punctuation.definition.tag.end",
    ], "punct", None),
    ("Attribute name", [
        "entity.other.attribute-name",
        "meta.attribute.class",
        "meta.attribute.id",
    ], "variable", None),
    ("Attribute value", [
        "meta.attribute string",
        "string.quoted.double.html",
        "string.quoted.single.html",
    ], "string", None),
    ("Entity reference", ["constant.character.entity"], "constant", None),
    # --- CSS and SCSS ---
    ("CSS selector", [
        "entity.name.tag.css",
        "entity.other.attribute-name.class.css",
        "entity.other.attribute-name.id.css",
        "entity.other.attribute-name.pseudo-class.css",
        "entity.other.attribute-name.pseudo-element.css",
    ], "class", None),
    ("CSS property", [
        "support.type.property-name.css",
        "support.type.property-name.scss",
        "meta.property-name",
    ], "variable", None),
    ("CSS value", [
        "support.constant.property-value",
        "meta.property-value",
        "support.constant.font-name",
    ], "text", None),
    ("CSS unit", [
        "keyword.other.unit",
        "constant.numeric.css",
    ], "number", None),
    ("CSS at-rule", ["keyword.control.at-rule", "punctuation.definition.keyword.css"],
     "keyword", None),
    # --- JSON, YAML, TOML, INI ---
    ("Key", [
        "support.type.property-name.json",
        "support.type.property-name.toml",
        "entity.name.tag.yaml",
        "keyword.key",
    ], "variable", None),
    ("Table header", [
        "entity.name.section.toml",
        "entity.name.tag.ini",
    ], "class", "bold"),
    ("YAML anchor and alias", [
        "entity.name.type.anchor.yaml",
        "variable.other.alias.yaml",
    ], "constant", None),
    # --- Markdown ---
    ("Markdown heading", [
        "markup.heading",
        "entity.name.section.markdown",
        "punctuation.definition.heading.markdown",
    ], "class", "bold"),
    ("Markdown bold", ["markup.bold"], "text", "bold"),
    ("Markdown italic", ["markup.italic"], "text", "italic"),
    ("Markdown strikethrough", ["markup.strikethrough"], "muted", "strikethrough"),
    ("Markdown link", [
        "markup.underline.link",
        "string.other.link",
        "constant.other.reference.link",
    ], "method", None),
    ("Markdown link text", ["string.other.link.title", "meta.link"], "class", None),
    ("Markdown code", [
        "markup.inline.raw",
        "markup.fenced_code",
        "markup.raw",
    ], "string", None),
    ("Markdown quote", ["markup.quote"], "comment", "italic"),
    ("Markdown list marker", [
        "punctuation.definition.list.begin.markdown",
        "beginning.punctuation.definition.list.markdown",
    ], "keyword", None),
    ("Markdown inserted", ["markup.inserted"], "added", None),
    ("Markdown deleted", ["markup.deleted"], "removed", None),
    ("Markdown changed", ["markup.changed"], "modified", None),
    # --- shell ---
    ("Shell variable", [
        "variable.other.normal.shell",
        "punctuation.definition.variable.shell",
        "string.interpolated.dollar.shell",
    ], "variable", None),
    ("Shell builtin", [
        "support.function.builtin.shell",
        "keyword.other.shell",
    ], "method", None),
    # --- SQL ---
    ("SQL keyword", [
        "keyword.other.DML.sql",
        "keyword.other.DDL.sql",
        "keyword.other.sql",
    ], "keyword", "bold"),
    ("SQL function", ["support.function.aggregate.sql", "support.function.sql"],
     "method", None),
    # --- Go, Rust, Java, Kotlin specifics that the general rules miss ---
    ("Go package", ["entity.name.package.go", "entity.name.import.go"], "punct", None),
    ("Rust lifetime", [
        "storage.modifier.lifetime.rust",
        "entity.name.type.lifetime.rust",
        "punctuation.definition.lifetime.rust",
    ], "constant", "italic"),
    ("Rust macro", ["entity.name.function.macro.rust", "support.function.macro.rust"],
     "method", None),
    ("Java annotation", [
        "storage.type.annotation.java",
        "punctuation.definition.annotation.java",
    ], "method", "italic"),
    ("Kotlin label", ["entity.name.label.kotlin"], "keyword", None),
    # --- Python specifics ---
    # PyCharm is one of the four targets, so Python gets first-class treatment
    # rather than riding on the generic rules alone.
    ("Python builtin type", [
        "support.type.python",
        "support.class.python",
    ], "class", None),
    ("Python builtin function", [
        "support.function.builtin.python",
        "support.function.magic.python",
    ], "method", None),
    ("Python self", [
        "variable.parameter.function.language.special.self.python",
        "variable.language.special.self.python",
    ], "keyword", "italic"),
    ("Python f-string", [
        "meta.fstring.python",
        "string.interpolated.python",
    ], "string", None),
    ("Python docstring", [
        "string.quoted.docstring.python",
        "comment.block.documentation.python",
    ], "comment", None),
    ("Python type hint", [
        "meta.function.parameters support.type",
        "meta.function.return-type",
    ], "class", None),
    # --- C# specifics that TextMate can reach ---
    # These are the fallback for a C# file the language server has not analysed
    # yet. Once OmniSharp or Roslyn reports, semanticTokenColors takes over and
    # the five type kinds separate properly.
    ("C# verbatim string", ["string.quoted.double.literal.cs"], "string", None),
    ("C# XML doc", [
        "comment.block.documentation.cs",
        "comment.block.documentation.tag.cs",
    ], "comment", None),
]

# ---------------------------------------------------------------------------
# Emission
# ---------------------------------------------------------------------------


def colour(d, spec):
    """A role name, or a (role, alpha) pair, resolved to a VS Code hex string."""
    if isinstance(spec, tuple):
        role, a = spec
        return alpha(d[role], a)
    return "#" + d[spec]


def workbench(d):
    return {key: colour(d, spec) for key, spec in WORKBENCH}


def terminal(d):
    out = {}
    for name in ("Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"):
        out["terminal.ansi" + name] = "#" + d["ansi" + name]
        out["terminal.ansiBright" + name] = "#" + d["ansiBright" + name]
    return out


def semantic(d):
    out = {}
    for selector, role, style in SEMANTIC:
        entry = {"foreground": "#" + d[role]}
        if style:
            entry["fontStyle"] = style
        out[selector] = entry
    return out


def tokens(d):
    out = []
    for name, scopes, role, style in TOKENS:
        settings = {"foreground": "#" + d[role]}
        if style:
            settings["fontStyle"] = style
        out.append({"name": name, "scope": scopes, "settings": settings})
    return out


def theme(p):
    d = derive_extended(p)
    colors = workbench(d)
    colors.update(terminal(d))
    return {
        "$schema": "vscode://schemas/color-theme",
        "name": p["name"],
        "type": "dark",
        "semanticHighlighting": True,
        "colors": colors,
        "semanticTokenColors": semantic(d),
        "tokenColors": tokens(d),
    }


def slug(p):
    return p["file"].replace(".vstheme", "-color-theme.json")


def sync_manifest():
    """Rewrite contributes.themes from PALETTES.

    The manifest has to name all six themes, which would be a second list of
    palette names drifting away from the first. It is generated instead, and the
    rest of package.json is left exactly as written.
    """
    path = os.path.join(os.path.dirname(OUTDIR), "package.json")
    if not os.path.isfile(path):
        return
    with open(path, encoding="utf-8") as fh:
        manifest = json.load(fh)
    manifest.setdefault("contributes", {})["themes"] = [
        {
            "label": p["name"],
            "uiTheme": "vs-dark",
            "path": "./themes/" + slug(p),
        }
        for p in PALETTES
    ]
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(manifest, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    print("synced %s" % path)


README = """# Focus Themes

Six high-separation dark themes for Visual Studio Code and Cursor, designed for
fast scanning. Each gives every kind of type a color of its own - class,
interface, record, struct, and enum are five different hues, not five shades of
one - so the shape of a file reads before you read a word of it.

The same six palettes ship for Visual Studio, Rider, and PyCharm. They are
generated from one table, so a theme is the same theme in every editor.

## The six

%s

## What is themed

- **Semantic tokens** where the language server provides them: C#, TypeScript,
  JavaScript, Python, Rust, Go, Java. This is the layer that separates a record
  from a class, and no TextMate grammar can do it.
- **TextMate scopes** for everything else, and as the fallback before the
  language server reports: HTML, CSS/SCSS, JSON, YAML, TOML, Markdown, SQL,
  shell, Kotlin.
- **The workbench**: editor, tabs, sidebar, status bar, diffs, git decorations,
  and all sixteen terminal ANSI slots.

Comments and interfaces are italic; control flow is bold. That matches the
Visual Studio build, where the same emphasis comes from a MEF component.

## Accessibility

Every syntax hue clears WCAG AA (4.5:1) against its own background. Comments,
the gutter, and regex pattern text are held to 3:1 instead - deliberately, so
commentary recedes rather than competing with code.

## License

MIT
"""


def readme():
    """One entry per palette, from the description the palette already carries."""
    lines = []
    for p in PALETTES:
        desc = " ".join(p["desc"].split())
        lines.append("### %s\n\n%s\n" % (p["name"], desc))
    path = os.path.join(os.path.dirname(OUTDIR), "README.md")
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(README % "\n".join(lines))
    print("wrote %s" % path)


def main():
    if not os.path.isdir(OUTDIR):
        os.makedirs(OUTDIR)
    for p in PALETTES:
        path = os.path.join(OUTDIR, slug(p))
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(theme(p), fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        print("wrote %s" % path)
    sync_manifest()
    readme()
    print("done: %d theme(s)" % len(PALETTES))
    return 0


if __name__ == "__main__":
    sys.exit(main())
