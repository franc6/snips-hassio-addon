#!/usr/bin/env bashio
set -e

CONFIG_PATH=/data/options.json

ANALYTICS=$(bashio::config 'analytics')
ASSISTANT=$(bashio::config 'assistant')
LANG=$(bashio::config 'language')
COUNTRY=$(bashio::config 'country_code')
CAFILE=$(bashio::config 'cafile')
USE_CUSTOM_TTS=$(bashio::config 'custom_tts.active')
GOOGLE_ASR_CREDENTIALS=$(bashio::config 'google_asr_credentials')
SNIPS_WATCH=$(bashio::config 'snips_watch')

export LC_ALL="${LANG}_${COUNTRY}.UTF-8"

. /funcs.sh

bashio::log.info "LANG: ${LANG}"

snipstomlfile=$(check_for_file snips.toml)
if [ -n "${snipstomlfile}" ]; then
    bashio::log.warning "Installing ${snipstomlfile}"
    bashio::log.warning "Addon configuration will be ignored!"
    rm -f /etc/snips.toml
    cp ${snipstomlfile} /etc
else
    cat > /etc/snips.toml << _SNIPS_TOML_EOF
[snips-common]
assistant = "/usr/share/snips/assistant"
user_dir = "/var/lib/snips"
bus = "mqtt"
mqtt = "localhost:1883"

[snips-analytics]

[snips-asr]

[snips-audio-server]
bind = "$(hostname)@mqtt"

[snips-dialogue]

[snips-hotword]
audio = ["+@mqtt"]

[snips-injection]

[snips-nlu]

[snips-pegasus]

[snips-asr-google]
_SNIPS_TOML_EOF

    if [ -n "${GOOGLE_ASR_CREDENTIALS}" ]; then
	google_asr_credentials=$(check_for_file ${GOOGLE_ASR_CREDENTIALS})
	if [ -n "${google_asr_credentials}" ]; then
	    echo "credentials = \"${google_asr_credentials}\"" >> /etc/snips.toml
	fi
    fi

    echo "" >> /etc/snips.toml
    echo "[snips-tts]" >> /etc/snips.toml

    if [ "$USE_CUSTOM_TTS" = "true" ]; then
	CUSTOM_TTS_PLATFORM=$(bashio::config 'custom_tts.platform')
	CUSTOM_TTS_VOICE=$(bashio::config 'custom_tts.voice')
	CUSTOM_TTS_VOICE=$(bashio::config 'custom_tts.voice')
	CUSTOM_TTS_GENDER=$(bashio::config 'custom_tts.gender')
	echo 'provider = "customtts"' >> /etc/snips.toml
	if [ "${CUSTOM_TTS_PLATFORM}" = "mimic" ]; then
	    echo "customtts = { command = [\"/usr/local/bin/mimic\", \"-o\", \"%%OUTPUT_FILE%%\", \"-voice\", \"${CUSTOM_TTS_VOICE}\", \"-t\", \"%%TEXT%%\"] }" >> /etc/snips.toml
	elif [ "${CUSTOM_TTS_PLATFORM}" = "pico2wave" ]; then
	    echo "customtts = { command = [\"/usr/bin/pico2wave\", \"-w\", \"%%OUTPUT_FILE%%\", \"-l\", \"${CUSTOM_TTS_VOICE}\", \"%%TEXT%%\"] }" >> /etc/snips.toml
	#elif [ "${CUSTOM_TTS_PLATFORM}" = "SnipsSuperTTS" ]; then
	    #echo "customtts = { command = [\"/usr/local/bin/snipsSuperTTS.sh\", \"%%OUTPUT_FILE%%\", \"google\", \"${LANG}\", \"${COUNTRY}\", \"${CUSTOM_TTS_VOICE}\", \"${CUSTOM_TTS_GENDER}\", \"%%TEXT%%\", \"22050\"] }" >> /etc/snips.toml
	fi
    else
	echo 'provider = "picotts"' >> /etc/snips.toml
    fi
fi
bashio::log.info "Done with snips.toml setup."

# Get information about the mqtt server from hassio API, to set up
# mosquitto.conf
if MQTT_CONFIG="$(curl -s -X GET -H "X-HASSIO-KEY: ${HASSIO_TOKEN}" http://hassio/services/mqtt)" ; then
    mqtt_host="$(echo "${MQTT_CONFIG}" | jq --raw-output '.data.host')"
    mqtt_port="$(echo "${MQTT_CONFIG}" | jq --raw-output '.data.port')"
    mqtt_username="$(echo "${MQTT_CONFIG}" | jq --raw-output '.data.username')"
    mqtt_password="$(echo "${MQTT_CONFIG}" | jq --raw-output '.data.password')"
    mqtt_ssl="$(echo "${MQTT_CONFIG}" | jq --raw-output '.data.ssl')"
    cat > /etc/mosquitto/mosquitto.conf << _MOSQUITTO_CONF_EOF
pid_file /var/run/mosquitto.pid
persistence true
persistence_location /data/
log_dest stdout
log_type error
log_type warning
log_type notice
include_dir /etc/mosquitto/conf.d

user root

listener 1883
protocol mqtt

connection hassio-mqtt
address ${mqtt_host}:${mqtt_port}
cleansession false
clientid $(hostname)
start_type automatic
username ${mqtt_username}
password ${mqtt_password}
notifications false
try_private false
topic hermes/intent/# out
topic hermes/dialogueManager/# in
_MOSQUITTO_CONF_EOF
    if [ "${mqtt_ssl}" = "true" ]; then
	echo "bridge_insecure true" >> /etc/mosquitto/mosquitto.conf
	cafile=$(check_for_file ${CAFILE})
	if [ -n "${cafile}" ]; then
	    echo "bridge_cafile ${cafile}" >> /etc/mosquitto/mosquitto.conf
	fi
    fi
else
    bashio::log.error "No Hass.io mqtt service found!  You must install and configure the MQTT addon!"
    exit 1
fi

if ! extract_assistant "${ASSISTANT}" ; then
    exit 1
fi

mkdir -p /share/snips/logs

ingress_entry="/"
ingress_port="8099"
if SELF_INFO="$(curl -s -X GET -H "X-HASSIO-KEY: ${HASSIO_TOKEN}" http://hassio/addons/self/info)" ; then
    ingress_ip="$(echo "${SELF_INFO}" | jq --raw-output '.data.ip_address')"
    ingress_entry="$(echo "${SELF_INFO}" | jq --raw-output '.data.ingress_entry')"
    ingress_port="$(echo "${SELF_INFO}" | jq --raw-output '.data.ingress_port')"
fi

SERVICES=(ingress mosquitto)
mosquitto_flags="-c /etc/mosquitto/mosquitto.conf"
mosquitto_priority=100
mosquitto_startsecs=15

SNIPS_GROUP=()

SERVICES+=(snips-asr snips-dialogue snips-hotword snips-nlu snips-injection snips-tts snips-skill-server snips-audio-server)

for service in ${SERVICES[@]} ; do
    if [[ "${service}" == snips-* ]]; then
	SNIPS_GROUP+=(${service})
    fi
done

# snips-watch and snips-analytics should not be included in SNIPS_GROUP, so we
# add them only after setting up SNIPS_GROUP!
if [ "${SNIPS_WATCH}" = "true" ]; then
    SERVICES+=(snips-watch)
fi

if [ "${ANALYTICS}" = "true" ]; then
    SERVICES+=(snips-analytics)
fi

snips_audio_server_flags="--disable-playback --no-mike --hijack localhost:64321"
snips_skill_server_priority="999"
assistant_file=$(check_for_file "${ASSISTANT}")
ingress_flags="/ingress/control.py ${ingress_ip} ${ingress_port} ${ingress_entry} ${SERVICES[@]/%/.log}"
ingress_program="python3"
ingress_priority="1"
ingress_directory="/ingress"
ingress_startsecs=5

rm -f ${SUPERVISORD_CONF}
cat > ${SUPERVISORD_CONF} << _EOF_SUPERVISORD_CONF
[supervisord]
nodaemon = true
logfile = /share/snips/logs/supervisord.log
logfile_maxbytes = 50MB
logfile_backups = 1
loglevel = info
pifile = /supervisord.pid

[unix_http_server]
file = /var/run/supervisor.sock
chmod = 0700
chown = root:root

[supervisorctl]
serverurl = unix:///var/run/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
_EOF_SUPERVISORD_CONF

for service in ${SERVICES[@]} ; do
    flags=$(echo ${service}_flags | sed -e 's/-/_/g')
    priority=$(echo ${service}_priority | sed -e 's/-/_/g')
    directory=$(echo ${service}_directory | sed -e 's/-/_/g')
    program=$(echo ${service}_program | sed -e 's/-/_/g')
    startsecs=$(echo ${service}_startsecs | sed -e 's/-/_/g')
    if [ "${service}" = "mosquitto" -o "${service}" = "ingress" ]; then
	command="${!program:-${service}} ${!flags:-}"
    else
	command="/start_service.sh localhost 1883 0 ${!program:-${service}} ${!flags:-}"
    fi
    cat >> ${SUPERVISORD_CONF} << _EOF_CONF
[program:${service}]
command=${command}
priority=${!priority:-900}
directory=${!directory:-/}
autostart=true
autorestart=true
startretries=5
startsecs=${!startsecs:-0}
redirect_stderr=true
stdout_logfile=/share/snips/logs/${service}.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=5
_EOF_CONF
done

( IFS=, ; cat >> ${SUPERVISORD_CONF} << _EOF_CONF
[group:snips-group]
programs=${SNIPS_GROUP[*]}
_EOF_CONF
)

supervisord -c ${SUPERVISORD_CONF} &
WAIT_PIDS+=($!)

function stop_snips() {
    bashio::log.info "Shutdown $(hostname)"
    kill -TERM "${WAIT_PIDS[@]}"
    wait "${WAIT_PIDS[@]}"
}

trap "stop_snips" SIGTERM SIGHUP

wait "${WAIT_PIDS[@]}"
