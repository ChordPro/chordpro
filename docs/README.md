# The ChordPro documentation

Here you can find all the ChordPro documentation for the current
stable version.

The documentation is in the form of a web site and can be generated
using the [hugo](https://www.gohugo.io) framework for building
websites.

### Directory structure

| Item | Description |
| ---- | ----------- |
| assets | Static files, like images and style sheets |
| config/\_default/config.yaml | Site configuration |
| config/\_default/menu.yaml | Sidebar menu config |
| contents | The actual documentation files |
| layout | Templates for hugo |

### Maintenance

The `Makefile` provides targets for:

* server  
  run a hugo server for interactive maintenance of the docs
* production  
  generates a static (standalone) site in the `public` directory
* publish  
  updates the ChordPro web site from the `public` directory, provided
  you have access to the site

### The home page

The home page (`content/Landing.md`, layout `layouts/landing/baseof.html`)
keeps all of its words in the front matter of `Landing.md`, so it can be
edited without touching a template. Lines with chords are written the
ChordPro way, `[D]Brackets [G]lift your [A7]chords over the [D]words`, and
the `leadline` partial sets them with each chord over its syllable. The
sheet images in `assets/images/home/` are rendered by ChordPro itself from
`lib/ChordPro/res/examples/` on A5 paper.

The site uses two typefaces from Collletttivo under the SIL Open Font
License, Apfel Grotezk and Necto Mono, self-hosted in `static/fonts/` with
their licences. The hero video in `static/video/` is a free Pexels clip
(video 4553896 by Pavel Danilyuk). There are no script libraries on the home
page: the scroll scenes are `position: sticky` plus `assets/js/home.js`, and
all of it is switched off for readers who ask for reduced motion.

