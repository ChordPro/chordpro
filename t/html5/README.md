# HTML5 Output Backend Tests

This directory contains basic test cases for the Object::Pad-based HTML5 output backend.

## Test Files

### 01_base.t
Tests basic functionality from `ChordPro::Output::Base.pm`:
- Object creation with config and options parameters
- Reader methods: `config()`, `options()`, `song()`
- Type checking for config (ChordPro::Config object)
- Method availability: `config_has()`, `config_get()`, `generate_songbook()`

**Tests:** 12  
**Status:** ✅ All passing

### 02_chordprobase.t
Tests ChordPro-specific functionality from `ChordPro::Output::ChordProBase.pm`:
- Reader methods: `current_context()`, `is_lyrics_only()`, `is_single_space()`
- Abstract method implementations: `render_chord()`, `render_songline()`, `render_grid_line()`
- Element dispatch system: `dispatch_element()`
- Element handlers: `handle_songline()`, `handle_chorus()`, `handle_verse()`, `handle_comment()`, `handle_set()`, `handle_diagrams()`

**Tests:** 15  
**Status:** ✅ All passing

### 03_html5_output.t
Integration tests for `ChordPro::Output::HTML5.pm`:
- Generates HTML output from .cho files
- Compares output against reference .html files
- Tests 3 sample songs with different features

**Tests:** 4  
**Status:** ✅ All passing

## Test Data Files

### simple.cho
Basic song with chords on lyrics:
- Title and artist metadata
- Simple chord placement

### chorus.cho
Song structure with verses and chorus:
- `{start_of_verse}` / `{end_of_verse}` directives
- `{start_of_chorus}` / `{end_of_chorus}` directives
- Multiple verses

### comment.cho
Comment handling:
- Hash-style comments (`#`)
- Directive comments (`{comment: ...}`)
- Subtitle metadata

## Running the Tests

### Run all HTML5 tests:
```bash
cd /workspace
PERL5LIB=/home/vscode/perl5/lib/perl5:$PERL5LIB prove -v t/html5/*.t
```

### Run a specific test:
```bash
PERL5LIB=/home/vscode/perl5/lib/perl5:$PERL5LIB prove -v t/html5/01_base.t
```

### Update reference files:
If you make changes to HTML5.pm and want to update the reference files:
```bash
cd t
for file in html5/*.cho; do 
    perl -I../lib ../script/chordpro.pl --no-default-configs \
        --generate HTML5 --output "${file%.cho}.html" "$file"
done
```

## Dependencies

These tests require:
- `JSON::Relaxed` - Install with `cpanm JSON::Relaxed`
- All standard ChordPro dependencies

## Architecture Tested

These tests validate the three-tier architecture:

1. **Base Layer** (`ChordPro::Output::Base`)
   - Configuration management
   - Abstract rendering methods
   - Song state management

2. **ChordPro Layer** (`ChordPro::Output::ChordProBase`)
   - ChordPro-specific abstractions
   - Element dispatching
   - Context tracking (verse/chorus/etc.)
   - Handler methods for directives

3. **Format Layer** (`ChordPro::Output::HTML5`)
   - Concrete HTML5 implementation
   - Flexbox chord positioning
   - CSS styling
   - Escaped HTML output
