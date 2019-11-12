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

