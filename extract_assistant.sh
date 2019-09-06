#!/usr/bin/env bashio
set -e

CONFIG_PATH=/data/options.json

ASSISTANT=$(bashio::config 'assistant')
LANG=$(bashio::config 'language')
COUNTRY=$(bashio::config 'country_code')

export LC_ALL="${LANG}_${COUNTRY}.UTF-8"

. /funcs.sh

bashio::log.info "Assistant update requested" 
if ! extract_assistant ${ASSISTANT}; then
    exit 1
fi

bashio::log.info "Assistant update finished" 
# Restart snips services
restart_snips

