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
| config/\_default/config.yaml | Site confguration |
| config/\_default/menu.yaml | Sidebar menu config |
| contents | The actual documentation files |
| layout | Templates for hugo |

### Maintenance

The `Makefile` provides targets for:

* server  
  run a hugo server for interactive maintenance of the docs
* production  
  generates a static (standalone) site in the `public` directory
* dist  
  updates the ChordPro web site from the `public` directory, provided
  you have access to the site

