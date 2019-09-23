#!/bin/sh

if [ "${BUILD_ARCH}" == "armhf" ] ; then
    /usr/bin/qemu-arm-static /bin/cp /bin/sh.real /bin/sh
    /usr/bin/qemu-arm-static /bin/rm -f /bin/sh-shim
    /usr/bin/qemu-arm-static /bin/cp /bin/bash.real /bin/bash
    /usr/bin/qemu-arm-static /bin/rm -f /bin/bash-shim
    /usr/bin/qemu-arm-static /bin/rm -f /usr/bin/qemu-arm-static
    /usr/bin/qemu-arm-static /bin/rm -f /start-arm-build.sh
    /usr/bin/qemu-arm-static /bin/rm -f /stop-arm-build.sh
else
    rm -f /start-arm-build.sh
    rm -f /stop-arm-build.sh
fi

exit 0


