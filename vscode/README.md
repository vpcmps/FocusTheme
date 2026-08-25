# Focus Themes

Six high-separation dark themes for Visual Studio Code and Cursor, designed for
fast scanning. Each gives every kind of type a color of its own - class,
interface, record, struct, and enum are five different hues, not five shades of
one - so the shape of a file reads before you read a word of it.

The same six palettes ship for Visual Studio, Rider, and PyCharm. They are
generated from one table, so a theme is the same theme in every editor.

## The six

### Focus Voltage

Hot pink keywords against cyan types - the two loudest hues sit at opposite ends of the wheel, so structure pops before you read a word. Reference types stay cool (cyan class, mint italic interface) and value types go warm (lime record, amber struct, orange enum), so the cool/warm split alone says what you are looking at.

### Focus Ultraviolet

A violet ground with magenta classes, sky records and mint structs - behaviour and data occupy different temperature zones, so a DTO never reads as a service.

### Focus Reactor

A green-black ground reads calmer than a blue one, which lets a single orange accent carry all the urgency. Aqua class, pale-aqua italic interface, violet record, pink struct, azure enum - five type kinds, five clearly separated hues, with literals kept in one chartreuse family so they never compete with declarations.

### Focus Arcade

The loudest of the six: five saturated hues at near-equal weight. Nothing recedes except comments, which is the point - every token class claims its own hue rather than sharing one. With five type kinds in play that puts real pressure on the yellow family.

### Focus Signal

The restrained option. A neutral grey-black ground, one orange-red accent for keywords, cooler hues for everything else. All five type kinds still separate cleanly - blue class, periwinkle italic interface, violet record, teal struct, pink enum - but nothing shouts. The safest pick for eight-hour days.

### Focus Nightdive

Deep teal-black with coral keywords, chartreuse records and lavender structs - complementary pairs, so declarations never blur together in dense files. The only direction whose accent is not its keyword hue: the teal that marks classes carries the chrome instead.


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
