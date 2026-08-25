#define THEME_SAMPLE

using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;

// Lets `record` and `init` compile on net472. Not part of the sample's point.
namespace System.Runtime.CompilerServices
{
    internal static class IsExternalInit { }
}

namespace Sample.Tokens
{
    /// <summary>
    /// Every token class the Focus themes paint, in one file.
    /// </summary>
    /// <remarks>
    /// Open this with a theme applied and read down: each region below is one
    /// group of classifications. If a group is not colour-separated from its
    /// neighbours, that is the palette failing its own first rule.
    /// <para>The XML doc tags around this text are their own classifications:
    /// <c>delimiter</c> for the angle brackets, <c>name</c> for the tag, and
    /// <c>text</c> for what you are reading.</para>
    /// <![CDATA[ CDATA sections get their own colour too: <not/> markup. ]]>
    /// </remarks>
    /// <typeparam name="T">A type parameter name.</typeparam>
    public sealed class AllTokens<T> : ITokenSample, IDisposable
        where T : class, new()
    {
        #region Fields, constants and events

        // A plain line comment.

        /* A block comment,
           spanning two lines. */

        private readonly List<string> _backing = new List<string>();
        private int _counter;
        private static T _cached;

        /// <summary>A constant name — distinct from a plain field.</summary>
        public const int MaxAccents = 31;

        private const string DefaultLabel = "focus";

        /// <summary>An event name.</summary>
        public event EventHandler<TokenEventArgs> Changed;

        #endregion

        #region Properties and indexers

        /// <summary>A property name.</summary>
        public string Label { get; init; } = DefaultLabel;

        public int Count => _backing.Count;

        public string this[int index] => _backing[index];

        #endregion

        #region Literals

        public void Literals()
        {
            // Numbers: decimal, hex, binary, and every numeric suffix.
            int decimalLiteral = 42;
            int hex = 0x1F;
            int binary = 0b1010_0101;
            long big = 9_223_372_036_854_775_807L;
            double pi = 3.14159;
            float ratio = 1.5f;
            decimal money = 19.99m;
            uint unsigned = 7u;

            // Strings: plain, with escapes, verbatim, interpolated, raw.
            string plain = "a plain string";
            string escaped = "tab:\t newline:\n quote:\" unicode:\u00e9 backslash:\\";
            string verbatim = @"C:\Users\vpcam\source\repos\no\escapes\here";
            string interpolated = $"{Label} allows {MaxAccents} accents";
            string mixed = $@"{Label}\raw\and\interpolated";

            // Booleans and null are keywords, not literals.
            bool flag = true;
            object nothing = null;

            Console.WriteLine(
                $"{decimalLiteral} {hex} {binary} {big} {pi} {ratio} {money} {unsigned}");
            Console.WriteLine($"{plain} {escaped} {verbatim} {interpolated} {mixed}");
            Console.WriteLine($"{flag} {nothing} {_counter} {_cached}");
        }

        #endregion

        #region Control flow, operators and nesting

        /// <summary>Exercises control keywords, which these themes render bold.</summary>
        /// <param name="items">A parameter name.</param>
        public int ControlFlow(IEnumerable<string> items)
        {
            var total = 0;

            // Nested braces, to show the three brace-pair levels.
            foreach (var item in items)
            {
                if (item is null)
                {
                    continue;
                }

                switch (item.Length)
                {
                    case 0:
                        goto Finished;
                    case 1:
                        total += 1;
                        break;
                    default:
                        total += item.Length;
                        break;
                }

                try
                {
                    checked
                    {
                        total *= 2;
                    }
                }
                catch (OverflowException ex) when (ex.Message.Length > 0)
                {
                    throw new InvalidOperationException("overflowed", ex);
                }
                finally
                {
                    _counter++;
                }
            }

        Finished:
            // Operators: arithmetic, comparison, logical, bitwise, null-handling.
            total = total + 1 - 2 * 3 / 4 % 5;
            total = total << 1 | 0x0F & ~0x02 ^ 0x04;
            var compared = total >= MaxAccents && total != 0 || total < -1;
            var coalesced = _cached ?? new T();
            var length = Label?.Length ?? 0;
            var ternary = compared ? length : -length;
            var lambda = (int x) => x * ternary;

            return lambda(total) + (coalesced is null ? 0 : 1);
        }

        #endregion

        #region Local functions and generics

        public static TResult Map<TSource, TResult>(TSource source, Func<TSource, TResult> project)
        {
            // A local function name.
            TResult Apply(TSource value) => project(value);

            return Apply(source);
        }

        #endregion

        #region Operator overloading

        /// <summary>An overloaded operator — bold in both theme families.</summary>
        public static AllTokens<T> operator +(AllTokens<T> left, AllTokens<T> right)
        {
            left._backing.AddRange(right._backing);
            return left;
        }

        public static bool operator ==(AllTokens<T> left, AllTokens<T> right) => Equals(left, right);

        public static bool operator !=(AllTokens<T> left, AllTokens<T> right) => !Equals(left, right);

        public override bool Equals(object obj) => ReferenceEquals(this, obj);

        public override int GetHashCode() => _counter;

        public void Dispose() => _backing.Clear();

        #endregion

        #region Preprocessor

#if THEME_SAMPLE
        // Preprocessor keywords and the text after them are separate classifications.
        private const bool SampleBuild = true;
#else
        private const bool SampleBuild = false;
#endif

#pragma warning disable CS0219
        private static void PragmaScope() { var unused = 0; }
#pragma warning restore CS0219

        #endregion
    }

    #region Other type kinds

    /// <summary>An interface name — italic in both theme families.</summary>
    public interface ITokenSample
    {
        int Count { get; }
    }

    /// <summary>A struct name.</summary>
    public struct Accent
    {
        public byte R, G, B;
    }

    /// <summary>A record class name.</summary>
    public record Palette(string Name, int Size);

    /// <summary>A record struct name.</summary>
    public record struct Swatch(string Hex);

    /// <summary>An enum name, with enum member names.</summary>
    public enum Emphasis
    {
        None = 0,
        Italic = 1,
        Bold = 2,
        BoldItalic = Italic | Bold,
    }

    /// <summary>A delegate name.</summary>
    public delegate void TokenHandler(object sender, TokenEventArgs e);

    public sealed class TokenEventArgs : EventArgs
    {
        public Emphasis Emphasis { get; set; } = Emphasis.Italic;
    }

    /// <summary>Holds an extension method name — italic in both theme families.</summary>
    public static class TokenExtensions
    {
        public static string Describe(this Emphasis emphasis) => emphasis switch
        {
            Emphasis.None => "plain",
            Emphasis.Italic => "italic",
            Emphasis.Bold => "bold",
            _ => "bold italic",
        };

        public static unsafe int PointerSize(int* pointer) => sizeof(int) + (pointer is null ? 0 : 1);
    }

    #endregion
}
