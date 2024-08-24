# syntax=docker/dockerfile:1
FROM debian:stable-slim AS base

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=en_US.UTF-8

# Install perl and runtime packages.
# We have a libpdf-api2-perl but that's not recent enough.
RUN apt-get update && apt-get upgrade \
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
    libpdf-api2-perl \
    libobject-pad-perl \
    libimage-info-perl \
    libjson-pp-perl \
    libjson-xs-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Perl modules from CPAN.
RUN cpanm \
    Pod::Usage \
    JavaScript::QuickJS \
    File::LoadLines \
    String::Interpolate::Named \
    HarfBuzz::Shaper \
    Text::Layout~0.038 \
    Data::Printer

FROM base AS chordpro-prod
RUN cpanm chordpro

# Cleanup.
RUN rm -fr .cpanminus

# Setup for run-time
ENV DOCKER_PACKAGED=1.00
RUN chordpro --about

FROM base AS chordpro-dev
COPY chordpro-dev.tar.gz ./
RUN mkdir ChordPro \
  && tar xf chordpro-dev.tar.gz -C ChordPro \
  && cd ChordPro \
  && perl Makefile.PL \
  && make && make install

# Cleanup.
RUN rm -fr .cpanminus

# Setup for run-time
ENV DOCKER_PACKAGED=1.00
RUN chordpro --about
