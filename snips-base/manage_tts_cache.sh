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
    cacheSize=$(/usr/bin/du -s${duSizeOpt} "${cache}")
    cacheSize=${cacheSize/[^0-9]*/}
    while [ ${cacheSize} -gt ${maxCacheSize} ]
    do
        /bin/rm -f $(/bin/ls -tur "${cache}" | /usr/bin/head -n 1)
        cacheSize=$(/usr/bin/du -s${duSizeOpt} "${cache}")
        cacheSize=${cacheSize/([^0-9]*)/}
    done
}

echo "READY"
len=0
read -a header
for i in ${header[@]}
do
    if [[ ${i} == len:* ]]; then
	len=${i/len:/}
    fi
done

if [ "${len}" == "0" ]; then
    exit 0
fi

read -N ${len} when && manageCache 
if [ $? -eq 0 ]; then
    echo "RESULT 2"
    echo "OK"
else
    echo "RESULT 4"
    echo "FAIL"
fi
exit 0

