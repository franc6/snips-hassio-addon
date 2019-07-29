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
    && sed -i -e 's/# en_\(..\)\.UTF-8 UTF-8/en_\1.UTF-8 UTF-8/' /etc/locale.gen \
    && sed -i -e 's/# fr_\(..\)\.UTF-8 UTF-8/fr_\1.UTF-8 UTF-8/' /etc/locale.gen \
    && sed -i -e 's/# de_\(..\)\.UTF-8 UTF-8/de_\1.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale

RUN set -x \
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
	bash -c  'echo "deb https://debian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list'; (apt-key adv --keyserver pgp.surfnet.nl --recv-keys F727C778CCB0A455 || apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F727C778CCB0A455); \
    else \
	bash -c  'echo "deb https://raspbian.snips.ai/stretch stable main" > /etc/apt/sources.list.d/snips.list'; (apt-key adv --keyserver pgp.surfnet.nl --recv-keys D4F50CDCA10A2849 || apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D4F50CDCA10A2849); \
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
	snips-tts

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
# Don't forget to clean up the stuff the image won't actually use!
RUN set -x \
    && rm -rf /tmp/mimic \
    && apt-get -y autoremove

RUN set -x \
    && usermod -aG snips-skills-admin root

COPY run.sh /

ENTRYPOINT [ "/run.sh" ]
