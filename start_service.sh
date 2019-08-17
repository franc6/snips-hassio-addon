#!/usr/bin/env bashio
set -e

# Shift everything we're using early, so we can use $* later for the process to
# run!
host=$1
shift
port=$1
shift
timeout=$1
shift

WAIT_PID=
( ./wait-for-it.sh -h ${host} -p ${port} -t ${timeout} -- )
ret=$?
if [ ${ret} ] ; then
    $* &
    WAIT_PID=$!
else
    bashio::log.info "Could not connect to ${host} on port ${port} after ${timeout} seconds.  Exiting!"
    exit 1
fi

function stop_process() {
    kill -TERM ${WAIT_PID}
    wait "${WAIT_PID}"
}

if [ -n "${WAIT_PID}" ]; then
    trap "stop_process" SIGTERM
    wait "${WAIT_PID}"
fi

