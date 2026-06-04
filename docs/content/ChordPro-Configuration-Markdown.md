---
title: "Configuration for Markdown output"
description: "Configuration for Markdown output"
---

# Configuration for Markdown output

The Markdown backend generates standard Markdown-formatted text files that can be viewed in any Markdown viewer, converted to HTML, or used in documentation systems like GitHub, GitLab, Hugo, Jekyll, and many others.

Topics in this document:
{{< toc >}}

## Overview

ChordPro's Markdown output backend produces clean, readable Markdown files with:

* **Standard Markdown syntax**: Compatible with all major Markdown processors
* **Chords above lyrics**: Default formatting with proper alignment
* **Inline chord diagrams**: Automatic chord diagram images via external services
* **Structural elements**: Proper headings, blockquotes, and formatting
* **Web-friendly**: Ready for wikis, blogs, documentation sites, and version control

Unlike PDF or LaTeX output which focus on print, Markdown output is designed for digital viewing and web publishing.

## Why Use Markdown Output?

The Markdown backend is ideal when you need:

* **Web publishing**: Post songs on websites, wikis, or blogs
* **Documentation systems**: Integrate with Hugo, Jekyll, MkDocs, GitBook
* **Version control**: Track changes in git with readable diffs
* **Collaboration**: Share on GitHub, GitLab, or other platforms
* **Plain text**: Simple, portable format readable anywhere
* **Easy editing**: Edit output files with any text editor
* **Multi-format conversion**: Use Pandoc to convert to many formats
* **Quick preview**: View in any Markdown viewer or editor

## Basic Usage

Generate Markdown output from ChordPro files:

```bash
# Single song
chordpro --generate=Markdown song.cho -o song.md

# Multiple songs (songbook)
chordpro --generate=Markdown song1.cho song2.cho song3.cho -o songbook.md

# With configuration file
chordpro --config=myconfig.json --generate=Markdown songs/*.cho -o output.md
```

## Output Structure

A typical Markdown output file contains:

```markdown
# Song Title

## Subtitle Line 1
## Subtitle Line 2

![C](https://chordgenerator.net/C.png?p=X32010&s=2) ![G](https://chordgenerator.net/G.png?p=320003&s=2)

**Chorus**

	C           G
	Amazing grace, how sweet the sound
	    Am          F
	That saved a wretch like me

---------------

**Chorus**

	C                    G
	I once was lost, but now I'm found
	    Am            F      C
	Was blind, but now I see

---------------

---------------
```

### Output Elements

* **Title**: Rendered as H1 heading (`# Title`)
* **Subtitles**: Rendered as H2 headings (`## Subtitle`)
* **Chord diagrams**: Embedded images from chordgenerator.net
* **Sections**: Labeled with bold text (`**Chorus**`, `**Verse**`)
* **Song lines**: Chords above lyrics with dashes for alignment
* **Comments**: Rendered as blockquotes (`> Comment text`)
* **Separators**: Horizontal rules (`---------------`)

## Configuration Settings

While the Markdown backend has no dedicated configuration section in the config file, it respects global ChordPro settings.

### Relevant Global Settings

These settings from `settings` section affect Markdown output:

```json
{
  "settings": {
    "lyrics-only": false,
    "suppress-empty-chords": true,
    "inline-chords": false,
    "chords-under": false
  }
}
```

#### Lyrics-Only Mode

Suppress all chords in output:

```json
{
  "settings": {
    "lyrics-only": true
  }
}
```

Or via command line:

```bash
chordpro --generate=Markdown --lyrics-only song.cho -o song.md
```

Result:
```markdown
# Song Title

	Amazing grace, how sweet the sound
	That saved a wretch like me
```

#### Single-Space Mode

Suppress empty chord lines (when a line has no chords):

```json
{
  "settings": {
    "suppress-empty-chords": true
  }
}
```

Command line:

```bash
chordpro --generate=Markdown -a song.cho -o song.md
```

This removes the chord line when there are no chords, making output more compact.

#### Inline Chords

Place chords inline with lyrics instead of above:

```json
{
  "settings": {
    "inline-chords": "[%s]"
  }
}
```

The format string controls how chords appear:
* `[%s]` - Chords in brackets: `[C]Amazing grace`
* `{%s}` - Chords in braces: `{C}Amazing grace`
* `(%s)` - Chords in parentheses: `(C)Amazing grace`
* `**%s** ` - Bold chords: `**C** Amazing grace`

Result with `[%s]`:
```markdown
	[C]Amazing [G]grace, how sweet the sound
	[Am]That saved a [F]wretch like me
```

If set to `true` instead of a format string, defaults to `[%s]`.

#### Chords Under Lyrics

Place chords below lyrics instead of above:

```json
{
  "settings": {
    "chords-under": true
  }
}
```

Result:
```markdown
	Amazing grace, how sweet the sound
	C           G
	That saved a wretch like me
	    Am          F
```

This is less common but useful for some applications.

### Backend Options

Additional options can be passed via `--backend-option`:

#### Tidy Mode

Add extra spacing between songs in songbooks:

```bash
chordpro --generate=Markdown --backend-option=tidy=1 *.cho -o songbook.md
```

This adds blank lines between songs for better readability in multi-song files.

## Output Formatting

### Chord-Lyric Alignment

The Markdown backend uses dashes (`-`) to align chords with lyrics:

```markdown
	C           G
	Amazing grace, how sweet the sound
	    Am          F
	That saved a wretch like me
```

The alignment algorithm:
1. Places chords at syllable boundaries
2. Adds dashes to lyrics where needed to maintain alignment
3. Preserves relative spacing between chords
4. Uses tabs for indentation

### Structural Elements

#### Headings

* Song title: `# Title` (H1)
* Subtitles: `## Subtitle` (H2)
* Section labels: `**Chorus**` (bold text)

#### Sections

**Chorus sections** are marked with bold label and separator:

```markdown
**Chorus**

	[chord lines and lyrics]

---------------
```

**Verse sections** have no explicit label (just content).

**Tab sections** are labeled and indented:

```markdown
**Tabulatur**

	e|--0--1--3--1--0--|
	B|--1--1--1--1--1--|
	G|--0--0--0--0--0--|
```

**Grid sections** are labeled and formatted:

```markdown
**Grid**

	| C    | G    | Am   | F    |
	| C    | G    | C    | C    |
```

#### Comments

Comments are rendered as blockquotes:

```markdown
> This is a comment
```

Italic comments:

```markdown
> *This is an italic comment*
```

Comments with metadata substitution work:

```
{comment: Written by %{composer}}
```

Produces:

```markdown
> Written by John Newton
```

### Images

Images are rendered with Markdown syntax:

```markdown
![Alt text](image.png)
```

ChordPro's `{image: file.png}` directive becomes:

```markdown
![](file.png)
```

### Chord Diagrams

Chord diagrams are automatically generated as embedded images using chordgenerator.net:

```markdown
![C](https://chordgenerator.net/C.png?p=X32010&s=2) ![G](https://chordgenerator.net/G.png?p=320003&s=2)
```

The URL includes:
* Chord name in path
* `p=` parameter with fret positions
* `s=2` parameter for size

To suppress chord diagrams, use lyrics-only mode or remove chords from the song.

### Page Breaks and Separators

* `{new_page}` directive produces: `---------------`
* `{column_break}` produces three blank lines
* Chorus endings produce: `---------------`
* Songs are separated by: `---------------`

## Advanced Features

### Metadata Substitution

Metadata can be used in comments and text via `%{key}` syntax:

ChordPro file:
```
{title: Amazing Grace}
{composer: John Newton}
{comment: Written by %{composer} in %{year|1772}}
```

Markdown output:
```markdown
# Amazing Grace

> Written by John Newton in 1772
```

Available metadata keys:
* `%{title}` - Song title
* `{subtitle}` - First subtitle
* `%{artist}` - Artist name
* `%{composer}` - Composer name
* `%{lyricist}` - Lyricist name
* `%{copyright}` - Copyright notice
* `%{album}` - Album name
* `%{year}` - Year
* `%{key}` - Musical key
* `%{tempo}` - Tempo
* `%{time}` - Time signature
* `%{capo}` - Capo position

### Text Markup

ChordPro's text markup is preserved in Markdown:

* `<span>text</span>` - Plain text
* `<b>bold</b>` - **bold**
* `<i>italic</i>` - *italic*
* `<u>underline</u>` - Underline (not standard Markdown)
* `<sup>super</sup>` - Superscript
* `<sub>sub</sub>` - Subscript

Example ChordPro:
```
{title: <b>Song</b> in <i>Markdown</i>}
```

Markdown output:
```markdown
# **Song** in *Markdown*
```

### Leading Spaces

Lines with leading spaces use non-breaking spaces (U+00A0) to preserve indentation:

ChordPro:
```
    Indented lyric line
```

Markdown preserves the indentation in the output.

### Empty Lines

Empty lines in ChordPro become empty lines in Markdown, with special handling:
* Consecutive empty lines are collapsed to single empty lines
* Empty lines within sections maintain structure
* Extra empty lines can be added with tidy mode

## Workflow Examples

### Example 1: GitHub Wiki

Generate Markdown for GitHub wiki:

```bash
# Generate all songs
for file in songs/*.cho; do
  chordpro --generate=Markdown "$file" -o "wiki/$(basename "$file" .cho).md"
done

# Commit to wiki repository
cd wiki
git add *.md
git commit -m "Update song collection"
git push
```

### Example 2: Hugo Website

Generate songs for Hugo static site:

```bash
# Generate with frontmatter template
for file in *.cho; do
  echo "---" > "content/songs/$(basename "$file" .cho).md"
  echo "title: \"Song Title\"" >> "content/songs/$(basename "$file" .cho).md"
  echo "date: $(date +%Y-%m-%d)" >> "content/songs/$(basename "$file" .cho).md"
  echo "---" >> "content/songs/$(basename "$file" .cho).md"
  chordpro --generate=Markdown "$file" >> "content/songs/$(basename "$file" .cho).md"
done

# Build site
hugo
```

### Example 3: Pandoc Conversion

Convert Markdown to multiple formats:

```bash
# Generate Markdown
chordpro --generate=Markdown song.cho -o song.md

# Convert with Pandoc
pandoc song.md -o song.html        # HTML
pandoc song.md -o song.docx        # Word
pandoc song.md -o song.pdf         # PDF (requires LaTeX)
pandoc song.md -o song.epub        # EPUB ebook
```

### Example 4: Inline Chords for Email

Generate compact inline format for email:

```bash
chordpro --generate=Markdown \
  --backend-option=inline-chords='[%s]' \
  song.cho -o song.md
```

Copy the Markdown content and paste into email.

### Example 5: Songbook with Table of Contents

Generate songbook with TOC:

```bash
# Generate individual songs
for file in *.cho; do
  chordpro --generate=Markdown "$file" -o "md/$(basename "$file" .cho).md"
done

# Create TOC
echo "# Songbook" > songbook.md
echo "" >> songbook.md
echo "## Table of Contents" >> songbook.md
for file in md/*.md; do
  title=$(head -n1 "$file" | sed 's/# //')
  echo "* [$title](#$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'))" >> songbook.md
done
echo "" >> songbook.md

# Append all songs
cat md/*.md >> songbook.md
```

## Integration with Documentation Systems

### Hugo

Place Markdown files in `content/songs/`:

```bash
chordpro --generate=Markdown songs/*.cho -o content/songs/all-songs.md
```

Add Hugo frontmatter manually or via script.

### Jekyll

Generate files with YAML frontmatter:

```bash
cat > _songs/song.md <<EOF
---
layout: song
title: "Song Title"
artist: "Artist Name"
---
EOF

chordpro --generate=Markdown song.cho >> _songs/song.md
```

### MkDocs

Place in `docs/` directory:

```bash
mkdir -p docs/songs
chordpro --generate=Markdown *.cho -o docs/songs/index.md
```

Update `mkdocs.yml`:

```yaml
nav:
  - Home: index.md
  - Songs: songs/index.md
```

### GitBook

Generate in book structure:

```bash
chordpro --generate=Markdown songs/*.cho -o SUMMARY.md
```

### Obsidian / Foam / Zettlr

Generate for personal knowledge management:

```bash
chordpro --generate=Markdown song.cho -o "vault/Songs/Song Title.md"
```

Add wiki-links manually:

```markdown
Related: [[Other Song]] [[Artist Page]]
```

## Viewing Markdown Output

### Command Line Viewers

```bash
# Glow (styled terminal viewer)
glow song.md

# Pandoc to HTML and open
pandoc song.md -o song.html && open song.html

# Markdown viewer
mdless song.md
```

### Editors with Preview

* **VS Code**: Built-in Markdown preview (Ctrl+Shift+V)
* **Atom**: Markdown Preview package
* **Sublime Text**: MarkdownPreview package
* **Vim**: vim-markdown-preview plugin
* **Emacs**: markdown-mode with preview

### Web Browsers

Many Markdown browser extensions:
* Chrome: Markdown Viewer, Markdown Preview Plus
* Firefox: Markdown Viewer Webext
* Safari: Markdown Preview

Or convert to HTML:

```bash
pandoc song.md -s -o song.html
```

## Customization Strategies

### Custom Post-Processing

Edit generated Markdown with scripts:

```bash
# Generate
chordpro --generate=Markdown song.cho -o song.md

# Post-process
sed -i 's/\*\*Chorus\*\*/### Chorus/' song.md  # Change to H3
sed -i 's/^	/    /' song.md  # Convert tabs to 4 spaces
```

### Template Insertion

Wrap output in template:

```bash
cat header.md > final.md
chordpro --generate=Markdown song.cho >> final.md
cat footer.md >> final.md
```

### Combining with Other Formats

Generate multiple formats:

```bash
# Markdown for web
chordpro --generate=Markdown song.cho -o song.md

# PDF for print
chordpro --generate=PDF song.cho -o song.pdf

# LaTeX for editing
chordpro --generate=LaTeX song.cho -o song.tex
```

## Tips and Best Practices

### For Web Publishing

* Use inline chords for better mobile viewing
* Enable tidy mode for multi-song pages
* Add custom CSS for chord styling in HTML
* Consider using lyrics-only mode for text-heavy pages

### For Documentation

* Use descriptive filenames matching song titles
* Keep one song per file for better navigation
* Add metadata in comments for searchability
* Link between related songs with Markdown links

### For Version Control

* One song per file enables better diff viewing
* Use meaningful commit messages for chord changes
* Tag versions for released songbooks
* Use branches for alternate arrangements

### For Conversion

* Keep Markdown clean for best Pandoc results
* Avoid nested structures that don't convert well
* Use standard Markdown syntax when possible
* Test conversions early in workflow

### For Collaboration

* Include metadata in comments for attribution
* Use consistent formatting across songs
* Document any custom conventions
* Consider inline chords for email/chat sharing

## Troubleshooting

### Chords Not Aligning

**Problem**: Chords don't align with syllables in viewer.

**Solution**: Use monospace font in viewer. Most Markdown viewers use variable-width fonts by default, breaking alignment.

Options:
* View in terminal with monospace font
* Use inline-chords mode instead
* Convert to HTML with custom CSS (monospace for chord lines)

### Chord Diagrams Not Showing

**Problem**: Image links broken or not displaying.

**Solution**: 
* Check internet connection (images are external)
* Use alternative chord diagram service
* Generate local chord diagrams and update links
* Disable diagrams with lyrics-only mode

### Extra Blank Lines

**Problem**: Too many blank lines in output.

**Solution**: Use tidy mode or post-process to clean up:

```bash
# Remove multiple consecutive blank lines
sed '/^$/N;/^\n$/D' song.md
```

### Indentation Lost

**Problem**: Leading spaces disappear in viewer.

**Solution**: The backend uses non-breaking spaces which may not display properly in all viewers. Alternative:
* Use blockquotes for indented sections
* Post-process to convert to code blocks

### Special Characters

**Problem**: Unicode characters not displaying.

**Solution**: Ensure file is saved as UTF-8:

```bash
file --mime-encoding song.md  # Check encoding
iconv -f ISO-8859-1 -t UTF-8 song.md -o song-utf8.md  # Convert if needed
```

## Configuration Reference

Markdown backend respects these global configuration settings:

```json
{
  "settings": {
    "lyrics-only": false,
    "suppress-empty-chords": true,
    "suppress-empty-lyrics": true,
    "inline-chords": false,
    "inline-annotations": "%s",
    "chords-under": false,
    "transpose": 0,
    "columns": 1
  }
}
```

Backend-specific options (via command line):
* `--backend-option=tidy=1` - Add extra spacing between songs

## Resources

### Markdown Specifications

* **CommonMark**: [https://commonmark.org/](https://commonmark.org/)
* **GitHub Flavored Markdown**: [https://github.github.com/gfm/](https://github.github.com/gfm/)
* **Markdown Guide**: [https://www.markdownguide.org/](https://www.markdownguide.org/)

### Conversion Tools

* **Pandoc**: [https://pandoc.org/](https://pandoc.org/) - Universal document converter
* **Kramdown**: [https://kramdown.gettalong.org/](https://kramdown.gettalong.org/) - Ruby Markdown processor
* **markdown-it**: [https://markdown-it.github.io/](https://markdown-it.github.io/) - JavaScript parser

### Documentation Systems

* **Hugo**: [https://gohugo.io/](https://gohugo.io/)
* **Jekyll**: [https://jekyllrb.com/](https://jekyllrb.com/)
* **MkDocs**: [https://www.mkdocs.org/](https://www.mkdocs.org/)
* **GitBook**: [https://www.gitbook.com/](https://www.gitbook.com/)
* **Docusaurus**: [https://docusaurus.io/](https://docusaurus.io/)

### Viewers and Editors

* **Glow**: [https://github.com/charmbracelet/glow](https://github.com/charmbracelet/glow) - Terminal viewer
* **Obsidian**: [https://obsidian.md/](https://obsidian.md/) - Knowledge base
* **Typora**: [https://typora.io/](https://typora.io/) - WYSIWYG editor
* **MarkText**: [https://marktext.app/](https://marktext.app/) - Simple editor

## Command Line Reference

```bash
# Basic generation
chordpro --generate=Markdown input.cho -o output.md

# Lyrics only
chordpro --generate=Markdown --lyrics-only input.cho -o output.md
chordpro --generate=Markdown -l input.cho -o output.md

# Single-space mode (suppress empty chord lines)
chordpro --generate=Markdown --single-space input.cho -o output.md
chordpro --generate=Markdown -a input.cho -o output.md

# Inline chords
chordpro --generate=Markdown --define settings.inline-chords='[%s]' input.cho -o output.md

# Chords under lyrics
chordpro --generate=Markdown --define settings.chords-under=true input.cho -o output.md

# Multiple songs (songbook)
chordpro --generate=Markdown song1.cho song2.cho song3.cho -o songbook.md

# With configuration file
chordpro --config=myconfig.json --generate=Markdown songs/*.cho -o output.md

# Tidy mode for songbooks
chordpro --generate=Markdown --backend-option=tidy=1 *.cho -o songbook.md

# Transpose while generating
chordpro --generate=Markdown --transpose=2 input.cho -o output.md

# To stdout (for piping)
chordpro --generate=Markdown input.cho
```

## Conclusion

The Markdown backend provides a versatile, portable output format ideal for web publishing, documentation, and collaboration. While it lacks some of the typographic sophistication of PDF output, its simplicity and compatibility with modern workflows make it invaluable for digital song distribution and online songbooks.

For print-quality output, consider using PDF or LaTeX backends. For web and digital use, Markdown is often the best choice.
