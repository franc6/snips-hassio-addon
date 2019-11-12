ARG BUILD_FROM
FROM $BUILD_FROM AS myBase
COPY qemu-arm-static /usr/bin/

ARG BUILD_ARCH

ENV LANG C.UTF-8

# Update system and install dependencies
RUN set -x \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
        dirmngr \
        locales \
        apt-utils \
        apt-transport-https \
    && sed -i -e 's/# de_\(..\)\.UTF-8 UTF-8/de_\1.UTF-8 UTF-8/' \
           -e 's/# en_\(..\)\.UTF-8 UTF-8/en_\1.UTF-8 UTF-8/' \
           -e 's/# fr_\(..\)\.UTF-8 UTF-8/fr_\1.UTF-8 UTF-8/' \
           -e 's/# it_\(..\)\.UTF-8 UTF-8/it_\1.UTF-8 UTF-8/' \
           -e 's/# ja_\(..\)\.UTF-8 UTF-8/ja_\1.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale \
    && apt-get update \
    && apt-get install -y \
        alsa-utils \
        curl \
        git \
        libttspico-utils \
        mosquitto \
        mosquitto-clients \
        mpg123 \
        python-pip \
        python-virtualenv \
        python3-pip \
        python3-venv \
        python3-setuptools \
        python3-virtualenv \
        unzip \
        ffmpeg \
        supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && pip install virtualenv

