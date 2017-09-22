#
# Amsterdam (SELKS) in Docker.
# We need access to the host's Docker socket, so run the container like so:
#
#     - docker run --privileged -v /var/run/docker.sock:/var/run/docker.sock monokal/amsterdam:latest
#

FROM python:2-alpine

# The system timezone to configure.
ENV TIMEZONE 'Europe/London'

# Alpine packages to install.
ENV APK_PACKAGES \
    alpine-sdk \
    libffi-dev \
    openssl-dev \
    tzdata \
    git \
    bash

# PyPI packages to install.
ENV PIP_PACKAGES \
    docker \
    docker-compose \
    six \
    cryptography \
    pyopenssl

# Install the above packages.
RUN apk --no-cache add $APK_PACKAGES
RUN pip install $PIP_PACKAGES

# Configure the system time.
RUN apk add tzdata && \
    cp "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime && \
    echo $TIMEZONE > /etc/timezone && \
    apk del tzdata

# Copy in repo content.
COPY . /opt/Amsterdam/

# Build, install & initialise Amsterdam.
WORKDIR /opt/Amsterdam/
RUN mkdir data && sudo python setup.py install

RUN echo $'#!/bin/bash\n\
set -e\n\
amsterdam -d data -i eth0 setup\n\
amsterdam -d data start' > entrypoint.sh && \
    chmod +x entrypoint.sh

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
