---
title: "Configuration for LaTeX output"
description: "Configuration for LaTeX output"
---

# Configuration for LaTeX output

Definitions for LaTeX output are stored in the configuration under the
key `"latex"`. For example, when setting a template path:

    latex.templates.songbook: "my-songbook.tt"

or

    latex {
        templates {
            songbook: "my-songbook.tt"
        }
    }

Topics in this document:
{{< toc >}}

## Overview

The LaTeX backend generates professional `.tex` files that can be compiled to PDF using LaTeX processors. Unlike the PDF backend which directly generates PDF files, the LaTeX backend produces intermediate LaTeX source code, giving you complete control over the typesetting process.

The LaTeX backend is fully template-driven using [Template Toolkit](http://www.template-toolkit.org/), allowing complete customization of the LaTeX output without modifying backend code.

## Why Use LaTeX Output?

The LaTeX backend is ideal when you need:

* **Full typesetting control**: Edit the generated `.tex` file before compiling
* **Integration with LaTeX workflows**: Incorporate songs into existing LaTeX documents
* **Custom LaTeX packages**: Use specialized music notation packages or layout tools
* **Academic or professional publishing**: Leverage LaTeX's superior typography
* **Batch processing**: Generate LaTeX source for automated document pipelines
* **Version control**: Store `.tex` files in git for collaborative editing

## Template System

The LaTeX backend uses Template Toolkit for all output generation. Templates define the LaTeX structure and commands used in the final output.

### Template Configuration

Templates are specified in the configuration:

    latex {
        templates {
            songbook : "songbook.tt"    // Main document template
            comment  : "comment.tt"     // Comment rendering template
            image    : "image.tt"       // Image inclusion template
        }
    }

### Built-in Templates

ChordPro includes two complete LaTeX template sets:

#### 1. Songs Package Templates (Default)

Located at `lib/ChordPro/res/templates/`:
* **songbook.tt**: Full document using the [songs package](http://songs.sourceforge.net/songsdoc/songs.html)
* **comment.tt**: Styled comment boxes with tcolorbox
* **image.tt**: Image inclusion with scaling

The songs package is specifically designed for chord sheets and provides:
* Automatic chord positioning above lyrics
* Verse and chorus environments
* Chord diagram support (`\gtab` command)
* Multiple column layout
* Automatic songbook indexing

#### 2. Guitar Package Templates

Located at `lib/ChordPro/res/templates/`:
* **guitar_songbook.tt**: Uses the [guitar package](https://ctan.org/pkg/guitar)
* **guitar_comment.tt**: Alternative comment styling
* **guitar_image.tt**: Image handling for guitar package

The guitar package provides:
* `\guitarChord{}` macro for chord notation
* Integrated with gchords package for diagrams
* Article-based layout (vs. songs' book format)

### Switching Template Sets

To use the guitar package templates:

    latex {
        templates {
            songbook : "guitar_songbook.tt"
            comment  : "guitar_comment.tt"
            image    : "guitar_image.tt"
        }
    }

### Template Include Paths

Add custom template directories to the search path:

    latex {
        template_include_path : [
            "/path/to/my/templates",
            "$HOME/.config/chordpro/templates",
            "$CHORDPRO_LIB/mytemplates"
        ]
    }

Templates in these directories override built-in templates. ChordPro searches paths in order:
1. Your custom `template_include_path` directories
2. ChordPro's built-in template directory
3. `$CHORDPRO_LIBRARY` environment variable path

## Creating Custom Templates

### Basic Template Structure

A minimal LaTeX songbook template:

```latex
\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage{songs}

\begin{document}
[% FOREACH song IN songs %]
  \beginsong{[% song.title %]}
  [% song.songlines | eval %]
  \endsong
[% END %]
\end{document}
```

### Template Variables

Templates receive these variables from the backend:

#### Song Variables

* **`song.title`**: Song title (LaTeX-encoded)
* **`song.subtitle`**: Array of subtitles
* **`song.meta`**: Hash of all metadata fields
  * `song.meta.artist` – Artist name(s)
  * `song.meta.composer` – Composer name(s)
  * `song.meta.lyricist` – Lyricist name(s)
  * `song.meta.copyright` – Copyright notice
  * `song.meta.album` – Album name
  * `song.meta.key` – Musical key
  * `song.meta.time` – Time signature
  * `song.meta.tempo` – Tempo marking
  * `song.meta.capo` – Capo position
  * `song.meta.index` – Index entry (first phrase)
* **`song.chords`**: Array of chord definitions
  * `chord.chord` – Chord name
  * `chord.frets` – Fret positions (e.g., "X32010")
  * `chord.base` – Base fret
  * `chord.fingers` – Finger positions
* **`song.songlines`**: Rendered song body (LaTeX text)

#### Songbook Variables

* **`songs`**: Array of song objects (each containing the above)

### Control Tags

Templates must define these control tags that the backend uses when generating song content:

```latex
[% 
 newpage_tag = "\\newpage\n"
 emptyline_tag = "\\newline\n"
 columnbreak_tag = "\\columnbreak\n"
 beginchorus_tag = "\\beginchorus"
 endchorus_tag = "\\endchorus"
 beginverse_tag = "\\beginverse"
 endverse_tag = "\\endverse"
 begintab_tag = "\\begin{verbatim}"
 endtab_tag = "\\end{verbatim}"
 begingrid_tag = "\\begin{verbatim}"
 endgrid_tag = "\\end{verbatim}"
 gchordstart_tag = "\\["
 gchordend_tag = "]"
 chorded_line = "\\chordson "
 unchorded_line = "\\chordsoff "
 start_spaces_songline = "\\hspace{0.5cm}"
 eol = "\n"
%]
```

#### Tag Descriptions

* **`newpage_tag`**: LaTeX command for page breaks (`{new_page}` directive)
* **`emptyline_tag`**: Command for empty lines
* **`columnbreak_tag`**: Column break command (`{column_break}` directive)
* **`beginchorus_tag`** / **`endchorus_tag`**: Chorus environment delimiters
* **`beginverse_tag`** / **`endverse_tag`**: Verse environment delimiters
* **`begintab_tag`** / **`endtab_tag`**: Tab environment (usually verbatim)
* **`begingrid_tag`** / **`endgrid_tag`**: Grid environment (usually verbatim)
* **`gchordstart_tag`** / **`gchordend_tag`**: Chord notation delimiters
  * Songs package: `\[` and `]`
  * Guitar package: `\guitarChord{` and `}`
* **`chorded_line`**: Command before lines containing chords
* **`unchorded_line`**: Command before lines without chords
* **`start_spaces_songline`**: Replacement for leading spaces in lyrics
* **`eol`**: End-of-line sequence (`\n`, `\\`, or `\newline`)

### Example: Custom Comment Template

Create `my-comment.tt`:

```latex
\begin{tcolorbox}[colback=yellow!10, colframe=orange!80, 
                  width=\textwidth, arc=2mm]
  \textit{[% comment %]}
\end{tcolorbox}
```

Then configure it:

    latex.templates.comment : "my-comment.tt"

### Example: Custom Image Template

Create `my-image.tt`:

```latex
\begin{figure}[h]
  \centering
  \includegraphics[width=[% opts.scale || 0.8 %]\textwidth]{[% uri %]}
  [% IF opts.title %]\caption{[% opts.title %]}[% END %]
\end{figure}
```

Configure:

    latex.templates.image : "my-image.tt"

## LaTeX Packages

### Required Packages

The default templates require these LaTeX packages:

#### Songs Package Template
```latex
\usepackage[chorded]{songs}      % Chord sheet formatting
\usepackage[TS1,T1]{fontenc}     % Font encoding
\usepackage{graphicx}            % Image support
\usepackage[most]{tcolorbox}     % Styled boxes (comments, diagrams)
\usepackage[bookmarks]{hyperref} % PDF bookmarks
\usepackage{fancyhdr}            % Headers/footers
```

#### Guitar Package Template
```latex
\usepackage{guitar}              % Guitar chord notation
\usepackage{gchords}             % Chord diagrams
\usepackage[most]{tcolorbox}     % Styled boxes
\usepackage{graphicx}            % Image support
```

### Installing LaTeX Packages

On most systems with TeX Live or MiKTeX:

```bash
# TeX Live (Linux/Mac)
sudo tlmgr install songs guitar gchords tcolorbox

# MiKTeX (Windows)
mpm --install=songs
mpm --install=guitar
mpm --install=gchords
```

Or install via your distribution's package manager:

```bash
# Debian/Ubuntu
sudo apt install texlive-latex-extra

# Fedora
sudo dnf install texlive-songs texlive-guitar

# macOS (MacTeX)
# Usually includes all packages
```

### Package Documentation

* **Songs package**: [http://songs.sourceforge.net/songsdoc/songs.html](http://songs.sourceforge.net/songsdoc/songs.html)
* **Guitar package**: [https://ctan.org/pkg/guitar](https://ctan.org/pkg/guitar)
* **GChords package**: [https://ctan.org/pkg/gchords](https://ctan.org/pkg/gchords)
* **TColorBox**: [https://ctan.org/pkg/tcolorbox](https://ctan.org/pkg/tcolorbox)

## Workflow

### Basic Usage

1. Generate LaTeX source:
   ```bash
   chordpro --generate=LaTeX song.cho -o song.tex
   ```

2. Compile to PDF:
   ```bash
   pdflatex song.tex
   pdflatex song.tex  # Run twice for indexes and cross-references
   ```

3. View the PDF:
   ```bash
   open song.pdf  # macOS
   xdg-open song.pdf  # Linux
   ```

### Songbook Workflow

Generate songbook from multiple songs:

```bash
# Generate LaTeX
chordpro --generate=LaTeX song1.cho song2.cho song3.cho -o songbook.tex

# Compile
pdflatex songbook.tex
pdflatex songbook.tex  # Second pass for index
```

### With Custom Configuration

```bash
# Use custom templates and settings
chordpro --config=mylatex.json --generate=LaTeX songs/*.cho -o songbook.tex
```

### Integration with Existing LaTeX Documents

Extract just the song content by creating a minimal template:

```latex
[% FOREACH song IN songs %]
\beginsong{[% song.title %]}[by={[% song.meta.composer.0 %]}]
[% song.songlines | eval %]
\endsong

[% END %]
```

Then `\input` the result into your main document:

```latex
\documentclass{book}
\usepackage{songs}
\begin{document}
\begin{songs}{titleidx}
  \input{generated-songs}
\end{songs}
\end{document}
```

## Chord Diagrams

The LaTeX backend includes chord diagram support using package-specific commands.

### Songs Package Diagrams

The `\gtab` command creates chord diagrams:

```latex
\gtab{C}{X32010}    % Chord name, fret positions
\gtab{G}{320003}
```

In the template, diagrams are rendered like:

```latex
[% IF song.chords.0 %]
  [% FOREACH chord IN song.chords %]
    \gtab{[% chord.chord %]}{[% chord.frets %]}
  [% END %]
[% END %]
```

Fret positions use:
* `X` or `x` – Muted string
* `0` – Open string
* `1-9` – Fret numbers

### Guitar/GChords Package Diagrams

The `\chord` command creates diagrams:

```latex
\chord{t}{p3,p2,x,x,x,3}{C}  % Type, positions, name
```

The template converts ChordPro format to gchords format:

```latex
\chord{t}{[% FOREACH fret IN chord.frets.split(''); 
  IF fret != 'X'; 
    IF fret != '0'; 'p'; fret; END;
  ELSE; 'x'; END;
  IF not loop.last; ','; END;
END %]}{[% chord.chord %]}
```

### Diagram Positioning

Control diagram layout in your template:

```latex
% Display diagrams in a colored box
\begin{tcolorbox}[colback=white, colframe=black, 
                  width=0.75\textwidth, arc=3mm]
  [% FOREACH chord IN song.chords %]
    \gtab{[% chord.chord %]}{[% chord.frets %]}
    [% elements = loop.count % 5 %]
    [% IF ((elements == 0) and (not loop.last)) %]\newline[% END %]
  [% END %]
\end{tcolorbox}
```

This creates 5 diagrams per line with line breaks.

## Page Layout

### Songs Package Layout

Control page layout with LaTeX geometry:

```latex
\setlength{\textwidth}{10cm}
\setlength{\topmargin}{-1cm}
\setlength{\textheight}{18cm}
```

Songs package-specific settings:

```latex
\songcolumns{2}           % Two-column layout
\songcolumns{0}           % Disable songs package column management
\songpos{2}               % Page break preference (1-3)
\noversenumbers           % Disable verse numbering
\setlength{\sbarheight}{0pt}  % No horizontal rules
```

### Column Layout

Enable multi-column layout:

```latex
\songcolumns{2}  % Two columns
```

Or use standard LaTeX columns:

```latex
\usepackage{multicol}
\begin{multicols}{2}
  [% song.songlines | eval %]
\end{multicols}
```

### Page Breaks

Control page breaking behavior:

```latex
\songpos{1}  % Prefer keeping songs together (less aggressive)
\songpos{2}  % Balanced (default)
\songpos{3}  % Allow more aggressive breaking
```

Or force page breaks in your ChordPro file:

    {new_page}

## Headers and Footers

### Songs Package Headers/Footers

Using fancyhdr package:

```latex
\usepackage{fancyhdr}
\pagestyle{fancy}

\fancyhf{}                      % Clear all fields
\fancyhead[L]{My Songbook}      % Left header
\fancyhead[R]{\rightmark}       % Right header (song title)
\fancyfoot[C]{\thepage}         % Center footer (page number)
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0pt}
```

### Dynamic Song Titles in Headers

The songs package provides `\songmark`:

```latex
\renewcommand{\songmark}{\markboth{\thesongnum}{\songtitle}}
```

Then use `\leftmark` or `\rightmark` in headers:

```latex
\fancyhead[R]{\rightmark}  % Current song title
```

## Indexes

The songs package supports multiple indexes:

```latex
\newindex{titleidx}{cbtitle}        % Title index
\newauthorindex{authidx}{cbauth}    % Author index
\newscripindex{scripidx}{cbscrip}   % Scripture index
```

Reference indexes in song headers:

```latex
\beginsong{[% song.title %]}[
  by={[% song.meta.composer.0 %]},
  index={[% song.meta.index %]}
]
```

Display indexes:

```latex
\showindex{Index}{titleidx}
\showindex{Index of Authors and Composers}{authidx}
```

Compile twice for indexes to update:

```bash
pdflatex songbook.tex
pdflatex songbook.tex  # Updates indexes
```

## Customization Examples

### Example 1: A4 Two-Column Songbook

Configuration file `a4-songbook.json`:

```json
{
  "latex": {
    "templates": {
      "songbook": "my-a4-songbook.tt"
    }
  }
}
```

Template `my-a4-songbook.tt`:

```latex
[% newpage_tag = "\\newpage\n" 
   # ... other tags ...
%]
\documentclass[a4paper]{book}
\usepackage[chorded]{songs}
\usepackage{graphicx}

\songcolumns{2}
\setlength{\textwidth}{18cm}

\begin{document}
\begin{songs}{titleidx}
[% FOREACH song IN songs %]
\beginsong{[% song.title %]}
[% song.songlines | eval %]
\endsong
[% END %]
\end{songs}
\end{document}
```

Usage:

```bash
chordpro --config=a4-songbook.json --generate=LaTeX *.cho -o songbook.tex
pdflatex songbook.tex
```

### Example 2: Minimal Single-Song Template

For including in larger documents, create `minimal.tt`:

```latex
[% newpage_tag = "" 
   emptyline_tag = "\\newline\n"
   # ... other tags ...
%]
[% FOREACH song IN songs %]
\section{[% song.title %]}
[% IF song.subtitle.0 %]\textit{[% song.subtitle.0 %]}[% END %]

[% song.songlines | eval %]

[% END %]
```

### Example 3: Custom Chorus Styling

Modify `beginchorus_tag` and `endchorus_tag`:

```latex
[% 
  beginchorus_tag = "\\begin{tcolorbox}[colback=blue!5, colframe=blue!75, boxrule=2pt, arc=3mm]\n\\textbf{Chorus:}\\\\"
  endchorus_tag = "\\end{tcolorbox}"
%]
```

This creates blue-bordered boxes with "Chorus:" label.

### Example 4: Landscape Tablature Layout

For tab-heavy songs:

```latex
\documentclass[landscape]{article}
\usepackage[a4paper, margin=1cm]{geometry}
\usepackage{songs}

[% begintab_tag = "\\begin{verbatim}" %]
[% endtab_tag = "\\end{verbatim}" %]

% Reduce font size for more tab content
\small
```

## Advanced Features

### ABC Music Notation

The LaTeX backend supports ABC notation via ChordPro's ABC delegate:

In your ChordPro file:

    {start_of_abc}
    X:1
    M:4/4
    L:1/4
    K:C
    C D E F | G2 G2 | A A A A | G4 |
    {end_of_abc}

The backend generates:

```latex
\begin{abc}
X:1
M:4/4
L:1/4
K:C
C D E F | G2 G2 | A A A A | G4 |
\end{abc}
```

Note: This requires LaTeX packages that support ABC, or pre-processing ABC to images.

### LilyPond Integration

Similarly for LilyPond notation:

    {start_of_ly}
    \relative c' { c4 d e f g2 g }
    {end_of_ly}

Generates:

```latex
\begin{lilypond}
\relative c' { c4 d e f g2 g }
\end{lilypond}
```

Requires the `lilypond-book` preprocessor or lilypond-book LaTeX package.

### Grid Sections

Chord grids are rendered as verbatim text:

```latex
\begin{verbatim}
| C    | G    | Am   | F    |
| C    | G    | C    | C    |
\end{verbatim}
```

Customize grid rendering by modifying `begingrid_tag` and `endgrid_tag` in your template.

### Tab Sections

Tablature uses verbatim environment:

```latex
\begin{verbatim}
e|--0--1--3--1--0--|
B|--1--1--1--1--1--|
G|--0--0--0--0--0--|
\end{verbatim}
```

For better formatting, consider the `musixtex` or `guitar` package's tab environments.

## LaTeX Encoding

All text passed to templates is automatically LaTeX-encoded to handle special characters:

* `&` → `\&`
* `%` → `\%`
* `$` → `\$`
* `#` → `\#`
* `_` → `\_`
* `{` → `\{`
* `}` → `\}`
* `~` → `\textasciitilde{}`
* `^` → `\textasciicircum{}`
* `\` → `\textbackslash{}`

This ensures special characters in song lyrics and metadata don't break LaTeX compilation.

## Troubleshooting

### LaTeX Compilation Errors

**Undefined control sequence**: Missing LaTeX package.
* Solution: Install required packages (songs, guitar, tcolorbox, etc.)

**Missing character**: Font encoding issue.
* Solution: Add `\usepackage[T1]{fontenc}` or use `\usepackage[utf8]{inputenc}`

**Dimension too large**: Page layout conflict.
* Solution: Adjust `\textwidth`, `\textheight`, or margins

### Chord Positioning Issues

**Chords not appearing**: Check `chorded_line` and chord tags are correctly defined.

**Chord format errors**: Ensure chord syntax matches package requirements:
* Songs package: `\[C]` format
* Guitar package: `\guitarChord{C}` format

### Index Not Appearing

**Empty indexes**: Run `pdflatex` twice to generate indexes.

**Index files missing**: Check that index definitions are present in template:
```latex
\newindex{titleidx}{cbtitle}
```

### Custom Template Not Found

**Template not loading**: Check `template_include_path` uses absolute paths or valid path variables.

**Variables not substituting**: Ensure `| eval` filter is applied to `song.songlines`:
```latex
[% song.songlines | eval %]
```

### Encoding Issues

**Special characters broken**: Verify LaTeX encoding is applied. The backend automatically encodes text, but custom templates need `| eval` for tag substitution.

## Configuration Reference

Complete LaTeX configuration structure:

```json
{
  "latex": {
    "template_include_path": [
      "/path/to/templates",
      "$HOME/.config/chordpro/templates"
    ],
    "templates": {
      "songbook": "songbook.tt",
      "comment": "comment.tt",
      "image": "image.tt"
    }
  }
}
```

## Resources

* **Template Toolkit Manual**: [http://www.template-toolkit.org/docs/manual/](http://www.template-toolkit.org/docs/manual/)
* **Songs Package Documentation**: [http://songs.sourceforge.net/songsdoc/songs.html](http://songs.sourceforge.net/songsdoc/songs.html)
* **Guitar Package Documentation**: [https://ctan.org/pkg/guitar](https://ctan.org/pkg/guitar)
* **GChords Documentation**: [https://ctan.org/pkg/gchords](https://ctan.org/pkg/gchords)
* **CTAN (LaTeX Packages)**: [https://www.ctan.org/](https://www.ctan.org/)
* **LaTeX Project**: [https://www.latex-project.org/](https://www.latex-project.org/)

## Tips and Best Practices

### Choosing Songs vs. Guitar Package

**Use Songs package when:**
* Creating comprehensive songbooks with indexes
* Need automatic verse numbering and structure
* Want specialized chord sheet formatting
* Planning book-style layout with page numbers

**Use Guitar package when:**
* Creating simpler article-style documents
* Need fine control over chord positioning
* Prefer `\guitarChord{}` syntax
* Integrating with other guitar-focused packages

### Template Development Workflow

1. Start with a built-in template (copy to custom location)
2. Make small incremental changes
3. Test each change by generating and compiling LaTeX
4. Keep original templates as reference
5. Document custom control tags in template comments

### Performance Tips

* **Large songbooks**: Use `\includesongs{range}` to compile subsets during development
* **Compilation speed**: Disable indexes during development, enable for final version
* **Image-heavy**: Use `draft` document class option for faster preview

### Version Control

LaTeX output is ideal for git:
```bash
chordpro --generate=LaTeX *.cho -o songbook.tex
git add songbook.tex
git commit -m "Update songbook LaTeX source"
```

Track `.tex` files, not PDFs, for better diff viewing.

### Professional Publishing

For professional results:
1. Use LaTeX output for maximum typography control
2. Compile with `pdflatex` or `xelatex`
3. Fine-tune page breaks and spacing in generated `.tex`
4. Add custom LaTeX commands for special formatting
5. Use professional fonts with `fontspec` package (XeLaTeX)

### Hybrid Workflow

Generate LaTeX, then manually edit before final compilation:

```bash
# Generate initial LaTeX
chordpro --generate=LaTeX songs/*.cho -o songbook.tex

# Edit songbook.tex manually for fine-tuning
nano songbook.tex

# Compile final PDF
pdflatex songbook.tex
pdflatex songbook.tex
```

This combines ChordPro's parsing with LaTeX's formatting power.
