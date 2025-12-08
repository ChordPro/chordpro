# HTML5Paged Backend: PDF Configuration Implementation Plan

## Executive Summary

This document outlines a comprehensive plan to implement PDF-style configuration options in the HTML5Paged backend. The goal is to enable users to control page layout, margins, headers, footers, fonts, and styling through configuration files, similar to how the PDF backend works.

---

## 1. Configuration Categories

### 1.1 Page Setup & Layout

#### Current PDF Configuration:
```json
pdf {
  papersize: "a4"              // or [595, 842] in pt
  margintop: 80                // pt, excluding headspace
  marginbottom: 40             // pt, excluding footspace
  marginleft: 40               // pt
  marginright: 40              // pt
  headspace: 60                // pt for page titles
  footspace: 20                // pt for page footers
  columnspace: 20              // pt between columns
  head-first-only: false       // header on first page only
}
```

#### HTML5Paged Implementation Strategy:

**Priority: HIGH**

1. **Add config section** `html5.paged { }` or reuse `pdf { }` settings
2. **Map to CSS @page rules**:
   - `papersize` → `@page { size: A4 }` or custom dimensions
   - Margins → `@page { margin: 15mm 20mm }`
   - Support both pt and mm units (convert as needed)

3. **Implementation approach**:
   ```perl
   # In HTML5Paged.pm generate_paged_css()
   my $ps = $config->{html5}->{paged} // $config->{pdf};
   my $papersize = $ps->{papersize} // 'a4';
   my $margins = format_margins($ps);
   
   return qq{
     @page {
       size: $papersize;
       margin: $margins;
     }
   };
   ```

4. **Paper size mapping**:
   - Support named sizes: a4, letter, legal, a3, a5, b5
   - Support array format: [width, height] in pt
   - Convert pt to mm for CSS (1pt = 0.352778mm)

---

### 1.2 Spacing & Typography

#### Current PDF Configuration:
```json
spacing {
  title: 1.2           // baseline factor for titles
  lyrics: 1.2          // spacing between songlines
  chords: 1.2          // spacing between chords and lyrics
  diagramchords: 1.2   // spacing in chord diagrams
  grid: 1.2            // spacing for grid lines
  tab: 1              // spacing for tab lines
  toc: 1.4            // spacing for table of contents
  empty: 1            // spacing for blank lines
}
```

#### HTML5Paged Implementation Strategy:

**Priority: MEDIUM**

1. **Map to CSS line-height and margins**:
   ```css
   --cp-spacing-title: 1.2;
   --cp-spacing-lyrics: 1.2;
   --cp-spacing-chords: 1.2;
   
   .cp-title { line-height: var(--cp-spacing-title); }
   .cp-songline { margin-bottom: calc(var(--cp-size-text) * (var(--cp-spacing-lyrics) - 1)); }
   ```

2. **Implementation**:
   - Read spacing config in `generate_paged_css()`
   - Generate CSS variables for each spacing type
   - Apply to respective CSS classes

---

### 1.3 Page Headers & Footers (Formats)

#### Current PDF Configuration:
```json
formats {
  default {
    title: ["" "" ""]           // left, center, right
    subtitle: ["" "" ""]
    footer: ["%{title}" "" "%{page}"]
    background: ""
  }
  title {                       // First page of song
    title: ["" "%{title}" ""]
    subtitle: ["" "%{subtitle}" ""]
    footer: ["" "" "%{page}"]
  }
  first {                       // Very first page
    footer: false
  }
  filler {                      // Alignment pages
    title: false
    subtitle: false
    footer: false
  }
}
```

#### HTML5Paged Implementation Strategy:

**Priority: HIGH**

1. **Use @page named pages and margin boxes**:
   ```css
   @page default {
     @top-center { content: ""; }
     @bottom-left { content: string(song-title); }
     @bottom-right { content: counter(page); }
   }
   
   @page title {
     @top-center { content: string(song-title); }
     @bottom-center { content: counter(page); }
   }
   
   @page :first {
     @bottom-center { content: none; }
   }
   ```

2. **Metadata substitution**:
   - Parse format strings: `%{title}`, `%{subtitle}`, `%{page}`, `%{artist}`
   - Use CSS `string-set` for song metadata
   - Use `counter(page)` for page numbers
   - Inject metadata via data attributes or CSS variables

3. **Implementation challenges**:
   - CSS margin boxes have limited dynamic content support
   - May need JavaScript helper to inject metadata
   - Or: generate CSS per song with literal values

4. **Recommended approach**:
   ```perl
   # Generate page-specific CSS rules
   sub generate_format_css {
       my ($self, $format_config) = @_;
       my $css = '';
       
       # Parse title format
       my ($left, $center, $right) = @{$format_config->{title}};
       $css .= format_page_margin('@top-left', $left);
       $css .= format_page_margin('@top-center', $center);
       $css .= format_page_margin('@top-right', $right);
       
       # Similar for footer
       return $css;
   }
   ```

---

### 1.4 Dual Pages & Song Alignment

#### Current PDF Configuration:
```json
songbook {
  dual-pages: true              // Different odd/even pages
  align-songs: true             // Songs start on right pages
  align-songs-spread: false     // Songs start on left pages
  align-songs-extend: false     // Filler pages have headers
  align-tocs: true              // Align tables of contents
  sort-songs: false             // Sort by title/subtitle
  compact-songs: false          // Minimize page turns
  cover: false                  // PDF cover page
  front-matter: false           // PDF front matter
  back-matter: false            // PDF back matter
}
```

#### HTML5Paged Implementation Strategy:

**Priority: MEDIUM-LOW**

1. **Dual pages with :left and :right**:
   ```css
   @page :left {
     margin: 15mm 25mm 15mm 20mm;  /* Swap margins */
     @top-left { content: counter(page); }
     @top-right { content: string(song-title); }
   }
   
   @page :right {
     margin: 15mm 20mm 15mm 25mm;
     @top-left { content: string(song-title); }
     @top-right { content: counter(page); }
   }
   ```

2. **Song alignment**:
   - Use `page: song` on `.cp-song` elements
   - Add `page-break-before: right` for `align-songs: true`
   - Add `page-break-before: left` for `align-songs-spread: true`
   ```css
   .cp-song {
     page-break-before: right;  /* When align-songs: true */
   }
   ```

3. **Implementation note**:
   - CSS paged media has limited "filler page" support
   - May need JavaScript post-processing
   - Or generate blank pages in HTML

---

### 1.5 Fonts

#### Current PDF Configuration:
```json
fonts {
  title: {
    description: "serif bold 14"
    color: "black"
    background: ""
  }
  text: {
    description: "serif 12"
    color: "black"
  }
  chord: {
    description: "sans italic 10"
    color: "blue"
  }
  comment: {
    description: "sans 12"
    color: "grey70"
  }
  // ... many more
}
```

#### HTML5Paged Implementation Strategy:

**Priority: HIGH**

1. **Parse font descriptions**:
   - Format: `"family [style] [weight] size"`
   - Extract family, style, weight, size
   - Map to CSS font properties

2. **Generate CSS variables and classes**:
   ```css
   :root {
     --cp-font-title: "Georgia", serif;
     --cp-font-title-size: 14pt;
     --cp-font-title-weight: bold;
     --cp-color-title: black;
   }
   
   .cp-title {
     font-family: var(--cp-font-title);
     font-size: var(--cp-font-title-size);
     font-weight: var(--cp-font-title-weight);
     color: var(--cp-color-title);
   }
   ```

3. **Font family mapping**:
   - `serif` → `"Georgia", "Times New Roman", serif`
   - `sans` / `sans-serif` → `"Arial", "Helvetica", sans-serif`
   - `mono` / `monospace` → `"Courier New", monospace`
   - Custom fonts: use `@font-face` if TTF/OTF provided

4. **Implementation**:
   ```perl
   sub parse_font_description {
       my ($desc) = @_;
       # Parse "serif bold 14" → {family, style, weight, size}
       my @parts = split /\s+/, $desc;
       my $size = pop @parts if $parts[-1] =~ /^\d+/;
       my %font = (size => $size);
       # ... parse family, weight, style
       return \%font;
   }
   ```

---

### 1.6 Theme & Colors

#### Current PDF Configuration:
```json
theme {
  foreground: "black"
  foreground-medium: "grey70"
  foreground-light: "grey90"
  background: "none"
}
```

#### HTML5Paged Implementation Strategy:

**Priority: MEDIUM**

1. **Map to CSS variables**:
   ```css
   :root {
     --cp-color-foreground: black;
     --cp-color-foreground-medium: #b3b3b3;  /* grey70 */
     --cp-color-foreground-light: #e6e6e6;   /* grey90 */
     --cp-color-background: white;
   }
   ```

2. **Color name resolution**:
   - Support named colors: black, white, red, blue, etc.
   - Support hex: #RRGGBB
   - Support grey percentages: grey70 → #b3b3b3
   - Support RGB: rgb(r,g,b)

---

### 1.7 Chorus, Labels, Comments

#### Current PDF Configuration:
```json
chorus {
  indent: 0
  bar {
    offset: 8
    width: 1
    color: "foreground"
  }
  tag: "Chorus"
}

labels {
  width: "auto"
  align: "left"
  comment: ""
}
```

#### HTML5Paged Implementation Strategy:

**Priority: LOW-MEDIUM**

1. **Chorus styling**:
   ```css
   .cp-chorus {
     padding-left: 1em;
     border-left: 3px solid var(--cp-color-chorus-border);
   }
   ```

2. **Labels**:
   - Use `::before` pseudo-element for labels
   - Position with negative margin or absolute positioning
   ```css
   .cp-verse[data-label]::before {
     content: attr(data-label);
     position: absolute;
     left: -80px;
     width: 70px;
   }
   ```

---

### 1.8 Chord Diagrams & Grids

#### Current PDF Configuration:
```json
diagrams {
  show: "bottom"        // top, bottom, right, below
  align: "left"         // left, right, center, spread
  width: 6
  height: 6
  vcells: 4
  // ... many more
}

grids {
  cellbar { width: 0 }
  show: true
  symbols.color: "blue"
}
```

#### HTML5Paged Implementation Strategy:

**Priority: LOW**

1. **SVG-based diagrams**:
   - Generate SVG chord diagrams in HTML
   - Position with flexbox or CSS grid
   - Style via CSS

2. **Not critical for MVP** - can be added later

---

## 2. Implementation Phases

### Phase 1: Core Page Layout (MVP) ✅
**Status: COMPLETE**

- [x] Basic paged.js integration
- [x] Fixed @page rules (A4, margins)
- [x] Running headers with song titles
- [x] Page numbers in footer
- [x] Screen preview mode

### Phase 2: Configurable Page Setup
**Priority: HIGH | Estimated: 3-4 hours**

- [ ] Add config section: `html5.paged` or reuse `pdf`
- [ ] Parse papersize config (named + array format)
- [ ] Parse margin config (all 6 values)
- [ ] Generate dynamic @page rules from config
- [ ] Unit conversion (pt ↔ mm)
- [ ] Test with various paper sizes

### Phase 3: Headers & Footers Configuration
**Priority: HIGH | Estimated: 4-5 hours**

- [ ] Parse formats.default/title/first/filler config
- [ ] Generate @page margin-box rules dynamically
- [ ] Implement metadata substitution (%{title}, %{page})
- [ ] Support three-part format (left, center, right)
- [ ] Handle even/odd page differences
- [ ] Test with complex format strings

### Phase 4: Font Configuration
**Priority: HIGH | Estimated: 2-3 hours**

- [ ] Parse font descriptions from config
- [ ] Font family mapping (serif, sans, mono)
- [ ] Generate CSS variables for all fonts
- [ ] Color parsing and CSS generation
- [ ] Font size/weight/style extraction
- [ ] Test with various font configs

### Phase 5: Spacing Configuration
**Priority: MEDIUM | Estimated: 2 hours**

- [ ] Parse spacing config
- [ ] Generate CSS variables for spacing
- [ ] Apply to line-height and margins
- [ ] Test visual output

### Phase 6: Theme & Colors
**Priority: MEDIUM | Estimated: 1-2 hours**

- [ ] Parse theme colors
- [ ] Color name resolution (grey70, etc.)
- [ ] Generate CSS color variables
- [ ] Apply throughout stylesheet

### Phase 7: Dual Pages & Alignment
**Priority: MEDIUM-LOW | Estimated: 3-4 hours**

- [ ] Implement :left and :right page rules
- [ ] Song alignment (page-break-before)
- [ ] Margin swapping for odd/even pages
- [ ] Header/footer swapping
- [ ] Test with dual-page settings

### Phase 8: Advanced Features
**Priority: LOW | Estimated: variable**

- [ ] Chorus bar styling from config
- [ ] Label positioning
- [ ] Chord diagram configuration
- [ ] Grid styling
- [ ] Background images

---

## 3. Configuration File Structure

### Proposed: Shared PDF Configuration

**Recommended approach**: Reuse existing `pdf` config section for HTML5Paged backend.

**Rationale**:
- Users already familiar with PDF config
- Single source of truth for page layout
- Easier migration PDF → HTML5Paged
- Less configuration duplication

**Override mechanism**:
```json
{
  "pdf": {
    "papersize": "a4",
    "margintop": 80,
    // ... standard settings
  },
  "html5": {
    "paged": {
      // HTML5-specific overrides
      "papersize": "letter",  // Override for HTML5 only
      "preview-mode": true    // HTML5-specific setting
    }
  }
}
```

**Config resolution order**:
1. Check `html5.paged.{setting}`
2. Fall back to `pdf.{setting}`
3. Fall back to built-in default

---

## 4. Technical Challenges & Solutions

### Challenge 1: CSS @page Margin Box Limitations

**Problem**: CSS margin boxes (`@top-center`, etc.) have limited support for dynamic content.

**Solutions**:
- **Option A**: Generate literal CSS per song (more CSS, but works)
- **Option B**: Use JavaScript to inject metadata (requires paged.js hooks)
- **Option C**: Use CSS `string-set` with HTML data attributes (recommended)

**Recommended**:
```html
<h1 class="cp-title" data-title="Song Name">Song Name</h1>
<style>
.cp-title { string-set: song-title attr(data-title); }
@page song {
  @top-center { content: string(song-title); }
}
</style>
```

### Challenge 2: Filler Pages

**Problem**: CSS can't insert blank pages automatically for alignment.

**Solutions**:
- **Option A**: Generate blank pages in HTML during songbook generation
- **Option B**: Use JavaScript post-processing with paged.js hooks
- **Option C**: Document limitation and skip feature

**Recommended**: Option C for MVP, Option A for future enhancement

### Challenge 3: Font Loading

**Problem**: Custom fonts (TTF/OTF) need to be loaded in browser.

**Solutions**:
- **Option A**: Use `@font-face` with URL to font file
- **Option B**: Embed base64-encoded fonts in CSS
- **Option C**: Rely on system fonts only (MVP)

**Recommended**: Option C for MVP, Option A for Phase 8

### Challenge 4: Unit Conversion

**Problem**: PDF uses pt (points), CSS paged media prefers mm/cm/in.

**Solution**: Implement conversion utilities
```perl
sub pt_to_mm {
    my ($pt) = @_;
    return $pt * 0.352778;  # 1pt = 0.352778mm
}

sub format_css_size {
    my ($value, $unit) = @_;
    return "${value}${unit}" if $unit;
    return pt_to_mm($value) . "mm";  # Default to mm
}
```

---

## 5. Testing Strategy

### Unit Tests
- [ ] Config parsing tests
- [ ] Font description parsing
- [ ] Color name resolution
- [ ] Unit conversion
- [ ] Format string substitution

### Integration Tests
- [ ] Generate with various paper sizes
- [ ] Generate with different margins
- [ ] Generate with custom fonts
- [ ] Generate with dual-page settings
- [ ] Generate with complex headers/footers

### Visual Tests
- [ ] Compare PDF vs HTML5Paged output
- [ ] Print preview testing
- [ ] PDF generation from browser
- [ ] Multi-song alignment
- [ ] Page number verification

---

## 6. Documentation Plan

### User Documentation
- [ ] Configuration reference (similar to PDF docs)
- [ ] Migration guide (PDF → HTML5Paged)
- [ ] Examples gallery
- [ ] Troubleshooting guide

### Developer Documentation
- [ ] Architecture overview
- [ ] Config parsing implementation
- [ ] CSS generation strategy
- [ ] Extension points for custom features

---

## 7. Compatibility Matrix

| Feature | PDF Backend | HTML5Paged MVP | Phase 2+ | Notes |
|---------|-------------|----------------|----------|-------|
| Paper size | ✅ | ✅ Fixed | ✅ Config | |
| Margins | ✅ | ✅ Fixed | ✅ Config | |
| Headers/Footers | ✅ | ✅ Basic | ✅ Full | Limited metadata |
| Fonts | ✅ | ✅ Fixed | ✅ Config | System fonts only |
| Spacing | ✅ | ✅ Fixed | ✅ Config | |
| Dual pages | ✅ | ❌ | ✅ | Phase 7 |
| Song alignment | ✅ | ❌ | ⚠️ Limited | No auto filler pages |
| Chord diagrams | ✅ | ❌ | ⚠️ Limited | Phase 8 |
| Custom backgrounds | ✅ | ❌ | ❌ | CSS limitation |
| Outlines/Bookmarks | ✅ | ❌ | ❌ | PDF-specific |
| Page reordering | ✅ | ❌ | ⚠️ Possible | Needs Perl logic |

---

## 8. Next Steps

### Immediate (Phase 2)
1. Add config parameter support to `HTML5Paged->new()`
2. Implement `parse_config()` method
3. Make `generate_paged_css()` read from config
4. Test with sample config files

### Short-term (Phase 3-4)
1. Implement format string parser
2. Add font description parser
3. Generate dynamic CSS from config
4. Update test suite

### Long-term (Phase 5-7)
1. Implement spacing configuration
2. Add dual-page support
3. Implement song alignment
4. Full feature parity with PDF backend (where possible)

---

## 9. Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| CSS @page limitations | HIGH | MEDIUM | Document limitations, use workarounds |
| Browser compatibility | MEDIUM | LOW | Test with major browsers, document requirements |
| Font loading issues | MEDIUM | MEDIUM | Stick to system fonts for MVP |
| Performance (large books) | LOW | LOW | Optimize CSS generation, lazy loading |
| Config complexity | MEDIUM | HIGH | Good defaults, clear documentation |

---

## 10. Success Criteria

### Phase 2 Success Criteria
- [ ] Can set paper size via config
- [ ] Can set all 6 margin values via config
- [ ] Output matches config settings visually
- [ ] Tests pass for config parsing

### Overall Success Criteria
- [ ] 80% feature parity with PDF backend
- [ ] Users can generate print-ready HTML/PDF
- [ ] Configuration is intuitive and well-documented
- [ ] No major browser compatibility issues
- [ ] Performance is acceptable (< 5s for 50-song book)

---

## Appendix A: Example Configuration

```json
{
  "html5": {
    "paged": {
      "papersize": "a4",
      "margintop": 80,
      "marginbottom": 40,
      "marginleft": 40,
      "marginright": 40,
      "headspace": 60,
      "footspace": 20,
      
      "spacing": {
        "title": 1.2,
        "lyrics": 1.2,
        "chords": 1.2
      },
      
      "fonts": {
        "title": {
          "description": "sans-serif bold 18",
          "color": "#333"
        },
        "text": {
          "description": "serif 11",
          "color": "black"
        },
        "chord": {
          "description": "sans-serif bold 9",
          "color": "#0066cc"
        }
      },
      
      "formats": {
        "default": {
          "footer": ["%{title}", "", "%{page}"]
        },
        "title": {
          "title": ["", "%{title}", ""],
          "subtitle": ["", "%{subtitle}", ""],
          "footer": ["", "", "%{page}"]
        }
      }
    }
  }
}
```

---

## Appendix B: References

- **Paged.js Documentation**: https://pagedjs.org/documentation/
- **CSS Paged Media Spec**: https://www.w3.org/TR/css-page-3/
- **ChordPro PDF Config**: `/workspace/docs/content/ChordPro-Configuration-PDF.md`
- **ChordPro Default Config**: `/workspace/lib/ChordPro/res/config/chordpro.json`

---

**Document Version**: 1.0  
**Last Updated**: 2025-12-08  
**Author**: GitHub Copilot  
**Status**: Planning Phase
