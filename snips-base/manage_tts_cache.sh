#!/usr/bin/env bashio

cache="/data/tts/cache"
maxCacheSize=$(bashio::config 'tts.max_cache_size')
duSizeOpt="b"
case "$maxCacheSize" in
    *GB)
        duSizeOpt="BK"
        ;;
    *MB)
        duSizeOpt="BK"
        ;;
    *KB)
        duSizeOpt="BK"
        ;;
    [0-9]*)
        # It's all digits, assume it's the size in bytes
        ;;
    *)
        maxCacheSize=50000000
        ;;
esac
maxCacheSize=${maxCacheSize/([^0-9]*)/}

function manageCache() {
    echo "BUSY"
    cacheSize=$(/usr/bin/du -s${duSizeOpt} "${cache}")
    cacheSize=${cacheSize/([^0-9]*)/}
    while [ ${cacheSize} -gt ${maxCacheSize} ]
    do
        /bin/rm -f $(/bin/ls -tur "${cache}" | /usr/bin/head -n 1)
        cacheSize=$(/usr/bin/du -s${duSizeOpt} "${cache}")
        cacheSize=${cacheSize/([^0-9]*)/}
    done
}

echo "READY"
read l && manageCache
echo "RESULT 2"
echo "OK"
exit 0

