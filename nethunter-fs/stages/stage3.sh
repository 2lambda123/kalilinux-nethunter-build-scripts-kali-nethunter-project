#!/usr/bin/env bash

echo "[+] Environments"
export MALLOC_CHECK_=0 # Workaround for LP: #520465 (https://bugs.launchpad.net/ubuntu/+bug/520465)
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Sometimes we might need to install packages that are not in the kali repository
## Copy packages from local repository to chroot for installation
echo "[+] DEBs"
mkdir -pv $rootfs_dir/tmp/deb/
if ls $rootfs_dir/../data/deb/$build_arch/*.deb &>/dev/null; then
  echo "[+] Copying $build_arch packages to chroot from local repository"
  cp -v $rootfs_dir/../data/deb/$build_arch/*.deb $rootfs_dir/tmp/deb/
fi
if ls $rootfs_dir/../data/deb/all/*.deb &>/dev/null; then
  echo "[+] Copying generic packages to chroot from local repository"
  cp -v $rootfs_dir/../data/deb/all/*.deb $rootfs_dir/tmp/deb/
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Mounts"
mount -v -t proc proc "$rootfs_dir/proc"
mount -v -o bind /dev "$rootfs_dir/dev"
mount -v -t devpts none "$rootfs_dir/dev/pts"   # mount -v -o bind /dev/pts "$rootfs_dir/dev/pts"
mount -v -t sysfs sys "$rootfs_dir/sys"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Prep"
cat << EOF > "$rootfs_dir/debconf.set"
console-common console-data/keymap/policy select Select keymap from full list
console-common console-data/keymap/full select en-latin1-nodeadkeys
EOF

cat << EOF > "$rootfs_dir/third-stage"
#!/usr/bin/env bash

set -e

dpkg-divert --add --local --divert /usr/sbin/invoke-rc.d.chroot --rename /usr/sbin/invoke-rc.d
cp -v /bin/true /usr/sbin/invoke-rc.d
echo -e "#!/bin/sh\nexit 101" > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

apt-get update

debconf-set-selections /debconf.set
rm -fv /debconf.set

echo "[i] Installing core packages"
apt-get --yes install $( echo "$pkg_core" | grep -v '!'${build_arch} | sed 's_\[.*\]__g' | xargs )

if [ -n "$BUILD_REPO" ]; then
  echo "[i] Installing packages from $BUILD_REPO with apt-get"
  apt-get -t $BUILD_REPO --yes install $packages
else
  echo "[i] Installing packages with apt-get"
  apt-get --yes install $packages
fi

rm -fv /usr/sbin/policy-rc.d
rm -fv /usr/sbin/invoke-rc.d
dpkg-divert --remove --rename /usr/sbin/invoke-rc.d

if [ "$build_size" == nano ]; then
  echo "[i] Skipping local repo of packages"
else
  echo "[i] Installing custom packages from local repo"
  ## Install custom packages from local repo
  if ls /tmp/deb/*.deb &>/dev/null; then
     #apt install --yes /tmp/deb/*.deb
     dpkg --install /tmp/deb/*.deb
     apt-get install --fix-broken
  fi
  if [ -d /tmp/deb ]; then
    rm -rfv /tmp/deb
  fi
fi

## Create group to permit vnc users to access sockets to avoid the following error:
## "vncserver: socket failed: Permission denied"
addgroup --gid 3003 sockets

## Create non-privileged user
groupadd -g 100000 kali
useradd -m -u 100000 -g 100000 -G sudo,sockets -s /usr/bin/zsh kali
echo "kali:kali" | chpasswd

## Switch to zsh as default shell
echo "[i] Changing default shell of user 'root' to zsh"
chsh --shell /usr/bin/zsh root
echo "root:toor" | chpasswd
EOF
## End of third-stage script

if [ "$build_size" = full ]; then
  cat << EOF >> "$rootfs_dir/third-stage"

## Enable PHP in Apache
# $ apachectl -M | grep -q php
a2query -m | grep -q php \
  && echo "PHP already enabled" \
  || a2enmod \$( dpkg -l | awk -F ' ' '/ php[0-9]+\.[0-9]+ / {print \$2}' )

## Enable /var/www/html as default, disable mana unless we need it
a2query -s | grep -q mana-toolkit \
  && a2dissite 000-mana-toolkit \
  || echo "mana-toolkit has already been disabled"
a2ensite 000-default
EOF
  ## End of third-stage script append
fi

chmod +x "$rootfs_dir/third-stage"
chroot_do /third-stage
rm -v "$rootfs_dir/third-stage"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ "$build_size" = full ]; then
  echo "[+] VNC"
  ## Add default xstartup file for tigervnc-standalone-server
  cat << EOF >> "$rootfs_dir/etc/skel/.vnc/xstartup"
#!/usr/bin/env sh

set -e

#############################
##          All            ##
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export SHELL=/bin/bash

#############################
##          Gnome          ##
#[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
#[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
#vncconfig -iconic &
#dbus-launch --exit-with-session gnome-session &


############################
##           LXQT         ##
####exec openbox-session
#exec startlxqt


############################
##          KDE           ##
#exec /usr/bin/startkde


############################
##          XFCE          ##
startxfce4
EOF
  chmod 0700 "$rootfs_dir/etc/skel/.vnc/xstartup"

  ## powershell for arm64 is not yet available in Microsofts repos so let's install it manually
  echo "[+] PowerShell"
  if [ $build_arch == "arm64" ]; then
    mkdir -pv $rootfs_dir/opt/microsoft/powershell
    wget -P $rootfs_dir/opt/microsoft/powershell https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.4/powershell-6.2.0-preview.4-linux-arm64.tar.gz
    tar -xzf $rootfs_dir/opt/microsoft/powershell/powershell-6.2.0-preview.4-linux-arm64.tar.gz -C $rootfs_dir/opt/microsoft/powershell
    rm -v $rootfs_dir/opt/microsoft/powershell/powershell-6.2.0-preview.4-linux-arm64.tar.gz
  fi
  if [ $build_arch == "armhf" ]; then
    mkdir -pv $rootfs_dir/opt/microsoft/powershell
    wget -P $rootfs_dir/opt/microsoft/powershell https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.4/powershell-6.2.0-preview.4-linux-arm32.tar.gz
    tar -xzf $rootfs_dir/opt/microsoft/powershell/powershell-6.2.0-preview.4-linux-arm32.tar.gz -C $rootfs_dir/opt/microsoft/powershell
    rm -v $rootfs_dir/opt/microsoft/powershell/powershell-6.2.0-preview.4-linux-arm32.tar.gz
  fi
  ## Microsoft no longer supports deletion of the file DELETE_ME_TO_DISABLE_CONSOLEHOST_TELEMETRY to disable telemetry
  ## We have to set this environment variable instead
  cat << EOF > "$rootfs_dir/etc/profile.d/powershell.sh"
export POWERSHELL_TELEMETRY_OPTOUT=1
EOF

  cat << EOF >> "$rootfs_dir/etc/bash.bashrc"
export POWERSHELL_TELEMETRY_OPTOUT=1
EOF
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Install dictionaries/wordlists
echo "[+] Dictionaries"
mkdir -pv "$rootfs_dir/opt/dic"
tar xvf ./data/dictionaries/89.tar.gz -C "$rootfs_dir/opt/dic"
cp -v ./data/dictionaries/wordlist.txt "$rootfs_dir/opt/dic/wordlist.txt"
cp -v ./data/dictionaries/pinlist.txt  "$rootfs_dir/opt/dic/pinlist.txt"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## In order for metasploit to work daemon,nginx,postgres must all be added to inet beef-xss creates user beef-xss.
## Openvpn server requires nobdy:nobody in order to work.
echo "[+] Groups"
cat << EOF >> "$rootfs_dir/etc/group"
inet:x:3004:postgres,root,beef-xss,daemon,nginx,mysql
nobody:x:3004:nobody
EOF

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Apt now adds a new user to "nobody" but the _apt user can't access updates because of inet
## Modify passwd to put them in inet group for android
echo "[+] Users"
sed -i -e 's/^\(_apt:\)\([^:]\)\(:[0-9]*\)\(:[0-9]*\):/\1\2\3:3004:/' "$rootfs_dir/etc/passwd"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Add /system/xbin and /system/bin to PATH
echo "[+] Adding /system/xbin and /system/bin to path"
cat << EOF >> "$rootfs_dir/root/.profile"
PATH="$PATH:/system/xbin:/system/bin"
EOF

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Source .bashrc and .profile at login
echo "[+] Adding bashrc/profile sourcing to bash_profile"
cat << EOF >> "$rootfs_dir/root/.bash_profile"
. /root/.bashrc
. /root/.profile
cd ~
EOF

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Insert correct .bashrc file from kali-defaults
echo "[+] bashrc"
cp -v $rootfs_dir/etc/skel/.bashrc $rootfs_dir/root/.bashrc

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Modify SSHD to allow password logins which is a security risk
## if the user doesn't change their password
## or change their configuration for key based ssh
echo "[+] Modifying SSH to allow root user"
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' "$rootfs_dir/etc/ssh/sshd_config"
sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/g' "$rootfs_dir/etc/ssh/sshd_config"
sed -i 's/\#PermitRootLogin yes/PermitRootLogin yes/g' "$rootfs_dir/etc/ssh/sshd_config"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## DNSMASQ Configuration options for optional access point
if [ -e "$rootfs_dir/etc/dnsmasq.conf" ]; then
  echo "[+] dnsmasq"
  cat << EOF > "$rootfs_dir/etc/dnsmasq.conf"
log-facility=/var/log/dnsmasq.log
#address=/#/10.0.0.1
#address=/google.com/10.0.0.1
interface=wlan1
dhcp-range=10.0.0.10,10.0.0.250,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
#no-resolv
log-queries
EOF
else
  echo "[i] Skipping dnsmasq"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Removing Xfce4 panel plugins that are not needed in KeX
if [ -e "$rootfs_dir/etc/xdg/xfce4/panel/default.xml" ]; then
  echo "[+] Removing unneeded xfce4 panel plugins"
  sed -i '/\n/!N;/\n.*\n/!N;/\n.*\n.*kazam/{$d;N;N;d};P;D' "$rootfs_dir/etc/xdg/xfce4/panel/default.xml"
  sed -i '/pulseaudio/d'                                   "$rootfs_dir/etc/xdg/xfce4/panel/default.xml"
  sed -i '/power-manager-plugin/d'                         "$rootfs_dir/etc/xdg/xfce4/panel/default.xml"
else
  echo "[i] Skipping xfce4"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Modify Kismet log saving folder
if [ -e "$rootfs_dir/etc/kismet/kismet.conf" ]; then
  echo "[+] Modifying Kismet log folder"
  sed -i 's|.*\blogprefix=.*|logprefix=/captures/kismet/|g' "$rootfs_dir/etc/kismet/kismet.conf"
  sed -i 's|.*\bncsource=wlan0|ncsource=wlan1|g'            "$rootfs_dir/etc/kismet/kismet.conf"
  sed -i 's|.*\bgpshost=.*|gpshost=127.0.0.1:2947|g'        "$rootfs_dir/etc/kismet/kismet.conf"
else
  echo "[i] Skipping Kismet"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -e "$rootfs_dir/etc/skel/.vnc/xstartup" ]; then
  echo "[+] VNC"
  cp -fv "$rootfs_dir/etc/skel/.vnc/xstartup" "$rootfs_dir/root/.vnc/xstartup"
else
  echo "[i] Skipping VNC"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Fix armitage to run on NetHunter
##   REF: https://github.com/offensive-security/kali-nethunter/issues/600
if [ -e "$rootfs_dir/usr/share/armitage/armitage" ]; then
  echo "[+] armitage"
  sed -i s/-XX\:\+AggressiveHeap//g "$rootfs_dir/usr/share/armitage/armitage"
else
  echo "[i] Skipping armitage"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Sets the default for hostapd.conf to the mana karma version
if [ -e "$rootfs_dir/etc/init.d/hostapd" ]; then
  echo "[+] hostapd"
  sed -i 's#^DAEMON_CONF=.*#DAEMON_CONF=/sdcard/nh_files/configs/hostapd-karma.conf#' "$rootfs_dir/etc/init.d/hostapd"
else
  echo "[i] Skipping hostapd"
fi


if [ -e $rootfs_dir/etc/mana-toolkit/ ]; then
  sed -i 's/wlan0/wlan1/g' "$rootfs_dir/etc/mana-toolkit/hostapd-mana-"*
else
  echo "[i] Skipping hostapd/mana-toolkit"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -e "$rootfs_dir/usr/share/mana-toolkit/run-mana/" ]; then
  echo "[+] mana-toolkit"
  chmod 0755 $rootfs_dir/usr/share/mana-toolkit/run-mana/*.sh

  ## Happens in hostapd
  #sed -i 's/wlan0/wlan1/g' "$rootfs_dir/etc/mana-toolkit/hostapd-mana-"*

  ## Minor fix for mana-toolkit which made changes in update
  ## We need to mirror fixes
  sed -i 's|dhcpd -cf /etc/mana-toolkit/dhcpd\.conf.*|dnsmasq -z -C /etc/mana-toolkit/dnsmasq-dhcpd.conf -i $phy -I lo|' "$rootfs_dir/usr/share/mana-toolkit/run-mana/"*
else
  echo "[i] Skipping mana-toolkit"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Completed stage 3!"
