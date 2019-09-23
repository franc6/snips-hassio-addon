if [ "${BUILD_ARCH}" != "armhf" ] ; then
    exit 0
fi

/usr/bin/qemu-arm-static /bin/cp /bin/sh /bin/sh.real
/usr/bin/qemu-arm-static /bin/cp /bin/bash /bin/bash.real

/usr/bin/qemu-arm-static /bin/cat >/bin/sh-shim <<'_EOF'
#!/usr/bin/qemu-arm-static /bin/sh.real
set -o errexit

cp /bin/sh.real /bin/sh
/bin/sh "$@"
cp /usr/bin/sh-shim /bin/sh
_EOF
/usr/bin/qemu-arm-static /bin/cat >/bin/bash-shim <<'_EOF'
#!/usr/bin/qemu-arm-static /bin/bash.real
set -o errexit

cp /bin/bash.real /bin/bash
/bin/bash "$@"
cp /usr/bin/bash-shim /bin/bash
_EOF
/usr/bin/qemu-arm-static /bin/chmod 755 /bin/sh-shim /usr/bin/qemu-arm-static
/usr/bin/qemu-arm-static /bin/chmod 755 /bin/bash-shim /usr/bin/qemu-arm-static

/usr/bin/qemu-arm-static /bin/cp /bin/sh-shim /bin/sh
/usr/bin/qemu-arm-static /bin/cp /bin/bash-shim /bin/bash
