#!/usr/bin/env bashio
set -e

CONFIG_PATH=/data/options.json

ASSISTANT=$(bashio::config 'assistant')
LANG=$(bashio::config 'language')
COUNTRY=$(bashio::config 'country_code')
GOOGLE_ASR_CREDENTIALS=$(bashio::config 'google_asr_credentials')
SNIPS_ANALYTICS=$(bashio::config 'snips_extras.snips_analytics')
SNIPS_WATCH=$(bashio::config 'snips_extras.snips_watch')

if [ -z "${ASSISTANT}" ]; then
    bashio::log.error "Invalid configuration.  'assistant' must not be empty!"
    exit 1
fi

if [ -z "${LANG}" ]; then
    bashio::log.warning "'language' was not set.  Assuming English."
    LANG="en"
fi

if [ -z "${COUNTRY}" ]; then
    if [ "${LANG}" == "de" ]; then
	bashio::log.warning "'country' was not set.  Assuming Germany."
	COUNTRY="DE"
    elif [ "${LANG}" == "en" ]; then
	bashio::log.warning "'country' was not set.  Assuming the United States."
	COUNTRY="US"
    elif [ "${LANG}" == "fr" ]; then
	bashio::log.warning "'country was not set. Assuming France."
	COUNTRY="FR"
    fi
fi

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
    bashio::log.error "Snips is not running yet!"
    SNIPS_EMAIL=$(bashio::config 'snips_console.email')
    SNIPS_PASSWORD=$(bashio::config 'snips_console.password')
    if [ -n "${SNIPS_EMAIL}" -a -n "${SNIPS_PASSWORD}" ]; then
	bashio::log.warning "You can use the Web UI to install your assistant.  Snips will start after the assistant is installed."
    else
	bashio::log.error "You have not configured your Snips Console email address and password.  You must configure those or copy your assistant's ZIP file to /share/snips/${ASSISTANT}.  This add-on will now exit."
	stop_snips
	exit 1
    fi
    SNIPS_EMAIL=
    SNIPS_PASSWORD=
else
    bashio::log.info "Waiting for mosquitto to settle..."
    sleep 5
    start_snips
fi

function stop_addon() {
    bashio::log.info "Shutdown $(hostname)"
    kill -TERM "${WAIT_PIDS[@]}"
    wait "${WAIT_PIDS[@]}"
}

trap "stop_addon" SIGTERM SIGHUP

wait "${WAIT_PIDS[@]}"
