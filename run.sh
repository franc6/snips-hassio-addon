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

export LC_ALL="${LANG}_${COUNTRY}.UTF-8"

function check_for_file() {
    bashio::log.info "Checking for /share/snips/$1"
    if [ -f "/share/snips/$1" ]; then
	echo "/share/snips/$1"
	return 0
    fi
    bashio::log.info "Checking for /share/$1"
    if [ -f "/share/$1" ]; then
	echo "/share/$1"
	return 0
    fi
    echo
}

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
#audio = ["+@mqtt"]

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

assistant=$(check_for_file ${ASSISTANT})
if [ -n "${assistant}" ]; then
    bashio::log.info "Installing snips assistant from ${assistant}"
    rm -rf /usr/share/snips/assistant
    unzip -qq -d /usr/share/snips ${assistant}
else
    bashio::log.error "Could not find the snips assistant!"
    exit 1
fi

#start with a clear skill directory
rm -rf /var/lib/snips/skills/*

#deploy apps (skills). See: https://snips.gitbook.io/documentation/console/deploying-your-skills
snips-template render

#goto skill directory
cd /var/lib/snips/skills

#download required skills from git
for url in $(awk '$1=="url:" {print $2}' /usr/share/snips/assistant/Snipsfile.yaml); do
	git clone -q $url
done

#be sure we are in the skill directory
cd /var/lib/snips/skills

# run setup.sh for each skill, and link any config.ini file for it
# since we can't interact with the user, we have to do something else to get
# config.ini files in place!
find . -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir; do
        if [ "$dir" != "." ]; then
	    cd "$dir" 
	    skillname=$(echo $dir | cut -c3-)
	    if [ -f setup.sh ]; then
		bashio::log.info "Running setup.sh for ${skillname}"
		#run the scrips always with bash
		bash ./setup.sh
	    fi
	    skillconfigfile=$(check_for_file ${skillname}-config.ini)
	    if [ -n "${skillconfigfile}" ] ; then
		bashio::log.info "Copying ${skillconfigfile} to config.ini for ${skillname}"
		rm -f config.ini
		cp "${skillconfigfile}" "config.ini"
	    fi
	    if [ -f "spec.json" ]; then
		spec_json_name="$(jq --raw-output '.name' spec.json)"
		spec_json_language="$(jq --raw-output '.language' spec.json)"
		if [ "X${spec_json_name}" = "Xhomeassistant" ]; then
		    if [ "X${spec_json_language}" = "XPYTHON" ]; then
			for i in action_*.py ; do
			    bashio::log.info "Installing python_script: ${i}"
			    if [ ! -d "/config/python_scripts" ]; then
				mkdir /config/python_scripts
			    fi
			    cp "${i}" /config/python_scripts
			done
			bashio::log.info "You must set up the intent_script: component in configuration.yaml for ${dir} to work."
		    fi
		fi
	    fi
	    cd /var/lib/snips/skills
	fi
done
bashio::log.info "Finished deploying skills"

#go back to root directory
cd /

mkdir -p /share/snips/logs

SERVICES=(mosquitto)
mosquitto_flags="-c /etc/mosquitto/mosquitto.conf"
mosquitto_startup_delay=5
mosquitto_priority=1

if [ "${ANALYTICS}" = "true" ]; then
    SERVICES+=(snips-analytics)
fi

SERVICES+=(snips-asr snips-dialogue snips-hotword snips-nlu snips-injection snips-tts snips-skill-server snips-audio-server)
snips_audio_server_flags="--disable-playback --no-mike --hijack localhost:64321"
snips_skill_server_priority="999"

SUPERVISORD_CONF="/etc/supervisor/conf.d/supervisord.conf"
cat > ${SUPERVISORD_CONF} << _EOF_SUPERVISORD_CONF
[supervisord]
nodaemon=true
_EOF_SUPERVISORD_CONF

for service in ${SERVICES[@]} ; do
    flags=$(echo ${service}_flags | sed -e 's/-/_/g')
    priority=$(echo ${service}_priority | sed -e 's/-/_/g')
    if [ "${service}" = "mosquitto" ]; then
	command="${service} ${!flags:-}"
    else
	command="/wait-for-it.sh -h localhost -p 1883 -t 0 -- sh -c \"sleep 60 ; ${service} ${!flags:-}\""
    fi
    cat >> ${SUPERVISORD_CONF} << _EOF_CONF
[program:${service}]
command=${command}
priority=${!priority:-900}
directory=/
autostart=true
autorestart=true
startretries=5
stderr_logfile=/share/snips/logs/${service}.log
stdout_logfile=/share/snips/logs/${service}.log
_EOF_CONF
done

supervisord -c ${SUPERVISORD_CONF} &
WAIT_PIDS+=($!)

function stop_snips() {
    bashio::log.info "Shutdown $(hostname)"
    kill -TERM "${WAIT_PIDS[@]}"
    wait "${WAIT_PIDS[@]}"
}

trap "stop_snips" SIGTERM SIGHUP

wait "${WAIT_PIDS[@]}"
