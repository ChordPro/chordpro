# CLAUDE.md - ChordPro Development Guide

This is the primary agent instruction file. .github/copilot-instructions.md points here.

## Project Overview

ChordPro is a Perl-based lyrics and chords formatting program that generates professional sheet music from text files (`.cho` format). It outputs to PDF, HTML5, HTML, Markdown, LaTeX, JSON, Text, and MMA.

- **Language**: Perl 5.26+ with modern features (signatures, Object::Pad for OOP)
- **Entry point**: `lib/ChordPro.pm` orchestrates parsing and output generation
- **Architecture**: Parser (`Song.pm`) → Song Structure → Backend Renderer (`Output/*.pm`)
- **Version**: See `lib/ChordPro/Version.pm`

**Generated test files**: Place in `testing/` directory (not `t/` - that's for production tests / unit tests)
**Generated documentation**: Place in `ai-docs/` directory

These directories keep AI-generated content separate from the main codebase until reviewed and promoted.

Update this instructions when critical lessons are learned.

## Implementation Plan Workflow

**IMPORTANT:** Read `CLAUDE-implementation-plan-chapter.md` for the XML-based implementation plan workflow. All feature requests, bugs, and changes must be tracked in `ai-docs/overview-features-bugs.xml`.

## Build & Test

```bash
# Initial setup (generates Makefile)
perl Makefile.PL

# Build (REQUIRED after modifying Perl modules - blib/ caches compiled code)
make

# Run tests 
make test          # Standard tests in t/ - - a complete test runs about 260 seconds
make tests         # Include extended tests in xt/

# Run specific test
prove -bv t/105_chords.t

# Run ChordPro during development
perl -Ilib script/chordpro.pl input.cho -o output.pdf
perl -Ilib script/chordpro.pl --generate=HTML5 input.cho -o output.html
perl -Ilib script/chordpro.pl --generate=Markdown input.cho -o output.md
```

**Critical**: Always run `make` after modifying Perl modules before testing. The `blib/` directory caches compiled code and tests use it. Test failures showing old behavior usually mean a rebuild is needed.

## Code Layout

```
lib/ChordPro.pm              # Main orchestrator
lib/ChordPro/Song.pm         # Parser - largest module (~2800 lines)
lib/ChordPro/Config.pm       # Configuration loader
lib/ChordPro/Config/Data.pm  # Auto-generated from chordpro.json (don't edit by hand)
lib/ChordPro/Output/         # Backend renderers
lib/ChordPro/Chords/         # Chord parsing and notation systems
lib/ChordPro/Delegate/       # External format processors (ABC, LilyPond)
lib/ChordPro/Paths.pm        # Resource path resolution
lib/ChordPro/res/            # Resources: configs, templates, fonts
lib/ChordPro/res/config/     # JSON configuration files
lib/ChordPro/res/templates/  # Template::Toolkit templates (html5/, html5/paged/)
script/chordpro.pl           # CLI entry point
script/wxchordpro.pl         # GUI entry point (wxWidgets)
t/                           # Production test suite
xt/                          # Extended/author tests
testing/                     # AI-generated tests (separate from production)
ai-docs/                     # AI-generated documentation
```

## Architecture

### Song Processing Pipeline

1. **Parse** (`Song.pm`): Reads ChordPro directives, builds structured representation
2. **Transform**: Transposition, chord parsing via `Chords/*.pm`
3. **Render**: Backend-specific output via `Output/*.pm`

### Output Backend Patterns

**Modern pattern** (use for new backends): Object::Pad classes inheriting from `ChordProBase` with handler registry pattern. See `Output/Markdown.pm`, `Output/HTML5.pm`.

```perl
class ChordPro::Output::MyBackend :isa(ChordPro::Output::ChordProBase) {
    method render_songline($element) { ... }
    method render_chorus($element) { ... }
}
```

**Legacy pattern** (avoid for new work): Monolithic procedural functions. See `Output/PDF.pm`, `Output/HTML.pm`.

### Configuration System

- JSON configs in `lib/ChordPro/res/config/`
- Hierarchy: builtin → sysconfig → userconfig → CLI options
- Access via global `$config` and `$options`
- Config keys use kebab-case: `chords-under`, `lyrics-only`
- Backend selection: `{format}.module` config key overrides default (e.g., `{"html": {"module": "HTML5"}}`)
- **Restricted hashes**: JSON::Relaxed creates locked hashes. Use `eval { $config->{nested}->{key} } // default` for safe access. Clone before passing to Template::Toolkit: `{ %$hashref }`.

### Song Element Structure

Songs are arrays of element hashes:

```perl
{
  type    => "songline",   # songline, chorus, verse, comment, image, gridline, etc.
  chords  => [...],        # Chord positions
  phrases => [...],        # Lyric segments between chords
  context => "chorus",     # verse, chorus, tab, grid
}
```

Metadata lives in `$song->{meta}` (NOT top-level). All metadata fields are arrayrefs.

## Key Conventions

### Perl Patterns

```perl
# Modern OOP (Object::Pad 0.818+)
use Object::Pad;
class MyClass :isa(BaseClass) {
    field $private_field;
    BUILD { $private_field = ...; }  # Required for field initialization
    method my_method($arg) { ... }
}

# Signatures
use feature qw( signatures );
no warnings "experimental::signatures";
sub mysub ( $param1, $param2 ) { ... }
```

### Chord Object Handling

Chords appear as multiple types in the rendering pipeline. Use cascading checks:

```perl
if (ref($chord) eq 'HASH') { $name = $chord->{name} }
elsif ($chord->can('chord_display')) { $name = $chord->chord_display }
elsif ($chord->can('name')) { $name = $chord->name }
else { $name = "$chord" }
```

### Test Conventions

- Tests in `t/` follow `###_feature.t` naming (numbered for execution order)
- Use `ChordPro::Testing` module (auto-chdir to `t/`, exports Test::More)
- Tests compare generated output in `t/out/` against reference in `t/ref/`
- Never create mock song objects; use real `.cho` files with `ChordPro::Song->new()->parse_file()`
- AI-generated tests go in `testing/` first, then promote to `t/` after review and delete the remains if it `testing/`

### File Placement

- New backends: `lib/ChordPro/Output/BackendName.pm`
- Reusable output modules: `lib/ChordPro/Output/ComponentName/` (NOT `lib/ChordPro/lib/`)
- New tests: develop in `testing/`, promote to `t/` after verification
- AI-generated docs: `ai-docs/`

## Common Pitfalls

1. **Forgetting to rebuild**: Run `make` after any module change before testing
2. **Metadata access**: Use `$song->{meta}->{artist}` not `$song->{artist}`; metadata values are always arrayrefs
3. **Restricted hash errors**: Wrap nested config access in `eval {}`, clone before template use
4. **Structurization**: Never call `$song->structurize()` in central dispatch (`ChordPro.pm`); each backend handles its own needs
5. **Object::Pad fields**: Must use BUILD blocks for initialization; fields are NOT auto-initialized
6. **Template array checks**: Use `[% IF subtitle.0 %]` not `[% IF subtitle.size > 0 %]` to avoid numeric comparison warnings
7. **Template dashed keys**: Use `.item('key-name')` not `.'key-name'` in Template::Toolkit
8. **SVG rendering**: `<line>` elements need explicit `stroke="#color"` attributes; CSS classes alone won't work
9. **CSS sizing**: Use `em` units instead of fixed pixels for HTML outputs

