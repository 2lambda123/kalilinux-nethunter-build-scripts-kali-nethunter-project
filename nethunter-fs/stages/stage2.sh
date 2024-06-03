#!/usr/bin/env bash

if [ -n "$BUILD_REPO" ]; then
  echo "[i] Creating /etc/apt/sources.list.d/$BUILD_REPO.list file"
  cat << EOF > "$rootfs_dir/etc/apt/sources.list.d/$BUILD_REPO.list"
deb http://http.kali.org/kali $BUILD_REPO main contrib non-free non-free-firmware
EOF
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Fix for TUN symbolic link to enable programs like openvpn
## Set terminal length to 80 because root destroy terminal length
## Add fd to enable stdin/stdout/stderr
echo "[i] Creating /root/.bash_profile file"
cat << EOF > "$rootfs_dir/root/.bash_profile"
export TERM=xterm-256color
stty columns 80
cd /root
if [ ! -d /dev/net ]; then
  mkdir -pv /dev/net
  ln -sfv /dev/tun /dev/net/tun
fi

if [ ! -d /dev/fd ]; then
  ln -sfv /proc/self/fd /dev/fd
  ln -sfv /dev/fd/0 /dev/stdin
  ln -sfv /dev/fd/1 /dev/stdout
  ln -sfv /dev/fd/2 /dev/stderr
fi
EOF

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Create hosts file
echo "[i] Creating /etc/hosts file"
cat << EOF > "$rootfs_dir/etc/hosts"
127.0.0.1       localhost
127.0.1.1       kali

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
EOF

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Create default capture folders along with /sdcard, /external_sd, /system, /root/.ssh
echo "[i] Creating /root/.ssh directory"
mkdir -pv "$rootfs_dir/root/.ssh"

echo "[i] Creating /root/.vnc directory"
mkdir -pv "$rootfs_dir/root/.vnc"

echo "[i] Creating /etc/skel/.vnc directory"
mkdir -pv "$rootfs_dir/etc/skel/.vnc"

echo "[i] Creating /sdcard, /external_sd, /system mountpoints"
mkdir -pv "$rootfs_dir/external_sd" \
          "$rootfs_dir/sdcard" \
          "$rootfs_dir/system"

echo "[i] Creating /captures directories"
cap="$rootfs_dir/captures"
mkdir -pv "$cap/dsniff" \
          "$cap/ettercap" \
          "$cap/evilap" \
          "$cap/honeyproxy" \
          "$cap/kismet/db" \
          "$cap/mana/sslsplit" \
          "$cap/nmap" \
          "$cap/sslstrip" \
          "$cap/tcpdump" \
          "$cap/tshark" \
          "$cap/urlsnarf" \
          "$cap/wifite"

## Link /lib/modules to /system/lib/modules for modprobe
echo "[i] Creating mountpoint /lib/modules"
mkdir -pv "$rootfs_dir/lib/modules"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Completed stage 2!"
