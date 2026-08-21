using System.ComponentModel.Composition;
using Microsoft.VisualStudio.Text.Classification;
using Microsoft.VisualStudio.Utilities;

namespace FocusThemes
{
    /// <summary>
    /// Font emphasis for the Focus themes.
    /// </summary>
    /// <remarks>
    /// A .vstheme carries colour only — it has no attribute for weight or slant.
    /// Emphasis in the VS editor comes from <see cref="ClassificationFormatDefinition"/>,
    /// so it lives here instead of in the theme files.
    /// <para>
    /// Every definition below sets <c>IsBold</c>/<c>IsItalic</c> and deliberately
    /// leaves <c>ForegroundColor</c> unset, so the active theme still owns the colour.
    /// That also means the emphasis applies under every theme, not just Focus:
    /// switching to the built-in Dark keeps comments italic. MEF format definitions
    /// are static metadata and cannot be scoped to one theme.
    /// </para>
    /// <para>
    /// <b>On installing this alongside GraphiteTheme.</b> GraphiteEmphasis exports the
    /// same set of classification types at the same <see cref="Priority.High"/> order,
    /// so with both extensions installed two exports compete for each classification and
    /// MEF does not define which one wins. It does not matter in practice: both set the
    /// same flags to the same values and neither touches <c>ForegroundColor</c>, so
    /// either resolution order produces identical rendering. The <c>Focus.*</c> names
    /// below only need to be distinct from the <c>Graphite.*</c> ones so that the two
    /// parts do not collide by name.
    /// </para>
    /// <para>
    /// These are defaults. Anything the user has changed in
    /// Tools > Options > Environment > Fonts and Colors wins over them.
    /// </para>
    /// </remarks>
    internal static class FocusEmphasis
    {
        /// <summary>Runs after the default formats so these values are the ones that stick.</summary>
        private const string AfterDefaults = Priority.High;

        // ---- Italic: things that are borrowed, generic, or commentary ----

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "comment")]
        [Name("Focus.Comment")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class Comment : ClassificationFormatDefinition
        {
            public Comment() => IsItalic = true;
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "xml doc comment - text")]
        [Name("Focus.XmlDocText")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class XmlDocText : ClassificationFormatDefinition
        {
            public XmlDocText() => IsItalic = true;
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "xml doc comment - delimiter")]
        [Name("Focus.XmlDocDelimiter")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class XmlDocDelimiter : ClassificationFormatDefinition
        {
            public XmlDocDelimiter() => IsItalic = true;
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "xml doc comment - name")]
        [Name("Focus.XmlDocName")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class XmlDocName : ClassificationFormatDefinition
        {
            public XmlDocName() => IsItalic = true;
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "parameter name")]
        [Name("Focus.ParameterName")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class ParameterName : ClassificationFormatDefinition
        {
            public ParameterName() => IsItalic = true;
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "interface name")]
        [Name("Focus.InterfaceName")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class InterfaceName : ClassificationFormatDefinition
        {
            public InterfaceName() => IsItalic = true;
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "type parameter name")]
        [Name("Focus.TypeParameterName")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class TypeParameterName : ClassificationFormatDefinition
        {
            public TypeParameterName() => IsItalic = true;
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "extension method name")]
        [Name("Focus.ExtensionMethodName")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class ExtensionMethodName : ClassificationFormatDefinition
        {
            public ExtensionMethodName() => IsItalic = true;
        }

        // ---- Italic: every keyword ----
        // C# has no classification for predefined types: `int` and `string` are plain
        // `keyword`, exactly like `public` and `class`. Slanting primitives therefore
        // means slanting every keyword — the trade-off these themes accept.

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "keyword")]
        [Name("Focus.Keyword")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class Keyword : ClassificationFormatDefinition
        {
            public Keyword() => IsItalic = true;
        }

        // ---- Bold: type names, so a class reads apart from a method at a call site ----
        // `Console.WriteLine(...)` puts a class and a method side by side with only a dot
        // between them. Hue alone has to carry that split, and it stops carrying it the
        // moment Roslyn has no semantics and both fall back to the same colour. Weight is
        // a second, independent channel, so the distinction survives that.
        //
        // `interface name` is deliberately not here: it is already italic to mark it as
        // abstract, and stacking bold on top would make interfaces the loudest thing on
        // screen rather than types in general.

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "class name")]
        [Name("Focus.ClassName")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class ClassName : ClassificationFormatDefinition
        {
            public ClassName() => IsBold = true;
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "record class name")]
        [Name("Focus.RecordClassName")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class RecordClassName : ClassificationFormatDefinition
        {
            public RecordClassName() => IsBold = true;
        }

        // ---- Bold: things that change where the code goes ----

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "keyword - control")]
        [Name("Focus.ControlKeyword")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class ControlKeyword : ClassificationFormatDefinition
        {
            // Italic is stated rather than inherited: "keyword - control" derives from
            // "keyword", so it would pick the slant up anyway, but relying on that would
            // make the result depend on Roslyn's classification hierarchy.
            public ControlKeyword()
            {
                IsBold = true;
                IsItalic = true;
            }
        }

        [Export(typeof(EditorFormatDefinition))]
        [ClassificationType(ClassificationTypeNames = "operator - overloaded")]
        [Name("Focus.OverloadedOperator")]
        [UserVisible(false)]
        [Order(After = AfterDefaults)]
        internal sealed class OverloadedOperator : ClassificationFormatDefinition
        {
            public OverloadedOperator() => IsBold = true;
        }
    }
}
