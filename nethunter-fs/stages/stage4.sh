#!/usr/bin/env bash

echo "[+] Creating cleanup script"
cat << EOF > "$rootfs/cleanup"
#!/usr/bin/env sh

set -e

apt-get clean --yes
apt-get autoremove --yes --purge

rm -rv /usr/bin/qemu-$qemu_arch*

## REF: https://gitlab.com/kalilinux/build-scripts/kali-arm/-/blob/master/common.d/clean_system.sh
rm -rfv /0
rm -rfv /bsp
#command fc-cache && fc-cache -frs
rm -rfv /tmp/*
rm -rfv /etc/*-
rm -rfv /hs_err*
rm -rfv /etc/console-setup/cached_*
rm -rfv /userland
rm -rfv /opt/vc/src
rm -rfv /third-stage
rm -rfv /etc/ssh/ssh_host_*
rm -rfv /var/lib/dpkg/*-old
rm -rfv /var/lib/apt/lists/*
rm -rfv /var/cache/apt/*.bin
rm -rfv /var/cache/debconf/*-old
rm -rfv /var/cache/apt/archives/*
rm -rfv /etc/apt/apt.conf.d/apt_opts
rm -rfv /etc/apt/apt.conf.d/99_norecommends
for logs in \$( find /var/log -type f ); do echo \$logs; echo > \$logs; done
#history -cw
EOF

chmod +x "$rootfs/cleanup"
chroot_do /cleanup
rm -v "$rootfs/cleanup"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Add our sources (finished with $BUILD_MIRROR)
##   REF: https://www.kali.org/docs/general-use/updating-kali/
echo "[+] Defining stock /etc/apt/sources.list file"
cat << EOF > "$rootfs/etc/apt/sources.list"
# See: https://www.kali.org/docs/general-use/kali-linux-sources-list-repositories/
deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware

# Additional line for source packages
#deb-src http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF

## Sometimes we want to use kali-experimental
## Let's remove it after we are done with
if [ -n "$BUILD_REPO" ]; then
  echo "[+] Resetting /etc/apt/sources.list file"
  rm -v "$rootfs/etc/apt/sources.list.d/$BUILD_REPO.list"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Completed stage 4!"
