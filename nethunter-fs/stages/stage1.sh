#!/usr/bin/env bash

mkdir -pv "$rootfs_dir/"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ ! -f /usr/share/debootstrap/scripts/kali ]; then
  ## For those not building on Debian 9 or older
  echo "[i] Missing kali from debootstrap, downloading it"

  curl "https://gitlab.com/kalilinux/packages/debootstrap/raw/kali/master/scripts/kali" > /usr/share/debootstrap/scripts/kali
  ln -sv /usr/share/debootstrap/scripts/kali /usr/share/debootstrap/scripts/$BUILD_BRANCH
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ "$( uname -m )" == "$qemu_arch" ]; then
  echo "[i] Bypassing qemu/binfmts: Selected arch is the as host: $qemu_arch"
elif [ "$( uname -m )" == "x86_64" ] && [ "$qemu_arch" == "i386" ]; then
  echo "[i] Bypassing qemu/binfmts: amd64/i386 == $( uname -m ) == $qemu_arch"
elif [ "$qemu_arch" == "i386" ] && ( [ "$( uname -m )" == "i486" ] || [ "$( uname -m )" == "i586" ] || [ "$( uname -m )" == "i686" ] ); then
  echo "[i] Bypassing qemu/binfmts: i*86"
else
  echo "[i] Host ($( uname -m )) is a different arch to selected arch ($qemu_arch)"
  ## Docker needs binfmt to run arm
  ##   Without below commands second-stage and chroot will fail
  ##   REF: https://web.archive.org/web/20191108143948/http://neophob.com/2014/10/run-arm-binaries-in-your-docker-container-using-boot2docker/
  if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
    echo "[+] binfmt_misc not mounted"
    mount -v binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
    if [ -e "/.dockerenv" ]; then
      ls -lh /proc/sys/fs/binfmt_misc/qemu-* >/dev/null || echo "[!] Try installing qemu-user-static on the host"
    fi
  fi

  echo "[+] Setting up binfmts"
  if [ "$suse" = true ]; then
    qemu-binfmt-conf.sh
  else
    update-binfmts --enable "qemu-$qemu_arch"
  fi
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Starting debootstrap (download)"
tries=0
max_tries=5
while ! debootstrap --download-only --verbose --arch $build_arch $BUILD_BRANCH "$rootfs_dir" $BUILD_MIRROR; do
  ((tries++))
  if [ $tries -ge $max_tries ]; then
    exit_help "maximum retries ($max_tries) reached, could not download packages!"
  fi
  echo "[!] Failed to download packages (attempt $tries/$max_tries), trying again in 5 minutes!"
  sleep 300s
done

echo "[+] Starting debootstrap (install)"
debootstrap --foreign --components main,contrib,non-free,non-free-firmware --verbose --arch $build_arch $BUILD_BRANCH "$rootfs_dir" $BUILD_MIRROR

echo "[+] Installing qemu-$qemu_arch-static interpreter to rootfs"
if [ "$suse" = true ]; then
  cp -v "/usr/bin/qemu-$qemu_arch-binfmt" "$rootfs_dir/usr/bin/"
  cp -v "/usr/bin/qemu-$qemu_arch" "$rootfs_dir/usr/bin/"
else
  cp -v "/usr/bin/qemu-$qemu_arch-static" "$rootfs_dir/usr/bin/"
fi

echo "[+] Starting debootstrap in chroot (second stage)"
chroot_do /debootstrap/debootstrap --second-stage

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Completed stage 1!"
