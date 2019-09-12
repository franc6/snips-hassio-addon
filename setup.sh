function setup_amazon_tts() {
    bashio::log.error "setup_amazon_tts hasn't been implemented yet!"
    bashio::log.error "The Amazon Polly service will not work!"
}

function setup_mosquitto() {
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
persistence false
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
	return 1
    fi
    return 0
}

function setup_snips_toml() {
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

	echo 'provider = "customtts"' >> /etc/snips.toml
	echo "customtts = { command = [\"/tts/tts.sh\", \"%%OUTPUT_FILE%%\", \"%%TEXT%%\"] }" >> /etc/snips.toml
    fi
    bashio::log.info "Done with snips.toml setup."
}

funcion setup_supervisord() {
    SERVICES=(ingress mosquitto)
    SNIPS_GROUP=()

    SERVICES+=(snips-asr snips-dialogue snips-hotword snips-nlu snips-injection snips-tts snips-skill-server snips-audio-server)
    if [ "${SNIPS_ANALYTICS}" = "true" ]; then
	SERVICES+=(snips-analytics)
    fi

    for service in ${SERVICES[@]} ; do
	if [[ "${service}" == snips-* ]]; then
	    SNIPS_GROUP+=(${service})
	fi
    done

    # snips-watch must not be included in SNIPS_GROUP, so we add it only after
    # setting up SNIPS_GROUP!
    snips_watch_autostart="false"
    snips_watch_autorestart="false"
    if [ "${SNIPS_WATCH}" = "true" ]; then
	SERVICES+=(snips-watch)
    fi

    snips_audio_server_flags="--disable-playback --no-mike --hijack localhost:64321"
    snips_skill_server_priority="999"

    ingress_entry="/"
    ingress_port="8099"
    if SELF_INFO="$(curl -s -X GET -H "X-HASSIO-KEY: ${HASSIO_TOKEN}" http://hassio/addons/self/info)" ; then
	ingress_ip="$(echo "${SELF_INFO}" | jq --raw-output '.data.ip_address')"
	ingress_entry="$(echo "${SELF_INFO}" | jq --raw-output '.data.ingress_entry')"
	ingress_port="$(echo "${SELF_INFO}" | jq --raw-output '.data.ingress_port')"
    fi
    ingress_autostart="true"
    ingress_autorestart="true"
    ingress_flags="/ingress/control.py ${ingress_ip} ${ingress_port} ${ingress_entry} ${ADDON_VERSION} ${SNIPS_VERSION} ${SERVICES[@]/%/.log}"
    ingress_program="python3"
    ingress_priority="1"
    ingress_directory="/ingress"
    ingress_startsecs=5

    mosquitto_flags="-c /etc/mosquitto/mosquitto.conf"
    mosquitto_priority=100
    mosquitto_startsecs=15
    mosquitto_autostart="true"
    mosquitto_autorestart="true"

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

    tts_online=$(bashio::config 'tts.online_services | @sh')
    tts_maxCacheSize=$(bashio::config 'tts.max_cache_size')
    if [ -n "${tts_online[@]}" -a "X${tts_maxCacheSize}" != "X0"  ]; then
	cat >> ${SUPERVISORD_CONF} << _EOF_CONF
[eventlistener:manage_tts_cache]
command=/manage_tts_cache.sh
autostart=true
autorestart=true
events=TICK_3600

_EOF_CONF
    fi

    for service in ${SERVICES[@]} ; do
	service_underscores=${service//-/_}
	flags=$(echo ${service_underscores}_flags)
	priority=$(echo ${service_underscores}_priority)
	directory=$(echo ${service_underscores}_directory)
	program=$(echo ${service_underscores}_program)
	startsecs=$(echo ${service_underscores}_startsecs)
	autostart=$(echo ${service_underscores}_autostart)
	autorestart=$(echo ${service_underscores}_autorestart)
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
autostart=${!autostart:-false}
autorestart=${!autorestart:-unexpected}
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
}

function setup_tts_script() {
    offline_service=$(bashio::config 'tts.offline_service')
    mimic_voice=$(bashio::config 'tts.mimic_voice')
    online_services=$(bashio::config 'tts.online_services | @sh')
    online_services=${online_services[@]//\'}
    sample_rate=$(bashio::config 'tts.sample_rate')
    online_volume_factor=$(bashio::config 'tts.online_volume_factor')
    macos_voice=$(bashio::config 'tts.macos_voice')
    macos_ssh_config=$(bashio::config 'tts.macos_ssh_config')
    macos_ssh_host=$(bashio::config 'tts.macos_ssh_host')
    google_voice=$(bashio::config 'tts.google_voice')
    google_voice_gender=$(bashio::config 'tts.google_voice_gender')
    google_voice_gender="${google_voice_gender^^}"
    google_tts_key=$(bashio::config 'tts.google_tts_key')
    amazon_voice=$(bashio::config 'tts.amazon_voice')
    aws_access_key_id=$(bashio::config 'tts.aws_access_key_id')
    aws_secret_access_key=$(bashio::config 'tts.aws_secret_access_key')
    aws_default_region=$(bashio::config 'tts.aws_default_region')

    rm -f /tts/tts.sh
    sed -e "s/%%LANG%%/${LANG}/g" \
	-e "s/%%COUNTRY%%/${COUNTRY}/g" \
	-e "s/%%OFFLINE_SERVICE%%/${offline_service}/g" \
	-e "s,%%MIMIC_VOICE%%,${mimic_voice},g" \
	-e "s/%%ONLINE_SERVICES%%/${online_services}/g" \
	-e "s/%%SAMPLE_RATE%%/${sample_rate}/g" \
	-e "s/%%ONLINE_VOLUME_FACTOR%%/${online_volume_factor}/g" \
	-e "s/%%MACOS_VOICE%%/${macos_voice}/g" \
	-e "s,%%MACOS_SSH_CONFIG%%,${macos_ssh_config},g" \
	-e "s/%%MACOS_SSH_HOST%%/${macos_ssh_host}/g" \
	-e "s/%%GOOGLE_VOICE%%/${google_voice}/g" \
	-e "s/%%GOOGLE_VOICE_GENDER%%/${google_voice_gender}/g" \
	-e "s/%%GOOGLE_TTS_KEY%%/${google_tts_key}/g" \
	-e "s/%%AMAZON_VOICE%%/${amazon_voice}/g" \
	-e "s/%%AWS_ACCESS_KEY_ID%%/${aws_access_key_id}/g" \
	-e "s/%%AWS_SECRET_ACCESS_KEY%%/${aws_secret_access_key}/g" \
	-e "s/%%AWS_DEFAULT_REGION%%/${aws_default_region}/g" \
        /tts/tts-unparsed.sh > /tts/tts.sh
    chmod 755 /tts/tts.sh

    for i in ${online_services}
    do
	if [ "${i}" == "amazon" ]; then
	    setup_amazon_tts
	fi
    done
}
