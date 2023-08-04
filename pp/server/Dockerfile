#! /bin/docker -f

FROM perl:latest AS base

# Standard perl modules.
RUN cpanm \
    XML::LibXML \
    File::HomeDir \
    PDF::API2 \
    Image::Info \
    Object::Pad \
    Dancer2

# Add dependencies from CPAN for newest versions.
RUN cpanm \
    App::Packager \
    File::LoadLines \
    String::Interpolate::Named \
    HarfBuzz::Shaper \
    Text::Layout

# Add chordpro and clean up.
RUN cpanm chordpro

# Not needed, we're going to copy into a perl:slim image.
# RUN apt-get remove --purge -y curl make gcc && \
#     apt-get autoremove -y && \
#     apt-get clean && \
#     apt-get autoclean && \
#     echo -n > /var/lib/apt/extended_states && \
#     rm -rf /var/lib/apt/lists/* && \
#     rm -rf /usr/share/man/?? && \
#     rm -rf /usr/share/man/??_* && \
#     rm -rf ~/.cpanm/* ~/.cpanminus/*

# Copy into a slim image for reduced size.
FROM perl:slim AS prod
COPY --from=base /usr/local/lib /usr/local/lib
COPY --from=base /usr/local/bin /usr/local/bin

# Setup for run-time.
ENV DOCKER_PACKAGED=1.00
RUN chordpro --about
COPY scripts/chordpro-server.pl .

# Default listen to all, port 5000.
EXPOSE 5000
ENTRYPOINT plackup chordpro-server.pl

