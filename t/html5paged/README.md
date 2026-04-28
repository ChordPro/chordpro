# HTML5 Paged Mode Test Suite

This directory contains unit tests for the HTML5 output backend with paged mode (print/pagination features).

## Test Files

- **01_base.t** - Basic HTML5 paged functionality
  - Object creation and configuration
  - Method availability
  - Song generation

- **02_headers_footers.t** - Phase 3: Headers & Footers Configuration
  - `_format_content_string()` - Metadata substitution (%{title}, %{page}, etc.)
  - `_generate_margin_boxes()` - Three-part format arrays
  - `_generate_format_rule()` - @page CSS rule generation
  - First page vs default page formats

- **03_integration.t** - Full document integration
  - Complete headers/footers rendering
  - @page rules in output
  - String-set for running headers
  - Verse/chorus containers in paged output
  - Markup support in paged context

## Running Tests

Run all paged mode tests:
```bash
perl -Ilib t/html5paged/*.t
```

Run specific test:
```bash
perl -Ilib t/html5paged/02_headers_footers.t
```

## Test Coverage

### Phase 3: Headers & Footers Configuration
- ✅ Metadata substitution (%{title}, %{page}, %{artist}, %{subtitle})
- ✅ Three-part format arrays (left, center, right)
- ✅ @page rule generation (first, default)
- ✅ Margin box positioning (@top-left, @top-center, @top-right, etc.)
- ✅ Content string formatting with counter() and string()
- ✅ Empty format part handling

### Integration Features
- ✅ Full document with headers/footers
- ✅ Verse/chorus container rendering
- ✅ Markup support in paged output
- ✅ CSS string-set for running headers

## Configuration

Tests use custom config with pdf.formats section:

```perl
{
    pdf => {
        formats => {
            'first' => {
                'header' => [['%{title}', 'Center', 'Page %{page}']],
                'footer' => [['', 'Footer Text', '']],
            },
            'default' => {
                'header' => [['%{title}', '', '%{page}']],
                'footer' => [['', '%{subtitle}', '']],
            },
        },
    },
}
```

## Related Documentation

- Phase 3 Implementation: `/workspace/Design/HTML5Paged-PDF-Config-Implementation.md`
- Paged.js Documentation: https://pagedjs.org/documentation/
