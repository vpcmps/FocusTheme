"""Generate every Focus JetBrains colour scheme from the shared palette.

Two artefacts, because the JetBrains IDEs split what VS Code keeps together:

  schemes/*.icls        the editor. Importable on its own through
                        Settings > Editor > Color Scheme > Import Scheme, so it
                        works in Rider and PyCharm with no plugin and no build.
  plugin/.../*.theme.json  the IDE frame - tool windows, tabs, the status bar.
                        Only a plugin can supply this, and it points back at the
                        .icls above rather than restating any colour.

An .icls silently ignores an attribute key it does not know, so a scheme may name
keys for languages the running IDE has never heard of. That is what makes one
file work in both Rider and PyCharm: Rider drops the PY.* block, PyCharm drops
the ReSharper.* block, and each paints what it has. Omission is the failure mode
here, not over-inclusion.

Usage:  python gen-jetbrains.py [outdir]
"""
import json
import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "scripts"))

from focuspalette import PALETTES, derive_extended  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "schemes")
PLUGIN_THEMES = os.path.join(HERE, "plugin", "src", "main", "resources", "themes")

# JetBrains writes colours as bare lowercase hex, no hash. FONT_TYPE is a
# bitfield: 1 bold, 2 italic, 3 both.
FONT = {None: None, "bold": "1", "italic": "2", "bold italic": "3"}

# ---------------------------------------------------------------------------
# <colors> - the editor surface
# ---------------------------------------------------------------------------
COLORS = [
    ("CARET_COLOR", "caret"),
    ("CARET_ROW_COLOR", "currentline"),
    ("SELECTION_BACKGROUND", "sel"),
    ("SELECTION_FOREGROUND", "text"),
    ("GUTTER_BACKGROUND", "bg"),
    ("LINE_NUMBERS_COLOR", "muted"),
    ("LINE_NUMBER_ON_CARET_ROW_COLOR", "text"),
    ("INDENT_GUIDE", "border"),
    ("SELECTED_INDENT_GUIDE", "muted"),
    ("RIGHT_MARGIN_COLOR", "border"),
    ("WHITESPACES", "border"),
    ("TEARLINE_COLOR", "border"),
    ("SELECTED_TEARLINE_COLOR", "muted"),
    ("METHOD_SEPARATORS_COLOR", "border"),
    ("FOLDED_TEXT_BORDER_COLOR", "raised"),
    ("NOTIFICATION_BACKGROUND", "overlay"),
    ("DOCUMENTATION_COLOR", "panel"),
    ("CONSOLE_BACKGROUND_KEY", "bg"),
    ("ANNOTATIONS_COLOR", "comment"),
    ("ERROR_HINT", "error"),
    # Version control gutter marks. Same roles as the VS Code gutter, so a diff
    # reads the same in both.
    ("ADDED_LINES_COLOR", "added"),
    ("MODIFIED_LINES_COLOR", "modified"),
    ("DELETED_LINES_COLOR", "removed"),
    ("IGNORED_ADDED_LINES_BORDER_COLOR", "added"),
    ("IGNORED_MODIFIED_LINES_BORDER_COLOR", "modified"),
    ("IGNORED_DELETED_LINES_BORDER_COLOR", "removed"),
    ("WHITESPACES_MODIFIED_LINES_COLOR", "modified"),
    # The annotate gutter cycles five colours by commit age.
    ("VCS_ANNOTATIONS_COLOR_1", "class"),
    ("VCS_ANNOTATIONS_COLOR_2", "method"),
    ("VCS_ANNOTATIONS_COLOR_3", "string"),
    ("VCS_ANNOTATIONS_COLOR_4", "enum"),
    ("VCS_ANNOTATIONS_COLOR_5", "record"),
    # Terminal and run console.
    ("CONSOLE_BLACK_OUTPUT", "ansiBlack"),
    ("CONSOLE_RED_OUTPUT", "ansiRed"),
    ("CONSOLE_GREEN_OUTPUT", "ansiGreen"),
    ("CONSOLE_YELLOW_OUTPUT", "ansiYellow"),
    ("CONSOLE_BLUE_OUTPUT", "ansiBlue"),
    ("CONSOLE_MAGENTA_OUTPUT", "ansiMagenta"),
    ("CONSOLE_CYAN_OUTPUT", "ansiCyan"),
    ("CONSOLE_GRAY_OUTPUT", "ansiWhite"),
    ("CONSOLE_DARKGRAY_OUTPUT", "ansiBrightBlack"),
    ("CONSOLE_RED_BRIGHT_OUTPUT", "ansiBrightRed"),
    ("CONSOLE_GREEN_BRIGHT_OUTPUT", "ansiBrightGreen"),
    ("CONSOLE_YELLOW_BRIGHT_OUTPUT", "ansiBrightYellow"),
    ("CONSOLE_BLUE_BRIGHT_OUTPUT", "ansiBrightBlue"),
    ("CONSOLE_MAGENTA_BRIGHT_OUTPUT", "ansiBrightMagenta"),
    ("CONSOLE_CYAN_BRIGHT_OUTPUT", "ansiBrightCyan"),
    ("CONSOLE_WHITE_OUTPUT", "ansiBrightWhite"),
]

# ---------------------------------------------------------------------------
# <attributes> - syntax
# ---------------------------------------------------------------------------
# Each entry is (key, foreground role or None, background role or None, style).
# The DEFAULT_* family is the platform's own vocabulary: a language plugin that
# does not define its own key inherits from these, so getting them right covers
# far more languages than the per-language blocks below.
PLATFORM = [
    ("TEXT", "text", "bg", None),
    ("DEFAULT_IDENTIFIER", "variable", None, None),
    ("DEFAULT_KEYWORD", "keyword", None, None),
    ("DEFAULT_OPERATION_SIGN", "operator", None, None),
    ("DEFAULT_SEMICOLON", "punct", None, None),
    ("DEFAULT_COMMA", "punct", None, None),
    ("DEFAULT_DOT", "punct", None, None),
    ("DEFAULT_BRACES", "punct", None, None),
    ("DEFAULT_BRACKETS", "punct", None, None),
    ("DEFAULT_PARENTHS", "punct", None, None),
    # Comments, upright - the same emphasis FocusEmphasis.cs applies in Visual
    # Studio and the VS Code themes apply through fontStyle. The comment hue
    # already puts commentary well below the code around it; adding a slant on
    # top made it the most visually distinct thing on screen rather than the
    # least.
    ("DEFAULT_COMMENT", "comment", None, None),
    ("DEFAULT_LINE_COMMENT", "comment", None, None),
    ("DEFAULT_BLOCK_COMMENT", "comment", None, None),
    ("DEFAULT_DOC_COMMENT", "comment", None, None),
    ("DEFAULT_DOC_COMMENT_TAG", "class", None, None),
    ("DEFAULT_DOC_COMMENT_TAG_VALUE", "string", None, None),
    ("DEFAULT_DOC_MARKUP", "muted", None, None),
    # Literals.
    ("DEFAULT_STRING", "string", None, None),
    ("DEFAULT_NUMBER", "number", None, None),
    ("DEFAULT_CONSTANT", "constant", None, None),
    ("DEFAULT_VALID_STRING_ESCAPE", "constant", None, None),
    ("DEFAULT_INVALID_STRING_ESCAPE", "error", None, None),
    ("DEFAULT_PREDEFINED_SYMBOL", "keyword", None, "italic"),
    # Types. The five kinds the design separates, in the platform's names.
    ("DEFAULT_CLASS_NAME", "class", None, None),
    ("DEFAULT_CLASS_REFERENCE", "class", None, None),
    ("DEFAULT_INTERFACE_NAME", "interface", None, "italic"),
    ("DEFAULT_METADATA", "method", None, "italic"),
    # Callables, bold - the same weight FocusEmphasis.cs gives `method name` in
    # Visual Studio. Decorators, annotations and built-ins stay italic-only:
    # those are metadata about a callable rather than one you declared.
    ("DEFAULT_FUNCTION_DECLARATION", "method", None, "bold"),
    ("DEFAULT_FUNCTION_CALL", "method", None, "bold"),
    ("DEFAULT_INSTANCE_METHOD", "method", None, "bold"),
    ("DEFAULT_STATIC_METHOD", "method", None, "bold"),
    # Names, split two ways. Locals and parameters take `variable`, a
    # desaturated plain text - they are the bulk of what is on a line and should
    # read as text. Members reached through a dot take `property`, a hue of its
    # own, so a field access does not read as a local. Data-format keys
    # (JSON, YAML, CSS, HTML) stay on `variable`: they are not members of a type,
    # and recolouring them would repaint every config file in the project.
    ("DEFAULT_LOCAL_VARIABLE", "variable", None, None),
    ("DEFAULT_PARAMETER", "variable", None, None),
    ("DEFAULT_INSTANCE_FIELD", "property", None, None),
    ("DEFAULT_STATIC_FIELD", "property", None, None),
    ("DEFAULT_GLOBAL_VARIABLE", "variable", None, None),
    ("DEFAULT_REASSIGNED_LOCAL_VARIABLE", "variable", None, None),
    ("DEFAULT_REASSIGNED_PARAMETER", "variable", None, None),
    ("DEFAULT_LABEL", "keyword", None, None),
    # Markup.
    ("DEFAULT_TAG", "tag", None, None),
    ("DEFAULT_ATTRIBUTE", "variable", None, None),
    ("DEFAULT_ENTITY", "constant", None, None),
    ("DEFAULT_TEMPLATE_LANGUAGE_COLOR", "text", "raised", None),
    # Editor feedback rather than code.
    ("BAD_CHARACTER", "error", None, None),
    ("MATCHED_BRACE_ATTRIBUTES", "accent", "isel", "bold"),
    ("UNMATCHED_BRACE_ATTRIBUTES", "keyword", None, "bold"),
    ("IDENTIFIER_UNDER_CARET_ATTRIBUTES", None, "wordhighlight", None),
    ("WRITE_IDENTIFIER_UNDER_CARET_ATTRIBUTES", None, "wordhighlight", None),
    ("TEXT_SEARCH_RESULT_ATTRIBUTES", None, "findmatch", None),
    ("SEARCH_RESULT_ATTRIBUTES", None, "findmatch", None),
    ("HYPERLINK_ATTRIBUTES", "class", None, None),
    ("FOLLOWED_HYPERLINK_ATTRIBUTES", "record", None, None),
    ("DEPRECATED_ATTRIBUTES", "muted", None, None),
    ("INLINE_PARAMETER_HINT", "comment", "raised", None),
    ("INLAY_DEFAULT", "comment", "raised", None),
    ("FOLDED_TEXT_ATTRIBUTES", "comment", "raised", "italic"),
    ("CONSOLE_SYSTEM_OUTPUT", "text", None, None),
    ("CONSOLE_NORMAL_OUTPUT", "text", None, None),
    ("CONSOLE_ERROR_OUTPUT", "error", None, None),
    ("CONSOLE_USER_INPUT", "string", None, "italic"),
    ("LOG_ERROR_OUTPUT", "error", None, None),
    ("LOG_WARNING_OUTPUT", "warning", None, None),
    ("LOG_DEBUG_OUTPUT", "comment", None, None),
    # Inspection severities.
    ("ERRORS_ATTRIBUTES", "error", None, None),
    ("WARNING_ATTRIBUTES", "warning", None, None),
    ("INFO_ATTRIBUTES", "info", None, None),
    ("WEAK_WARNING_ATTRIBUTES", "hint", None, None),
    ("NOT_USED_ELEMENT_ATTRIBUTES", "muted", None, None),
    ("TYPO", "hint", None, None),
    # Diff.
    ("DIFF_INSERTED", None, "added", None),
    ("DIFF_MODIFIED", None, "modified", None),
    ("DIFF_DELETED", None, "removed", None),
    ("DIFF_CONFLICT", None, "conflict", None),
]

# C# in Rider. ReSharper owns C# highlighting there, and its keys are the only
# place the five type kinds can be separated - the platform has one
# DEFAULT_CLASS_NAME for all of them.
CSHARP = [
    ("ReSharper.KEYWORD", "keyword", None, None),
    ("ReSharper.CLASS_IDENTIFIER", "class", None, None),
    ("ReSharper.STRUCT_IDENTIFIER", "struct", None, None),
    ("ReSharper.INTERFACE_IDENTIFIER", "interface", None, "italic"),
    ("ReSharper.ENUM_IDENTIFIER", "enum", None, None),
    ("ReSharper.RECORD_IDENTIFIER", "record", None, None),
    ("ReSharper.RECORD_STRUCT_IDENTIFIER", "record", None, None),
    ("ReSharper.DELEGATE_IDENTIFIER", "class", None, None),
    ("ReSharper.TYPE_PARAMETER_IDENTIFIER", "class", None, "italic"),
    ("ReSharper.NAMESPACE_IDENTIFIER", "punct", None, None),
    ("ReSharper.METHOD_IDENTIFIER", "method", None, "bold"),
    ("ReSharper.EXTENSION_METHOD_IDENTIFIER", "method", None, "bold italic"),
    ("ReSharper.CONSTRUCTOR_IDENTIFIER", "class", None, None),
    ("ReSharper.LOCAL_VARIABLE_IDENTIFIER", "variable", None, None),
    ("ReSharper.PARAMETER_IDENTIFIER", "variable", None, None),
    ("ReSharper.FIELD_IDENTIFIER", "property", None, None),
    ("ReSharper.STATIC_FIELD_IDENTIFIER", "property", None, None),
    ("ReSharper.EVENT_IDENTIFIER", "property", None, None),
    ("ReSharper.CONSTANT_IDENTIFIER", "constant", None, None),
    ("ReSharper.ENUM_MEMBER_IDENTIFIER", "variable", None, None),
    ("ReSharper.LABEL_IDENTIFIER", "keyword", None, None),
    ("ReSharper.OPERATOR_IDENTIFIER", "operator", None, None),
    ("ReSharper.PREPROCESSOR_KEYWORD", "keyword", None, None),
    ("ReSharper.STRING_ESCAPE_CHARACTER_1", "constant", None, None),
    ("ReSharper.STRING_ESCAPE_CHARACTER_2", "constant", None, None),
    # Roslyn's nine regex classifications, in ReSharper's spelling. Same
    # sub-family the .vstheme paints.
    ("ReSharper.REGEXP_TEXT", "regex_text", None, None),
    ("ReSharper.REGEXP_GROUP", "regex_group", None, None),
    ("ReSharper.REGEXP_QUANTIFIER", "keyword", None, None),
    ("ReSharper.REGEXP_ALTERNATION", "keyword", None, None),
    ("ReSharper.REGEXP_ANCHOR", "method", None, None),
    ("ReSharper.REGEXP_CHARACTER_CLASS", "enum", None, None),
    ("ReSharper.REGEXP_ESCAPE_CHARACTER", "struct", None, None),
    ("ReSharper.REGEXP_COMMENT", "comment", None, None),
    # XML doc comments inside C#.
    ("ReSharper.XMLDOC_TAG", "class", None, None),
    ("ReSharper.XMLDOC_ATTRIBUTE_NAME", "class", None, None),
    ("ReSharper.XMLDOC_ATTRIBUTE_VALUE", "string", None, None),
    ("ReSharper.XMLDOC_TEXT", "comment", None, None),
]

# Python. PyCharm is one of the four targets, so this block is as complete as
# the C# one rather than leaning on the DEFAULT_* fallbacks.
PYTHON = [
    ("PY.KEYWORD", "keyword", None, None),
    ("PY.STRING", "string", None, None),
    ("PY.STRING_U", "string", None, None),
    ("PY.STRING_B", "string", None, None),
    ("PY.BYTES", "string", None, None),
    ("PY.FSTRING_FRAGMENT", "text", None, None),
    ("PY.NUMBER", "number", None, None),
    ("PY.LINE_COMMENT", "comment", None, None),
    ("PY.DOC_COMMENT", "comment", None, None),
    ("PY.OPERATION_SIGN", "operator", None, None),
    ("PY.PARENTHS", "punct", None, None),
    ("PY.BRACKETS", "punct", None, None),
    ("PY.BRACES", "punct", None, None),
    ("PY.COMMA", "punct", None, None),
    ("PY.DOT", "punct", None, None),
    # A class definition is a declaration; a builtin type is a type reference.
    ("PY.CLASS_DEFINITION", "class", None, None),
    ("PY.FUNC_DEFINITION", "method", None, "bold"),
    ("PY.NESTED_FUNC_DEFINITION", "method", None, "bold"),
    ("PY.PREDEFINED_DEFINITION", "method", None, "italic"),
    ("PY.PREDEFINED_USAGE", "method", None, "italic"),
    ("PY.BUILTIN_NAME", "class", None, None),
    ("PY.DECORATOR", "method", None, "italic"),
    ("PY.ANNOTATION", "class", None, None),
    ("PY.SELF_PARAMETER", "keyword", None, "italic"),
    ("PY.PARAMETER", "variable", None, None),
    ("PY.KEYWORD_ARGUMENT", "variable", None, None),
    ("PY.VALID_STRING_ESCAPE", "constant", None, None),
    ("PY.INVALID_STRING_ESCAPE", "error", None, None),
]

# The remaining languages. Each block is short on purpose: the DEFAULT_* family
# already covers keywords, strings, numbers and comments for all of them, so only
# what a language names differently is listed here.
OTHER_LANGUAGES = [
    # JavaScript and TypeScript.
    ("JS.KEYWORD", "keyword", None, None),
    ("JS.LOCAL_VARIABLE", "variable", None, None),
    ("JS.PARAMETER", "variable", None, None),
    ("JS.GLOBAL_VARIABLE", "variable", None, None),
    ("JS.GLOBAL_FUNCTION", "method", None, "bold"),
    ("JS.INSTANCE_MEMBER_FUNCTION", "method", None, "bold"),
    ("JS.CLASS", "class", None, None),
    ("JS.REGEXP", "regex_text", None, None),
    ("JS.DECORATOR", "method", None, "italic"),
    ("TS.INTERFACE", "interface", None, "italic"),
    ("TS.TYPE_ALIAS", "class", None, None),
    ("TS.TYPE_PARAMETER", "class", None, "italic"),
    ("TS.TYPE_GUARD", "keyword", None, None),
    # Go.
    ("GO_KEYWORD", "keyword", None, None),
    ("GO_BUILTIN_CONSTANT", "constant", None, None),
    ("GO_BUILTIN_FUNCTION", "method", None, "italic"),
    ("GO_BUILTIN_TYPE_REFERENCE", "class", None, None),
    ("GO_TYPE_REFERENCE", "class", None, None),
    ("GO_STRUCT_EXPORTED_MEMBER", "property", None, None),
    ("GO_STRUCT_LOCAL_MEMBER", "property", None, None),
    ("GO_PACKAGE_EXPORTED_FUNCTION", "method", None, "bold"),
    ("GO_PACKAGE_LOCAL_FUNCTION", "method", None, "bold"),
    # Rust.
    ("org.rust.KEYWORD", "keyword", None, None),
    ("org.rust.STRUCT", "struct", None, None),
    ("org.rust.ENUM", "enum", None, None),
    ("org.rust.TRAIT", "interface", None, "italic"),
    ("org.rust.TYPE_ALIAS", "class", None, None),
    ("org.rust.TYPE_PARAMETER", "class", None, "italic"),
    ("org.rust.FUNCTION", "method", None, "bold"),
    ("org.rust.METHOD", "method", None, "bold"),
    ("org.rust.MACRO", "method", None, None),
    ("org.rust.LIFETIME", "constant", None, "italic"),
    ("org.rust.ATTRIBUTE", "method", None, "italic"),
    # Kotlin.
    ("KOTLIN_KEYWORD", "keyword", None, None),
    ("KOTLIN_CLASS", "class", None, None),
    ("KOTLIN_OBJECT", "class", None, None),
    ("KOTLIN_TRAIT", "interface", None, "italic"),
    ("KOTLIN_ENUM", "enum", None, None),
    ("KOTLIN_TYPE_PARAMETER", "class", None, "italic"),
    ("KOTLIN_FUNCTION_DECLARATION", "method", None, "bold"),
    ("KOTLIN_FUNCTION_CALL", "method", None, "bold"),
    ("KOTLIN_EXTENSION_FUNCTION_CALL", "method", None, "bold italic"),
    ("KOTLIN_ANNOTATION", "method", None, "italic"),
    ("KOTLIN_LABEL", "keyword", None, None),
    ("KOTLIN_SMART_CAST_VALUE", None, "wordhighlight", None),
    # Java.
    ("ANNOTATION_NAME_ATTRIBUTES", "method", None, "italic"),
    ("ANNOTATION_ATTRIBUTE_NAME_ATTRIBUTES", "variable", None, "italic"),
    ("ABSTRACT_CLASS_NAME_ATTRIBUTES", "class", None, "italic"),
    ("ENUM_NAME_ATTRIBUTES", "enum", None, None),
    ("INTERFACE_NAME_ATTRIBUTES", "interface", None, "italic"),
    ("RECORD_NAME_ATTRIBUTES", "record", None, None),
    ("TYPE_PARAMETER_NAME_ATTRIBUTES", "class", None, "italic"),
    # SQL. Keywords bold, which is the convention every SQL scheme uses and the
    # only place these themes add emphasis the other platforms do not.
    ("SQL_KEYWORD", "keyword", None, "bold"),
    ("SQL_TYPE", "class", None, None),
    ("SQL_TABLE", "class", None, None),
    ("SQL_COLUMN", "variable", None, None),
    ("SQL_PROCEDURE", "method", None, "bold"),
    ("SQL_SCHEMA", "punct", None, None),
    # Markdown.
    ("MARKDOWN_HEADER_LEVEL_1", "class", None, "bold"),
    ("MARKDOWN_HEADER_LEVEL_2", "class", None, "bold"),
    ("MARKDOWN_HEADER_LEVEL_3", "class", None, "bold"),
    ("MARKDOWN_HEADER_LEVEL_4", "class", None, "bold"),
    ("MARKDOWN_HEADER_LEVEL_5", "class", None, "bold"),
    ("MARKDOWN_HEADER_LEVEL_6", "class", None, "bold"),
    ("MARKDOWN_BOLD", "text", None, "bold"),
    ("MARKDOWN_ITALIC", "text", None, "italic"),
    ("MARKDOWN_STRIKE_THROUGH", "muted", None, None),
    ("MARKDOWN_CODE_SPAN", "string", None, None),
    ("MARKDOWN_CODE_BLOCK", "string", None, None),
    ("MARKDOWN_BLOCK_QUOTE", "comment", None, "italic"),
    ("MARKDOWN_LINK_DESTINATION", "method", None, None),
    ("MARKDOWN_LINK_TEXT", "class", None, None),
    ("MARKDOWN_LIST_MARKER", "keyword", None, None),
    # YAML, JSON, properties.
    ("YAML_SCALAR_KEY", "variable", None, None),
    ("YAML_SCALAR_VALUE", "string", None, None),
    ("YAML_ANCHOR", "constant", None, None),
    ("JSON.PROPERTY_KEY", "variable", None, None),
    ("JSON.KEYWORD", "constant", None, None),
    ("PROPERTIES.KEY", "variable", None, None),
    ("PROPERTIES.VALUE", "string", None, None),
    # HTML, XML, CSS.
    ("HTML_TAG_NAME", "tag", None, None),
    ("HTML_ATTRIBUTE_NAME", "variable", None, None),
    ("HTML_ATTRIBUTE_VALUE", "string", None, None),
    ("HTML_ENTITY_REFERENCE", "constant", None, None),
    ("XML_TAG_NAME", "tag", None, None),
    ("XML_ATTRIBUTE_NAME", "variable", None, None),
    ("XML_ATTRIBUTE_VALUE", "string", None, None),
    ("CSS.TAG_NAME", "class", None, None),
    ("CSS.CLASS_NAME", "class", None, None),
    ("CSS.IDENT", "class", None, None),
    ("CSS.PROPERTY_NAME", "variable", None, None),
    ("CSS.PROPERTY_VALUE", "text", None, None),
    ("CSS.FUNCTION", "method", None, "bold"),
    ("CSS.URL", "string", None, None),
    ("CSS.IMPORTANT", "keyword", None, "bold"),
    # Shell.
    ("BASH.SHEBANG", "comment", None, None),
    ("BASH.VAR_USE", "variable", None, None),
    ("BASH.VAR_DEF", "variable", None, None),
    ("BASH.EXTERNAL_COMMAND", "method", None, None),
    ("BASH.SUBSHELL_COMMAND", "method", None, None),
]

ATTRIBUTES = PLATFORM + CSHARP + PYTHON + OTHER_LANGUAGES


# ---------------------------------------------------------------------------
# Emission
# ---------------------------------------------------------------------------
def scheme_xml(p):
    d = derive_extended(p)
    root = ET.Element("scheme", {
        "name": p["name"],
        "version": "142",
        # Darcula supplies anything not named here. Every dark scheme in these
        # IDEs does this, the same way every Focus .vstheme falls back to VS Dark.
        "parent_scheme": "Darcula",
    })
    meta = ET.SubElement(root, "metaInfo")
    for key, value in (("originalScheme", p["name"]),
                       ("created", "generated by jetbrains/gen-jetbrains.py")):
        ET.SubElement(meta, "property", {"name": key}).text = value

    colors = ET.SubElement(root, "colors")
    for key, role in COLORS:
        ET.SubElement(colors, "option", {"name": key, "value": d[role].lower()})

    attributes = ET.SubElement(root, "attributes")
    for key, fg, bg, style in ATTRIBUTES:
        option = ET.SubElement(attributes, "option", {"name": key})
        value = ET.SubElement(option, "value")
        if fg:
            ET.SubElement(value, "option",
                          {"name": "FOREGROUND", "value": d[fg].lower()})
        if bg:
            ET.SubElement(value, "option",
                          {"name": "BACKGROUND", "value": d[bg].lower()})
        font = FONT[style]
        if font:
            ET.SubElement(value, "option", {"name": "FONT_TYPE", "value": font})
    return root


def slug(p):
    return p["file"].replace(".vstheme", "")


# The IDE frame. Only the handful of keys that are not already the platform's
# dark defaults; everything else follows `dark: true`.
def theme_json(p):
    d = derive_extended(p)
    return {
        "name": p["name"],
        "dark": True,
        "author": "Vinicius Campos",
        "editorScheme": "/themes/%s.icls" % slug(p),
        "colors": {
            "surface": "#" + d["bg"],
            "chrome": "#" + d["chrome"],
            "panel": "#" + d["panel"],
            "raised": "#" + d["raised"],
            "edge": "#" + d["border"],
            "ink": "#" + d["text"],
            "inkMuted": "#" + d["muted"],
            "accent": "#" + d["accent"],
        },
        "ui": {
            "*": {
                "background": "panel",
                "foreground": "ink",
                "borderColor": "edge",
                "separatorColor": "edge",
                "selectionBackground": "raised",
                "selectionForeground": "ink",
                "selectedForeground": "ink",
                "infoForeground": "inkMuted",
                "disabledForeground": "inkMuted",
                "focusColor": "accent",
                "focusedBorderColor": "accent",
            },
            "Editor": {"background": "surface"},
            "EditorTabs": {
                "background": "chrome",
                "underlinedTabBackground": "surface",
                "underlineColor": "accent",
                "inactiveUnderlineColor": "inkMuted",
                "borderColor": "edge",
            },
            "DefaultTabs": {
                "background": "chrome",
                "underlineColor": "accent",
                "borderColor": "edge",
            },
            "ToolWindow": {
                "Header": {"background": "chrome", "inactiveBackground": "chrome"},
                "Button": {"selectedBackground": "raised"},
            },
            "StatusBar": {"background": "chrome", "borderColor": "edge"},
            "MainToolbar": {"background": "chrome"},
            "TitlePane": {"background": "chrome", "inactiveBackground": "chrome"},
            "Popup": {"background": "raised", "borderColor": "edge"},
            "CompletionPopup": {
                "background": "raised",
                "selectionBackground": "accent",
                "matchForeground": "accent",
            },
            "Button": {
                "default": {
                    "startBackground": "accent",
                    "endBackground": "accent",
                    "foreground": "surface",
                    "focusColor": "accent",
                },
            },
            "Link": {"activeForeground": "accent", "hoverForeground": "accent"},
            "ProgressBar": {"progressColor": "accent", "indeterminateStartColor": "accent"},
            "Tree": {"background": "panel", "rowHeight": 22},
            "ScrollBar": {"thumbColor": "edge", "hoverThumbColor": "inkMuted"},
        },
        "icons": {"ColorPalette": {"Actions.Blue": "#" + d["accent"]}},
    }


# The plugin descriptor has to name all six themes, which would be a second list
# of palette names drifting away from the first. It is generated with them.
PLUGIN_XML = """<idea-plugin>
  <id>com.vpcmps.focus-themes</id>
  <name>Focus Themes</name>
  <vendor email="vpcmps@gmail.com" url="https://github.com/vpcmps/FocusTheme">Vinicius Campos</vendor>

  <description><![CDATA[
    <p>Six high-separation dark themes designed for fast scanning. Each gives
    every kind of type a colour of its own - class, interface, record, struct and
    enum are five different hues, not five shades of one - so the shape of a file
    reads before you read a word of it.</p>
    <p>The same six palettes ship for Visual Studio, VS Code and Cursor. They are
    generated from one table, so a theme is the same theme in every editor.</p>
    <p>Every syntax hue clears WCAG AA against its own background. Comments, the
    gutter and regex pattern text are held to 3:1 instead - deliberately, so
    commentary recedes rather than competing with code.</p>
  ]]></description>

  <depends>com.intellij.modules.platform</depends>

  <extensions defaultExtensionNs="com.intellij">
%s  </extensions>
</idea-plugin>
"""


def plugin_xml():
    entries = "".join(
        '    <themeProvider id="com.vpcmps.focus.%s" path="/themes/%s.theme.json"/>\n'
        % (slug(p).replace("Focus", "").lower(), slug(p))
        for p in PALETTES)
    path = os.path.join(HERE, "plugin", "src", "main", "resources",
                        "META-INF", "plugin.xml")
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(PLUGIN_XML % entries)
    print("wrote %s" % path)


def write_xml(root, path):
    ET.indent(root, space="  ")
    tree = ET.ElementTree(root)
    with open(path, "wb") as fh:
        tree.write(fh, encoding="utf-8", xml_declaration=True)
        fh.write(b"\n")


def main():
    for directory in (OUTDIR, PLUGIN_THEMES):
        if not os.path.isdir(directory):
            os.makedirs(directory)

    for p in PALETTES:
        name = slug(p)
        # The same scheme lands in two places: one for hand import, one bundled
        # in the plugin. Generated twice rather than copied, so neither can go
        # stale without the other.
        for directory in (OUTDIR, PLUGIN_THEMES):
            write_xml(scheme_xml(p), os.path.join(directory, name + ".icls"))
        path = os.path.join(PLUGIN_THEMES, name + ".theme.json")
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(theme_json(p), fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        print("wrote %s.icls (x2) and %s.theme.json" % (name, name))

    plugin_xml()
    print("done: %d scheme(s), %d colour key(s), %d attribute key(s)"
          % (len(PALETTES), len(COLORS), len(ATTRIBUTES)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
