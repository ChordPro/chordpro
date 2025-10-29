# Building AppImages.

These are adapted files to build a statically linked appimage.

## Ubuntu 22.04 LTS

See https://discourse.appimage.org/t/specify-required-glibc-version-in-appimage/2413/5.

Currently the as-old-as-possible-but-still-supported Ubuntu LTS system
is 22.04.

For 22.04 we'll use an unofficial wxWidgets 3.2.4 build, kindly
provided by the CodeLite team.

https://docs.codelite.org/wxWidgets/repo32/

22.04 uses webkit2gtk 4.0, which is not compatible with 4.1.

Many older Linux distro's use 4.0.

## Ubuntu 24.04 LTS

For 24.04 we'll use the official 3.2.4 build.

24.04 uses webkit2gtk 4.1, which is not compatible with 4.0.

Many more modern Linux distro's use 4.1; some provide both 4.0 and 4.1. 
