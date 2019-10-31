#!/usr/bin/qemu-arm-static /bin/sh

/usr/bin/qemu-arm-static /bin/cat >/bin/sh-shim <<'_EOF'
#!/usr/bin/qemu-arm-static /bin/sh.real
set -o errexit

/usr/bin/qemu-arm-static /bin/rm -f /bin/sh
/usr/bin/qemu-arm-static /bin/ln -s /bin/sh.real /bin/sh
/usr/bin/qemu-arm-static /bin/echo /bin/sh -c \"$@\"
/usr/bin/qemu-arm-static -execve /bin/sh -c "$@"
/usr/bin/qemu-arm-static /bin/echo done with real sh run
/usr/bin/qemu-arm-static /bin/rm -f /bin/sh
/usr/bin/qemu-arm-static /bin/ln -s /bin/sh-shim /bin/sh
/usr/bin/qemu-arm-static /bin/ls -lF /bin/sh
_EOF

/usr/bin/qemu-arm-static /bin/cat >/bin/bash-shim <<'_EOF'
#!/usr/bin/qemu-arm-static /bin/bash.real
set -x
set -o errexit

/usr/bin/qemu-arm-static /bin/rm -f /bin/bash
/usr/bin/qemu-arm-static /bin/ln -s /bin/bash.real /bin/bash
/usr/bin/qemu-arm-static /bin/echo temp call to apt-get update
/usr/bin/qemu-arm-static -execve /usr/bin/apt-get update
/usr/bin/qemu-arm-static /bin/echo END temp call to apt-get update
/usr/bin/qemu-arm-static /bin/echo /bin/bash -c \"$@\"
/usr/bin/qemu-arm-static -execve /bin/bash -c "$@"
/usr/bin/qemu-arm-static /bin/echo done with real bash run
/usr/bin/qemu-arm-static /bin/rm -f /bin/bash
/usr/bin/qemu-arm-static /bin/ln -s /bin/bash-shim /bin/bash
/usr/bin/qemu-arm-static /bin/ls -lF /bin/bash
_EOF

/usr/bin/qemu-arm-static /bin/mv /bin/sh /bin/sh.real
/usr/bin/qemu-arm-static /bin/mv /bin/bash /bin/bash.real

/usr/bin/qemu-arm-static /bin/chmod 755 /bin/sh-shim
/usr/bin/qemu-arm-static /bin/rm -f /bin/sh
/usr/bin/qemu-arm-static /bin/ln -s /bin/sh-shim /bin/sh

/usr/bin/qemu-arm-static /bin/chmod 755 /bin/bash-shim
/usr/bin/qemu-arm-static /bin/rm -f /bin/bash
/usr/bin/qemu-arm-static /bin/ln -s /bin/bash-shim /bin/bash
