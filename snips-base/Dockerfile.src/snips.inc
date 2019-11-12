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

