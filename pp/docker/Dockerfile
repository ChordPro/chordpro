# syntax=docker/dockerfile:1
FROM debian:stable-slim AS base

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=en_US.UTF-8

# Install perl and runtime packages.
# We have a libpdf-api2-perl but that's not recent enough.
RUN apt-get update \
    && apt-get install -y \
	  build-essential \
          perl \
	  libwx-perl \
	  mupdf \
          cpanminus

# Install perl modules and clean up.
RUN apt-get install --no-install-recommends -y \
    libxml-perl \
    libfile-homedir-perl \
    libfont-ttf-perl \
    libimage-info-perl \
    abcm2ps \
    imagemagick \
    librsvg2-bin \
    libimage-magick-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Perl modules from CPAN.
RUN cpanm \
    PDF::API2 \
    File::LoadLines \
    String::Interpolate::Named \
    HarfBuzz::Shaper \
    Text::Layout

FROM base

# Augmented version of App::Packeger.
RUN cpanm App::Packager
COPY CPAN/App/Packager.pm Packager.pm
RUN perl -MConfig -e 'print "mv Packager.pm $Config{sitelib}/App/Packager.pm\n"' | bash -x

# Add ChordPro
RUN cpanm chordpro

# Cleanup.
RUN rm -fr .cpanminus

# Setup for run-time
ENV DOCKER_PACKAGED=1.00
RUN chordpro --about
