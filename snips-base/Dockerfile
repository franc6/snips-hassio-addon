ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH

ENV LANG C.UTF-8

# Update system and install dependencies and the snips repository
RUN set -x \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
        dirmngr \
        locales \
        apt-utils \
        apt-transport-https

RUN set -x \
    && sed -i -e 's/# de_\(..\)\.UTF-8 UTF-8/de_\1.UTF-8 UTF-8/' \
           -e 's/# en_\(..\)\.UTF-8 UTF-8/en_\1.UTF-8 UTF-8/' \
           -e 's/# fr_\(..\)\.UTF-8 UTF-8/fr_\1.UTF-8 UTF-8/' \
           -e 's/# it_\(..\)\.UTF-8 UTF-8/it_\1.UTF-8 UTF-8/' \
           -e 's/# ja_\(..\)\.UTF-8 UTF-8/ja_\1.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale

RUN set -x \
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
    && rm -rf /var/lib/apt/lists/* \
    && if [ "$BUILD_ARCH" = "amd64" ]; then \
        bash -c  'echo "deb https://debian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list'; apt-key adv --fetch-keys https://debian.snips.ai/5FFCD0DEB5BA45CD.pub; \
    else \
        bash -c  'echo "deb https://raspbian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list'; apt-key adv --fetch-keys https://raspbian.snips.ai/531DD1A7B702B14D.pub; \
    fi \
    && pip install virtualenv

# Install snips
RUN set -x \
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
        snips-watch

# Install mimic from Mycroft
RUN set -x \
    && apt-get install -y \
        gcc \
        make \
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

RUN set -x \
    && usermod -aG snips-skills-admin root \
    && apt-get install -y supervisor

RUN set -x \
    && mkdir -p /ingress/templates /ingress/static /EXTRA-LICENSES \
    && pip3 install flask \
        requests \
        ruamel.yaml \
        cheroot

RUN set -x \
    && apt-get update \
    && apt-get install -y ffmpeg

# Don't forget to clean up the stuff the image won't actually use!
RUN set -x \
    && rm -rf /tmp/mimic \
    && apt-get -y autoremove

COPY ingress/*.py /ingress/
COPY ingress/templates/* /ingress/templates/
COPY ingress/static/* /ingress/static/

COPY funcs.sh /
COPY extract_assistant.sh /
COPY manage_tts_cache.sh /
COPY restart_snips_skill_server.sh /
COPY run.sh /
COPY setup.sh /
COPY start_service.sh /
COPY start_snips_watch.sh /
COPY stop_snips_watch.sh /
COPY tts-unparsed.sh /tts/
COPY update_ha_config.py /
COPY wait-for-it.sh /
COPY EXTRA-LICENSES/* /EXTRA-LICENSES/

RUN rm -rf /etc/supervisor \
        && mkdir /etc/supervisor
RUN chmod 755 /extract_assistant.sh /manage_tts_cache.sh /restart_snips_skill_server.sh /run.sh /start_service.sh /start_snips_watch.sh /stop_snips_watch.sh /update_ha_config.py /wait-for-it.sh /ingress/ /ingress/static/ /ingress/templates/ /ingress/control.py /etc/supervisor/ /tts/
RUN chmod 644 /funcs.sh /ingress/static/* /ingress/templates/* /setup.sh /tts/tts-unparsed.sh
ENTRYPOINT [ "/run.sh" ]
