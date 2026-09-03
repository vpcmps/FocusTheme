using System;
using System.Collections.Generic;
using System.ComponentModel.Composition;
using Microsoft.VisualStudio.Text.Classification;
using Microsoft.VisualStudio.Text.Editor;
using Microsoft.VisualStudio.Text.Formatting;
using Microsoft.VisualStudio.Utilities;

namespace FocusThemes
{
    /// <summary>Which font emphasis a classification carries.</summary>
    internal enum Emphasis
    {
        Bold,
        Italic,
        BoldItalic,
        None
    }

    /// <summary>
    /// Font emphasis for the Focus themes.
    /// </summary>
    /// <remarks>
    /// A .vstheme carries colour only — it has no attribute for weight or slant, so emphasis
    /// has to come from the editor's classification format map.
    /// <para>
    /// <b>Why this is applied at runtime rather than exported as a
    /// <see cref="ClassificationFormatDefinition"/>.</b> Versions up to 2.0 exported one such
    /// definition per classification, each setting only <c>IsBold</c>/<c>IsItalic</c> and
    /// deliberately leaving <c>ForegroundColor</c> unset, on the assumption that an unset
    /// property leaves the theme's colour alone. It does not. Any format definition of ours
    /// for a classification displaces the colour the theme supplied for it, and what shows up
    /// instead depends only on <c>UserVisible</c>: <c>false</c> drops to plain text,
    /// <c>true</c> drops to the colour inherited from the base classification. Both are wrong,
    /// and the second is worse — it made records render in the class colour, so a record
    /// silently read as a class.
    /// </para>
    /// <para>
    /// That is why <c>class name</c>, <c>record class name</c> and <c>interface name</c>
    /// rendered as plain text in every Focus theme through 2.0, while <c>struct name</c>,
    /// <c>enum name</c> and <c>method name</c> — which this file never touched — were always
    /// painted correctly. <c>keyword</c> and <c>comment</c> escaped the bug for an unrelated
    /// reason: the themes also spell those names in the legacy "Text Editor Language Service
    /// Items" category, which paints them by another route.
    /// </para>
    /// <para>
    /// Applying emphasis over the already-resolved properties cannot reintroduce that bug.
    /// The foreground comes from whatever the format map currently holds, so the theme owns
    /// the colour by construction rather than by assumption, and re-applying on
    /// <see cref="IClassificationFormatMap.ClassificationFormatMappingChanged"/> keeps that
    /// true across theme and font changes.
    /// </para>
    /// <para>
    /// Emphasis applies under every theme, not just Focus: switching to the built-in Dark
    /// keeps comments italic. The format map is not scoped to one theme.
    /// </para>
    /// <para>
    /// <b>On installing this alongside the discontinued Graphite Theme.</b> That extension is
    /// no longer built from this repository but remains published. Its GraphiteEmphasis sets
    /// the same flags on the same classifications, and applying a flag that is already set is
    /// a no-op here, so either order of the two produces identical rendering.
    /// </para>
    /// <para>
    /// These are defaults. Anything the user has changed in
    /// Tools &gt; Options &gt; Environment &gt; Fonts and Colors wins over them.
    /// </para>
    /// </remarks>
    [Export(typeof(IWpfTextViewCreationListener))]
    [ContentType("text")]
    [TextViewRole(PredefinedTextViewRoles.Document)]
    internal sealed class FocusEmphasis : IWpfTextViewCreationListener
    {
        /// <summary>
        /// The emphasis each classification carries.
        /// </summary>
        /// <remarks>
        /// Italic marks what is borrowed or generic. Bold marks what was declared and is
        /// named at a call site — types and methods alike — so <c>dados.ValidarCpf()</c>
        /// separates the call from the receiver by weight and not only by hue. Control flow
        /// gets both — it is the one thing that changes where the code goes.
        /// <para>
        /// Up to this version bold was reserved for type names, on the argument that
        /// <c>Console.WriteLine(...)</c> puts a class and a method side by side with only a
        /// dot between them and weight should carry that split. Bolding methods gives that
        /// up: class and method are now told apart by hue alone, which the palettes already
        /// separate by a wide margin. What weight says instead is declaration — a name some
        /// type owns, against the locals and punctuation around it.
        /// </para>
        /// <para>
        /// C# has no classification for predefined types: <c>int</c> and <c>string</c> are
        /// plain <c>keyword</c>, exactly like <c>public</c>. Slanting primitives therefore
        /// means slanting every keyword — the trade-off these themes accept.
        /// </para>
        /// <para>
        /// <c>interface name</c> is deliberately italic and not bold: the slant already marks
        /// it as abstract, and stacking bold on top would make interfaces the loudest thing on
        /// screen rather than types in general.
        /// </para>
        /// <para>
        /// <b>Markup keys.</b> A config file is a wall of key/value pairs with no type system
        /// to give it shape, so the one distinction worth drawing is key from value. These get
        /// bold italic rather than bold alone because a key is both declared - like a type
        /// name, which is what bold says here - and structural rather than content, which is
        /// what the slant says. The value keeps the plain weight it already had.
        /// </para>
        /// <para>
        /// The four names are spelled in Title Case because these are editor colour names
        /// rather than Roslyn classifications, which are lowercase. All four were confirmed
        /// by eye in Visual Studio Community 2026 18.9 - an element in .html and .xaml, a key
        /// in .json, an element in .csproj - because nothing here could establish it up front:
        /// <see cref="Apply"/> skips a name the registry does not know without saying so, so a
        /// wrong name looks exactly like a working one.
        /// </para>
        /// <para>
        /// Worth recording, because it reads as a contradiction otherwise: <c>XML Name</c> and
        /// <c>XAML Name</c> take their colour from the legacy "Text Editor Language Service
        /// Items" category - the same other route that paints <c>keyword</c> and
        /// <c>comment</c>, described above - and are still in the classification registry all
        /// the same. Which Fonts and Colors category paints a name says nothing about whether
        /// MEF can reach it. The two are separate lookups, and only the second one matters
        /// here.
        /// </para>
        /// <para>
        /// YAML has no entry at all. Visual Studio 2026 defines no classification for a YAML
        /// key - not in the classification registry and not among the editor's colourable
        /// items - so there is nothing here to emphasise.
        /// </para>
        /// </remarks>
        private static readonly IReadOnlyDictionary<string, Emphasis> Emphases =
            new Dictionary<string, Emphasis>(StringComparer.Ordinal)
            {
                // Borrowed, generic or commentary.
                ["comment"] = Emphasis.None,
                ["xml doc comment - text"] = Emphasis.None,
                ["xml doc comment - delimiter"] = Emphasis.None,
                ["xml doc comment - name"] = Emphasis.None,
                ["parameter name"] = Emphasis.Italic,
                ["interface name"] = Emphasis.Italic,
                ["type parameter name"] = Emphasis.Italic,

                // Every keyword.
                ["keyword"] = Emphasis.Italic,

                // Type names.
                ["class name"] = Emphasis.Bold,
                ["record class name"] = Emphasis.Bold,

                // Callables. An extension method keeps the slant of something borrowed and
                // takes the weight of the call it is.
                ["method name"] = Emphasis.Bold,
                ["extension method name"] = Emphasis.BoldItalic,

                // Things that change where the code goes.
                ["keyword - control"] = Emphasis.BoldItalic,
                ["operator - overloaded"] = Emphasis.Bold,

                // The key half of a key/value document. See the remarks above on why
                // these carry both weight and slant, and which of them the registry can
                // actually reach.
                ["HTML Element Name"] = Emphasis.BoldItalic,
                ["JSON Property Name"] = Emphasis.BoldItalic,
                ["XML Name"] = Emphasis.BoldItalic,
                ["XAML Name"] = Emphasis.BoldItalic,
            };

        [Import]
        internal IClassificationFormatMapService FormatMapService = null!;

        [Import]
        internal IClassificationTypeRegistryService TypeRegistry = null!;

        /// <summary>Format maps already subscribed to, so each is hooked exactly once.</summary>
        private readonly HashSet<IClassificationFormatMap> _subscribed = new HashSet<IClassificationFormatMap>();

        /// <summary>
        /// Guards against re-entry: writing to the map raises the very event that triggers a
        /// re-apply, which would otherwise recurse.
        /// </summary>
        private bool _applying;

        public void TextViewCreated(IWpfTextView textView)
        {
            IClassificationFormatMap formatMap = FormatMapService.GetClassificationFormatMap(textView);

            if (_subscribed.Add(formatMap))
            {
                // A theme or font change rebuilds the map from the theme, dropping the
                // emphasis. Re-applying then reads the new colours and keeps them.
                formatMap.ClassificationFormatMappingChanged += (_, __) => Apply(formatMap);
            }

            Apply(formatMap);
        }

        private void Apply(IClassificationFormatMap formatMap)
        {
            if (_applying)
            {
                return;
            }

            _applying = true;
            try
            {
                formatMap.BeginBatchUpdate();

                foreach (KeyValuePair<string, Emphasis> entry in Emphases)
                {
                    IClassificationType? classification = TypeRegistry.GetClassificationType(entry.Key);
                    if (classification is null)
                    {
                        // A classification this Visual Studio does not define. Nothing to
                        // emphasise, and nothing to report: the themes target several versions
                        // and not every one of them knows every name.
                        continue;
                    }

                    TextFormattingRunProperties current = formatMap.GetTextProperties(classification);
                    TextFormattingRunProperties emphasised = Emphasise(current, entry.Value);

                    if (!ReferenceEquals(current, emphasised))
                    {
                        formatMap.SetTextProperties(classification, emphasised);
                    }
                }
            }
            finally
            {
                formatMap.EndBatchUpdate();
                _applying = false;
            }
        }

        /// <summary>
        /// Adds the emphasis to <paramref name="properties"/>, returning the same instance
        /// when it already carries it so an unchanged classification is never written back.
        /// </summary>
        /// <remarks>
        /// Only weight and slant are touched. Every other property — the foreground the theme
        /// resolved above all — is carried through untouched.
        /// </remarks>
        private static TextFormattingRunProperties Emphasise(TextFormattingRunProperties properties, Emphasis emphasis)
        {
            bool wantsBold = emphasis == Emphasis.Bold || emphasis == Emphasis.BoldItalic;
            bool wantsItalic = emphasis == Emphasis.Italic || emphasis == Emphasis.BoldItalic;

            TextFormattingRunProperties result = properties;

            if (wantsBold && (result.BoldEmpty || !result.Bold))
            {
                result = result.SetBold(true);
            }

            if (wantsItalic && (result.ItalicEmpty || !result.Italic))
            {
                result = result.SetItalic(true);
            }

            return result;
        }
    }
}
