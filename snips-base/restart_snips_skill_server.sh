#!/usr/bin/env bashio
set -e

. /funcs.sh

bashio::log.info "Restarting snips-skill-server"
restart_snips_skill_server

