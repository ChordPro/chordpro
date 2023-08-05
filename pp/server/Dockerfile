#! /bin/docker -f

FROM perl:latest AS base

# Standard perl modules.
RUN cpanm \
    XML::LibXML \
    File::HomeDir \
    PDF::API2 \
    Image::Info \
    Object::Pad \
    Capture::Tiny \
    Dancer2

# Add dependencies from CPAN for newest versions.
RUN cpanm \
    App::Packager \
    File::LoadLines \
    String::Interpolate::Named \
    HarfBuzz::Shaper \
    Text::Layout

# Add abc2svg.
COPY abc2svg/abc2svg.tar.gz .
RUN tar zxvf abc2svg.tar.gz -C /usr/local/ && \
    rm abc2svg.tar.gz && \
    ln -s ../lib/abc2svg/abcqjs /usr/local/bin/abc2svg

# Add chordpro, pdfsvg and clean up.
COPY chordpro.tar.gz pdfsvg.tar.gz /tmp/
RUN cd /tmp && \
    mkdir chordpro && cd chordpro && \
    tar xf ../chordpro.tar.gz && \
    perl Makefile.PL && make && make install && \
    cd .. && rm -fr chordpro.tar.gz chordpro && \
    mkdir pdfsvg && cd pdfsvg && \
    tar xf ../pdfsvg.tar.gz && \
    perl Makefile.PL && make && make install && \
    cd .. && rm -fr pdfsvg.tar.gz pdfsvg 

# Copy into a slim image for reduced size.
FROM perl:slim AS prod
COPY --from=base /usr/local/lib /usr/local/lib
COPY --from=base /usr/local/bin /usr/local/bin

# Setup for run-time.
ENV DOCKER_PACKAGED=1.00
RUN chordpro --about
COPY dancer dancer

# Default listen to all, port 5000.
EXPOSE 5000
ENTRYPOINT plackup dancer/chordpro-server.pl

