#!/usr/bin/env bashio

outputFile=$1
text=$2
cache="/data/tts/cache"
shellSafeText=${text//\"/\\\"}
shellSafeText=${shellSafeText//\$/\\\$}

function amazonOnlineCheck() {
    # If aws isn't installed, don't bother with the online check!
    if [ ! -x /aws/bin/aws ] ; then
        echo "offline"
    else
        if /usr/bin/curl -s -f https://aws.amazon.com/polly/ -o /dev/null 2>/dev/null ; then
            echo "online"
        else
            echo "offline"
        fi
    fi
}

function googleOnlineCheck() {
    if /usr/bin/curl -s -f https://www.google.com/ -o /dev/null 2> /dev/null ; then
        echo "online"
    else
        echo "offline"
    fi
}

function macosOnlineCheck() {
    if echo > /dev/tcp/%%MACOS_SSH_HOST%%/22 ; then
        echo "online"
    else
        echo "offline"
    fi
}

function getCacheFileName() {
    hash=$(echo "${shellSafeText}_$1_%%SAMPLE_RATE%%_%%LANG%%_%%COUNTRY%%" |/usr/bin/md5sum|/usr/bin/cut -f1 -d" ")
    echo ${cache}/${hash}.$2
}

function getFromCache() {
    cacheFile=$1
    if [ -f "${cacheFile}" ]; then
        /usr/bin/ffmpeg -loglevel quiet -y -i "${cacheFile}" -ar %%SAMPLE_RATE%% -filter:a "volume=%%ONLINE_VOLUME_FACTOR%%" "${outputFile}"
        #/usr/bin/mpg123 -q -w "${outputFile}" "${cacheFile}"
        ret=$?
        if [ ${ret} -ne 0 ] ; then
            /bin/rm -f "${cacheFile}" "${outputFile}"
        fi
    fi
    return ${ret}
}

function getSSMLText() {
    echo "<speak>"
    echo ${text} | /bin/sed -e 's/&/&amp;/g' \
                            -e 's/"/&quot;/g' \
                            -e "s/'/&apos;/g" \
                            -e 's/</&lt;/g' \
                            -e 's/>/&gt;/g'
    echo "</speak>"
}

function amazon() {
    # Amazon Polly only processes up to 3000 characters, unless you're using
    # an Amazon S3 bucket, and we don't want to try managing that in this
    # script, so just return 1 if it's longer than 3000 characters.
    if [ $(echo "${shellSafeText}" | /usr/bin/wc -c) -gt 3000 ] ; then
        return 1
    fi

    cacheFile=$(getCacheFileName %%AMAZON_VOICE%% mp3)
    status=$(amazonOnlineCheck)

    if [ ! -f "${cacheFile}" -a "${status}" == "online" ]; then
        ssmltext=$(getSSMLText)

        export AWS_ACCESS_KEY_ID="%%AWS_ACCESS_KEY_ID%%"
        export AWS_SECRET_ACCESS_KEY="%%AWS_SECRET_ACCESS_KEY%%"
        export AWS_DEFAULT_REGION="%%AWS_DEFAULT_REGION%%"

        /aws/bin/aws polly synthesize-speech --output-format mp3 --voice-id "%%AMAZON_VOICE%%" --sample-rate %%SAMPLE_RATE%% --text-type ssml --text "${ssmlText}" "${cacheFile}"
        ret=$?
        if [ ${ret} -ne 0 ]; then
            /bin/rm -f "${cacheFile}"
        fi
    fi

    getFromCache "${cacheFile}"
    ret=$?
    return ${ret}
}

function google_translate() {
    # Google Translate only processes up to 100 bytes, so just return 1 if it's
    # longer than 100 bytes.
    if [ $(echo "${shellSafeText}" | /usr/bin/wc -c) -gt 100 ] ; then
        return 1
    fi

    cacheFile=$(getCacheFileName google-translate mp3)
    status=$(googleOnlineCheck)

    if [ ! -f "${cacheFile}" -a "${status}" == "online" ]; then
        /usr/bin/curl -s -f -G -A Mozilla "https://translate.google.com/translate_tts" \
            --data-urlencode "ie=UTF-8" \
            --data-urlencode "client=tw-ob" \
            --data-urlencode "tl=%%LANG%%-%%COUNTRY%%" \
            --data-urlencode "q=${text}" \
            -o ${cacheFile}
        ret=$?
        if [ ${ret} -ne 0 ] ; then
            /bin/rm -f "${cacheFile}"
        fi
    fi

    getFromCache "${cacheFile}"
    ret=$?
    return ${ret}
}

function google() {
    # Google Wavenet only processes up to 5000 bytes, so just return 1 if it's
    # longer than 5000 bytes.
    if [ $(echo "${shellSafeText}" | /usr/bin/wc -c) -gt 5000 ] ; then
        return 1
    fi
    googleVoice="%%LANG%%-%%COUNTRY%%-%%GOOGLE_VOICE%%"

    status=$(googleOnlineCheck)
    cacheFile=$(getCacheFileName %%GOOGLE_VOICE%% mp3)

    if [ ! -f "${cacheFile}" -a "${status}" == "online" ]; then
        ssmltext=$(getSSMLText)
        read -r -d '' data << 'DATA_EOF'
{
  "input": {
    "ssml": "${ssmltext}"
  },
  "voice": {
    "languageCode": %%LANG%%-%%COUNTRY%%",
    "name": "${googleVoice}"
    "ssmlGender": %%GOOGLE_VOICE_GENDER%%"
  },
  "audioConfig": {
    "audioEncoding": "MP3",
    "sampleRateHertz": "%%SAMPLE_RATE%%"
  }
}
DATA_EOF
        /usr/bin/curl -s -f -X POST \
             -H "Content-Type: application/json; charset=utf8" \
             -d "${data}" "https://texttospeech.googleapis.com/v1/text:synthesize?key=%%GOOGLE_TTS_KEY%%" -o - \
            | /usr/bin/awk -F'"' '/audioContent/ {print $4}' \
            | /usr/bin/base64 --decode > "${cacheFile}"
        ret=$?
        if [ ${ret} -ne 0 ] ; then
            /bin/rm -f "${cacheFile}"
        fi
    fi

    getFromCache "${cacheFile}"
    ret=$?
    return ${ret}
}

function macos() {
    cacheFile=$(getCacheFileName macos_%%MACOS_VOICE%% aiff)
    status=$(macosOnlineCheck)

    if [ ! -f "${cacheFile}" -a "${status}" == "online" ]; then
        /usr/bin/ssh -F %%MACOS_SSH_CONFIG%% %%MACOS_SSH_HOST%% "TMPFILE=\`mktemp\` ; say -v %%MACOS_VOICE%% -o \${TMPFILE} \"\\\"${shellSafeText/\\/\\\\\\}\\\"\" ; ret=\$? ; cat \${TMPFILE}; rm -f \${TMPFILE} ; exit \${ret}" > "${cacheFile}"
        ret=$?
        if [ $ret -ne 0 ]; then
            rm -f "${cacheFile}"
        fi
    fi

    getFromCache "${cacheFile}"
    ret=$?
    return ${ret}
}

function mimic() {
    /usr/local/bin/mimic -o "${outputFile}" -voice "%%MIMIC_VOICE%%" -t "${shellSafeText}"
}

function pico2wave() {
    /usr/bin/pico2wave -w "${outputFile}" -l "%%LANG%%-%%COUNTRY%%" "${shellSafeText}"
}

ret=1
for i in %%ONLINE_SERVICES%%
do
    bashio::log.info "Trying online service: ${i}"
    if ${i}; then
        bashio::log.info "Success with online service: ${i}"
        ret=0
        break
    else
        bashio::log.warning "Online service: ${i} failed"
    fi
done

if [ ${ret} -ne 0 ]; then
    bashio::log.info "Trying offline service: %%OFFLINE_SERVICE%%"
    %%OFFLINE_SERVICE%%
fi
