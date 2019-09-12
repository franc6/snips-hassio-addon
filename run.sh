#!/usr/bin/env bashio
set -e

CONFIG_PATH=/data/options.json

SNIPS_ANALYTICS=$(bashio::config 'analytics')
ASSISTANT=$(bashio::config 'assistant')
LANG=$(bashio::config 'language')
COUNTRY=$(bashio::config 'country_code')
GOOGLE_ASR_CREDENTIALS=$(bashio::config 'google_asr_credentials')
SNIPS_WATCH=$(bashio::config 'snips_watch')

export LC_ALL="${LANG}_${COUNTRY}.UTF-8"

ADDON_INFO="$(curl -s -X GET -H "X-HASSIO-KEY: ${HASSIO_TOKEN}" http://hassio/addons/self/info)"
ADDON_VERSION="$(echo "${ADDON_INFO}" | jq --raw-output '.data.version')"
SNIPS_VERSION="$(snips-skill-server -V | sed -E 's/.*\((.+)\)/\1/')"

# Must include funcs.sh before setup.sh!
. /funcs.sh
. /setup.sh

bashio::log.info "LANG: ${LANG}"

mkdir -p /share/snips/logs
mkdir -p /data/tts/cache
chmod 755 /data/tts/cache

rm -f /data/mosquitto.db

if ! setup_mosquitto ; then
    bashio::log.error "Failed to setup mosquitto!"
    exit 1
fi

setup_supervisord

supervisord -c ${SUPERVISORD_CONF} &
WAIT_PIDS+=($!)

setup_snips_toml

if ! setup_tts_script ; then
    bashio::log.error "Failed to setup the Text-to-Speech script!"
    stop_snips
    exit 1
fi

if ! extract_assistant "${ASSISTANT}" ; then
    bashio::log.error "Failed to extract and setup assistant!"
    stop_snips
    exit 1
fi

bashio::log.info "Waiting for mosquitto to settle..."
sleep 5
start_snips

function stop_addon() {
    bashio::log.info "Shutdown $(hostname)"
    kill -TERM "${WAIT_PIDS[@]}"
    wait "${WAIT_PIDS[@]}"
}

trap "stop_addon" SIGTERM SIGHUP

wait "${WAIT_PIDS[@]}"
