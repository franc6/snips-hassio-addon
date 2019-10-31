#!/usr/bin/qemu-arm-static /bin/sh
/usr/bin/qemu-arm-static /bin/rm -f /bin/sh
/usr/bin/qemu-arm-static /bin/mv /bin/sh.real /bin/sh
/usr/bin/qemu-arm-static /bin/rm -f /bin/sh-shim

/usr/bin/qemu-arm-static /bin/rm -f /bin/bash
/usr/bin/qemu-arm-static /bin/mv /bin/bash.real /bin/bash
/usr/bin/qemu-arm-static /bin/rm -f /bin/bash-shim

/usr/bin/qemu-arm-static /bin/rm -f /usr/bin/qemu-arm-static
/usr/bin/qemu-arm-static /bin/rm -f /start-arm-build.sh
/usr/bin/qemu-arm-static /bin/rm -f /stop-arm-build.sh

