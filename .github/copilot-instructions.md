# ChordPro Development Guide for AI Agents

## Project Overview
ChordPro is a Perl-based lyrics and chords formatting program that generates professional sheet music from text files. It parses ChordPro format files (`.cho`) and outputs to multiple backends: PDF, HTML, HTML5, Markdown, LaTeX, JSON, and Text.

**Core Language**: Perl 5.26+ with modern features (signatures, Object::Pad for OOP)
**Main Entry**: `lib/ChordPro.pm` - orchestrates parsing and output generation
**Architecture**: Parser → Song Structure → Backend Renderer

## Critical Architecture Patterns

### Song Processing Pipeline
1. **Parse** (`lib/ChordPro/Song.pm`, ~2800 lines): Reads ChordPro directives and builds structured representation
2. **Transform**: Apply transposition, substitutions, chord parsing via `lib/ChordPro/Chords/*.pm`
3. **Render**: Backend-specific output via `lib/ChordPro/Output/*.pm`

### Output Backend Architecture
**Two distinct patterns exist** - understand which to follow:

**Legacy Pattern** (PDF.pm, HTML.pm):
- Monolithic functions with 500+ line if/elsif chains
- Hard to maintain; avoid for new backends

**Modern Pattern** (Markdown.pm, HTML5.pm, ChordPro.pm):
- Object::Pad classes inheriting from `ChordProBase`
- Handler registry pattern: `%element_handlers` maps element types to methods
- Each directive type has dedicated handler method
- Example from Markdown.pm:
  ```perl
  class ChordPro::Output::Markdown :isa(ChordPro::Output::ChordProBase) {
      method render_songline($element) { ... }
      method render_chorus($element) { ... }
  }
  ```

**When creating new output backends**: Use Object::Pad pattern, inherit from ChordProBase, implement required methods.

### Configuration System
- JSON-based configs in `lib/ChordPro/res/config/`
- Loaded via `lib/ChordPro/Config.pm`
- Access via global `$config` and `$options` variables
- Config hierarchy: builtin → sysconfig → userconfig → CLI options
- Test configs: Use `ChordPro::Config::configurator()` without args for minimal setup

## AI Agent Output Conventions

**Generated test files**: Place in `testing/` directory (not `t/` - that's for production tests / unit tests)
**Generated documentation**: Place in `ai-docs/` directory

These directories keep AI-generated content separate from the main codebase until reviewed and promoted.

## Development Workflows

### Building & Testing
```bash
# Initial setup (generates Makefile from Makefile.PL)
perl Makefile.PL

# Run tests via GNUmakefile (preferred - sets PERL5LIB correctly)
make test          # Standard tests in t/
make tests         # Include extended tests in xt/

# Run specific test
prove -bv t/105_chords.t
```

### Running ChordPro During Development
```bash
# Single file - using installed script (if available)
./script/chordpro input.cho -o output.pdf

# Single file - development mode (no install needed)
perl -Ilib script/chordpro.pl input.cho -o output.pdf

# Generate songbook from multiple files (creates single output)
perl -Ilib script/chordpro.pl songs/*.cho -o songbook.pdf
perl -Ilib script/chordpro.pl song1.cho song2.cho song3.cho -o output.pdf

# Specify output backend
perl -Ilib script/chordpro.pl --generate=HTML5 songs/*.cho -o songbook.html
perl -Ilib script/chordpro.pl --generate=Markdown songs/*.cho -o songbook.md

# Quick inspection outputs
perl -Ilib script/chordpro.pl --generate=PDF input.cho -o output.pdf
perl -Ilib script/chordpro.pl --generate=HTML5 input.cho -o output.html
```

### Test Structure
- Tests in `t/` follow pattern: `###_feature.t` (numbered for execution order)
- Use `ChordPro::Testing` module which:
  - Auto-chdir to `t/` directory
  - Exports Test::More functions
  - Provides `is_deeply` for song structure comparison
- Tests compare generated output in `t/out/` against reference in `t/ref/`
- Test parameter pattern from `t/00_basic.pl`:
  ```perl
  my ($num, $basic, $backend) = @::params;
  @ARGV = ("--no-default-configs", "$basic.cho", "--output=out/$out");
  ::run();
  ok(!differ("out/$out", "ref/$out"));
  ```

### Testing HTML5 Backends
- `generate_song()` returns song HTML only (no headers/CSS), `generate_songbook()` returns full document
- For song-level tests, check for content presence rather than full document structure
- Example test pattern:
  ```perl
  my $html = $backend->generate_song($song);
  ok($html && length($html) > 0, "Output generated");
  like($html, qr/expected-content/, "Contains expected content");
  ```
- Backend modules must handle both chord info as blessed objects (runtime) and plain hash refs (tests)
- When testing inheritance (HTML5Paged from HTML5), verify inherited functionality is present without re-testing implementation details

### Chord System
- **Multiple notation systems**: standard (C, D, E...), solfege (Do, Re, Mi...), Nashville (1, 2, 3...), Roman (I, II, III...)
- Parser in `lib/ChordPro/Chords/Parser.pm` - understands transposition between systems
- Chord appearance (font, rendering) in `lib/ChordPro/Chords/Appearance.pm`
- Each song tracks used chords in order: `@used_chords` in Song.pm
- Configuration key: `$config->{notes}->{sharp}` defines the interval system

## Project-Specific Conventions

### Perl Patterns
```perl
# Modern OOP - Object::Pad (v0.818+)
use Object::Pad;
class MyClass :isa(BaseClass) {
    field $private_field;
    method my_method($arg) { ... }
}

# Signatures (Perl 5.26+)
use feature qw( signatures );
no warnings "experimental::signatures";
sub mysub ( $param1, $param2 ) { ... }

# Global variables (accessible in all packages)
our $options;  # CLI options
our $config;   # Configuration hash
```

### Element Structure
Songs are arrays of element hashes:
```perl
{
  type => "songline",      # Type: songline, chorus, verse, comment, etc.
  chords => [...],         # Chord positions and names
  phrases => [...],        # Lyric segments between chords
  context => "chorus",     # Context (verse, chorus, tab, grid)
}
```

### Naming Conventions
- Backends: `lib/ChordPro/Output/BackendName.pm` with `generate_songbook()` and `generate_song()` methods
- Tests: Numeric prefix indicates category (100s = basic, 300s = config, 80s = pagination)
- Config keys use kebab-case: `chords-under`, `lyrics-only`, `single-space`

## Key Integration Points

### ABC & LilyPond Music Notation
- Delegates to external processors: `lib/ChordPro/Delegate/ABC.pm`, `lib/ChordPro/Delegate/Lilypond.pm`
- ABC uses bundled `abc2svg` (JavaScript via Perl's JavaScript::QuickJS)
- LilyPond requires external `lilypond` binary
- Both output SVG embedded in final document

### Resource Resolution
- `ChordPro::Paths` handles resource lookup (configs, fonts, icons)
- Resources in `lib/ChordPro/res/` - fonts, configs, icons, abc/lilypond delegates
- Use `CP->findres($name, class => "type")` for resource loading

### GUI (wxChordpro)
- Separate wxWidgets frontend: `lib/ChordPro/Wx.pm`, `script/wxchordpro`
- Shares core parsing/rendering with CLI
- Not required for core ChordPro development

## Common Pitfalls

1. **Don't mix output patterns**: Use Object::Pad for new backends, not procedural style
2. **Config access timing**: Config loaded after option parsing; tests use `configurator()` to initialize
3. **Chord transposition**: Song.pm handles it during parsing; backends receive transposed chords
4. **Context management**: Song parser tracks context (`verse`, `chorus`, `tab`, `grid`); backends must respect it
5. **Line info tracking**: `$config->{settings}->{lineinfo}` controls source line tracking in output
6. **SVG rendering**: SVG `<line>` elements require explicit `stroke="#color"` attributes - CSS classes alone are insufficient for visibility
7. **CSS sizing for HTML outputs**: Use `em` units (e.g., `width: 4em`) instead of fixed pixels for better scalability across different font sizes
8. **Module flexibility**: When creating reusable modules, support both blessed objects and plain hash refs for maximum compatibility (check `ref($obj) eq 'HASH'` vs object methods)
9. **HTML5Paged inheritance**: HTML5Paged extends HTML5 via Object::Pad's `:isa()` - changes to HTML5 automatically propagate. HTML5Paged's `generate_paged_css()` must include ALL CSS rules (it doesn't call parent's CSS generation)
10. **Module organization**: Reusable output modules go in `lib/ChordPro/Output/ComponentName/`, NOT `lib/ChordPro/lib/` (Perl's @INC won't find them there)

## Recent Architectural Efforts
The project is migrating from monolithic backends (PDF.pm - 2800 lines) to modular Object::Pad-based architecture. See `Design/ARCHITECTURE_COMPARISON.md` and `Design/HTML5_*.md` for detailed rationale. **Follow the Markdown.pm pattern for new work**, not PDF.pm.

### Recent Additions (Dec 2025)
- **SVG Chord Diagrams**: HTML5 and HTML5Paged backends now support inline SVG chord diagrams
  - Implementation in `lib/ChordPro/Output/HTML5.pm` methods: `render_chord_diagrams()`, `generate_chord_diagram_svg()`
  - Standalone reusable module: `lib/ChordPro/Output/ChordDiagram/SVG.pm`
  - Diagrams sized at `4em` width for scalability with font size
  - Respects config settings: `diagrams.show`, `diagrams.sorted`, `diagrams.suppress`
  - Tests: `testing/145_chord_diagrams_svg.t`, `testing/146_html5_chord_diagrams.t`, `testing/147_html5paged_chord_diagrams.t`
