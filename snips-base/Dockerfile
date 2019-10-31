ARG BUILD_FROM
FROM $BUILD_FROM AS myBase

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

# Install snips
FROM myBase AS snips

ARG BUILD_ARCH

RUN set -x \
    && if [ "$BUILD_ARCH" = "amd64" ]; then \
        bash -c 'echo "deb https://debian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list' \
        && apt-key adv --fetch-keys https://debian.snips.ai/5FFCD0DEB5BA45CD.pub ; \
    else \
        bash -c 'echo "deb https://raspbian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list' \
        && apt-key adv --fetch-keys https://raspbian.snips.ai/531DD1A7B702B14D.pub ; \
    fi \
    && apt-get update \
    && apt-get install -y \
        snips-platform-voice \
        snips-asr \
        snips-audio-server \
        snips-dialogue \
        snips-hotword \
        snips-injection \
        snips-nlu \
        snips-skill-server \
        snips-template \
        snips-tts \
        snips-watch \
    && apt-get -y autoremove \
    && usermod -aG snips-skills-admin root

# Build mimic from Mycroft
FROM myBase AS mimic

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        pkg-config \
        automake \
        libtool \
        libicu-dev \
        libpcre2-dev \
        libasound2-dev
WORKDIR /tmp
RUN set -x && git clone https://github.com/MycroftAI/mimic.git
WORKDIR /tmp/mimic
RUN set -x \
    && ./autogen.sh \
    && ./configure --prefix=/usr/local \
    && make \
    && make check \
    && make install
WORKDIR /

FROM snips AS addon

RUN set -x \
    && mkdir -p \
        /ingress/templates \
        /ingress/static \
        /EXTRA-LICENSES \
    && pip3 install \
        flask \
        requests \
        ruamel.yaml \
        cheroot

COPY --from=mimic /usr/local/bin/* /usr/local/bin/

COPY ingress/*.py /ingress/
COPY ingress/templates/* /ingress/templates/
COPY ingress/static/* /ingress/static/

COPY funcs.sh \
    extract_assistant.sh \
    manage_tts_cache.sh \
    restart_snips_skill_server.sh \
    run.sh \
    setup.sh \
    start_service.sh \
    start_snips_watch.sh \
    stop_snips_watch.sh \
    update_ha_config.py \
    wait-for-it.sh \
    /
COPY LICENSE EXTRA-LICENSES/* /EXTRA-LICENSES/
COPY tts-unparsed.sh /tts/

RUN set -x \
    && rm -rf /etc/supervisor \
    && mkdir /etc/supervisor \
    && chmod 755 \
        /extract_assistant.sh \
        /manage_tts_cache.sh \
        /restart_snips_skill_server.sh \
        /run.sh \
        /start_service.sh \
        /start_snips_watch.sh \
        /stop_snips_watch.sh \
        /update_ha_config.py \
        /wait-for-it.sh \
        /ingress/ \
        /ingress/static/ \
        /ingress/templates/ \
        /ingress/control.py \
        /etc/supervisor/ \
        /tts/ \
    && chmod 644 \
        /funcs.sh \
        /ingress/static/* \
        /ingress/templates/* \
        /setup.sh \
        /tts/tts-unparsed.sh

ENTRYPOINT [ "/run.sh" ]
