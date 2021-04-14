# Diffusion Installer Core (DO NOT CHANGE)
# osm0sis @ xda-developers
# Modified for NetHunter (Magisk Flashing Support Only)

# keep Magisk's forced module installer backend involvement minimal (must end without ;)
SKIPUNZIP=1

# Define Several Variables 
[ -z $TMPDIR ] && TMPDIR=/dev/tmp;
[ ! -z $ZIP ] && { ZIPFILE="$ZIP"; unset ZIP; }
[ -z $ZIPFILE ] && ZIPFILE="$3";
DIR=$(dirname "$ZIPFILE");
TMP=$TMPDIR/$MODID;

# Magisk Manager/booted flashing support
[ -e /data/adb/magisk ] && ADB=adb;
OUTFD=/proc/self/fd/0;
if [ -e /data/$ADB/magisk ]; then
   [ -e /magisk/.core/busybox ] && MAGISKBB=/magisk/.core/busybox;
   [ -e /sbin/.core/busybox ] && MAGISKBB=/sbin/.core/busybox;
   [ -e /sbin/.magisk/busybox ] && MAGISKBB=/sbin/.magisk/busybox;
   [ -e /dev/*/.magisk/busybox ] && MAGISKBB=$(echo /dev/*/.magisk/busybox);
   [ "$MAGISKBB" ] && export PATH="$MAGISKBB:$PATH";
fi;

# Define Modules target Dirs
if [ -e /data/adb/modules ]; then
   MNT=/data/adb/modules_update;
   MAGISK=/$MODID/system;
fi;

# set target paths
[ ! -z $MODPTH ] || MODPATH=$MNT/$MODID
   TARGET=$MNT$MAGISK;
   ETC=$TARGET/etc;
   BIN=$TARGET/bin;
   XBIN=$TARGET/xbin;
   MEDIA=$TARGET/media;

ui_print() {
    echo "$1";
}

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  CON=$5
  [ -z $CON ] && CON=u:object_r:system_file:s0
  chcon $CON $1 || return 1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

symlink() {
	ln -sf "$1" "$2" 2>/dev/null;
	chmod 755 $2 2>/dev/null;
}

UMASK=$(umask);
umask 022;

# ensure zip installer shell is in a working scratch directory
mkdir -p $TMPDIR;
cd $TMPDIR;
# source custom installer functions and configuration
unzip -jo "$ZIPFILE" tools/module.prop -d $TMPDIR;
MODID=$(file_getprop module.prop id);

# Print Kali NetHunter Banner In Magisk Installation Terminal
ui_print "##################################################"
ui_print "##                                              ##"
ui_print "##  88      a8P         db        88        88  ##"
ui_print "##  88    .88'         d88b       88        88  ##"
ui_print "##  88   88'          d8''8b      88        88  ##"
ui_print "##  88 d88           d8'  '8b     88        88  ##"
ui_print "##  8888'88.        d8YaaaaY8b    88        88  ##"
ui_print "##  88P   Y8b      d8''''''''8b   88        88  ##"
ui_print "##  88     '88.   d8'        '8b  88        88  ##"
ui_print "##  88       Y8b d8'          '8b 888888888 88  ##"
ui_print "##                                              ##"
ui_print "####  ############# NetHunter ####################"

# Extract the uninstaller
ui_print "Unpacking the installer...";
mkdir -p $TMPDIR/$MODID;
cd $TMPDIR/$MODID;
unzip -qq "$ZIPFILE" -x "kalifs-*";

# setup environment before Installations
# Mount System as r/w just incase we need it
  DYNAMIC=false;
  SAR=false;
     if [ -d /dev/block/mapper ]; then
          for block in system; do
            for slot in "" _a _b; do
              blockdev --setrw /dev/block/mapper/$block$slot 2>/dev/null;
            done;
          done;
    DYNAMIC=true;
    fi;
mount -o rw,remount -t auto /system || mount /system;
[ $? != 0 ] && mount -o rw,remount -t auto / && SAR=true;
 
# Additional setup for installing apps via pm
 [[ "$(getenforce)" == "Enforcing" ]] && ENFORCE=true || ENFORCE=false
 ${ENFORCE} && setenforce 0
 VERIFY=$(settings get global verifier_verify_adb_installs)
 settings put global verifier_verify_adb_installs 0
 
# Uninstall previous apps and binaries module if they are installed
ui_print "Checking for previous version of NetHunter apps and files";
pm uninstall  com.offsec.nethunter &> /dev/null
pm uninstall  com.offsec.nethunter.kex &> /dev/null
pm uninstall  com.offsec.nhterm &> /dev/null
pm uninstall  com.offsec.nethunter.store &> /dev/null

# Remove Osmosis busybox module
[ -d /data/adb/modules/busybox-ndk ] && {
   # Follow Magisk way to disable and remove modules
   touch /data/adb/modules/busybox-ndk/disable
   touch /data/adb/modules/busybox-ndk/remove
}

# Remove Wifi Firmware Modules
[ -d /data/adb/modules/wirelessFirmware ] && {
   # Follow Magisk way to disable and remove modules
   touch /data/adb/modules/wirelessFirmware/disable
   touch /data/adb/modules/wirelessFirmware/remove
}


# Remove Nano Modules
[ -d /data/adb/modules/nano-ndk ] && {
   # Follow Magisk way to disable and remove modules
   touch /data/adb/modules/nano-ndk/disable
   touch /data/adb/modules/nano-ndk/remove
}

# Install All NetHunter Apps as /data app in Dynamic
# system apps work but breaks  many things
# Don't try to make system apps
ui_print "Installing apps...";

# Starting with Oreo we can no longer install user apps so we install NetHunter.apk as system app
ui_print "- Installing NetHunter.apk"
pm install $TMP/data/app/NetHunter.apk &>/dev/null

# and NetHunterTerminal.apk because nethunter.apk depends on it
ui_print "- Installing NetHunterTerminal.apk"
pm install $TMP/data/app/NetHunterTerminal.apk &>/dev/null

# and NetHunterKeX.apk because nethunter.apk depends on it
ui_print "- Installing NetHunter-KeX.apk"
pm install $TMP/data/app/NetHunterKeX.apk &>/dev/null

# and NetHunterStore.apk because we need it 
ui_print "- Installing NetHunter-Store.apk"
pm install $TMP/data/app/NetHunterStore.apk &>/dev/null

## Installing privileged extension as system app
# We don't need privileged extension apk in dynamic devices
# It makes system error when installing apk from store
# Note: Don't include it(whoever later do contribution:)
ui_print "Done installing apps";


# Install Kali NetHunter Busybox's
# As We Are Using Magisk to Flash, if Osmosis's busybox is installed,
# then nethunter busybox may conflict with osmOsis's busybox
# check if Osmosis Busybox is installed or not
# if installed, then remove that(in magisk way) and install Nethunter busybox_nh-*
mkdir -p $XBIN

ui_print "Installing NetHunter BusyBox..."
cd $TMP/tools
bb_list=$(ls busybox_nh-*)
for bb in $bb_list; do 
    ui_print "Installing $bb..."
    rm -f $XBIN/$bb 2>/dev/null
    cp -f $bb $XBIN/$bb
    chmod 0755 $XBIN/$bb;
done

busybox_latest=`(ls -v busybox_nh-* ) | tail -n 1`
ui_print "Setting $busybox_latest as default"
cp -f $XBIN/$busybox_latest $XBIN/busybox_nh 2>/dev/null
chmod 0755 $XBIN/busybox_nh
#Do Symlink applets with latest busybox_nh
cd $XBIN
for applet in $($XBIN/busybox_nh --list); do
    $XBIN/busybox_nh ln -sf busybox_nh $applet
done


[ -e $XBIN/busybox ] || {
	ui_print "/system/xbin/busybox not found! Symlinking..."
	# ln -sf busybox does not work on magisk modules. Copy the Busybox instead.
	cp -f $XBIN/$busybox_latest $XBIN/busybox
	chmod 0755 $XBIN/busybox
}
set_perm_recursive "$XBIN" 0 0 0755 0755
cd $TMP


# SetUp Kali NetHunter wallpaper of Correct Resolution if there is one available
set_wallpaper() {
[ -d $TMP/wallpaper ] || return 1
	ui_print "Installing NetHunter wallpaper";
 	
#Define wallpaper Variables
wp=/data/system/users/0/wallpaper
wpinfo=${wp}_info.xml
 
#Get Screen Resolution Using Wm size
res=$(wm size | grep "Physical size:" | cut -d' ' -f3 2>/dev/null)
res_w=$(wm size | grep "Physical size:" | cut -d' ' -f3 | cut -dx -f1 2>/dev/null)
res_w=$(wm size | grep "Physical size:" | cut -d' ' -f3 | cut -dx -f2 2>/dev/null)

#check if we grabbed Resolution from wm or not
[ -z $res_h -o -z $res_w ] && {
unset res res_h res_w

#Try to Grab the Wallpaper Height and Width from sysfs
res_w=$(cat /sys/class/drm/*/modes | head -n 1 | cut -f1 -dx)
res_h=$(cat /sys/class/drm/*/modes | head -n 1 | cut -f2 -dx)

res="$res_w"x"$res_h" #Resolution Size
}

[ ! "$res" ] && {
ui_print "Can't get screen resolution of Device! Skipping..."
return 1
}

ui_print "Found screen resolution: $res"

[ ! -f "$TMP/wallpaper/$res.png" ] && {
	ui_print "No wallpaper found for your screen resolution. Skipping..."
	return 1;
}

[ -f "$wp" ] && [ -f "$wpinfo" ] || setup_wp=1

cat "$TMP/wallpaper/$res.png" > "$wp"
echo "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>" > "$wpinfo"
echo "<wp width=\"$res_w\" height=\"$res_h\" name=\"nethunter.png\" />" >> "$wpinfo"

if [ "$setup_wp" ]; then
	chown system:system "$wp" "$wpinfo"
	chmod 600 "$wp" "$wpinfo"
	chcon "u:object_r:wallpaper_file:s0" "$wp"
	chcon "u:object_r:system_data_file:s0" "$wpinfo"
fi

ui_print "NetHunter wallpaper applied successfully"

}

set_wallpaper;

# Install Required Firmwares, Binaries, lib files for Kali NetHunter
# Warning: Do not Include Bootanimation in Magisk mdoule (I repeat!!)
[ -d $TMP/system/etc/nano ] && {
	ui_print "Copying nano highlights to /system/etc/nano"
    mkdir -p $ETC;
    cp -r "$TMP/system/etc/nano" "$ETC/"
    set_perm_recursive "$ETC/nano" 0 0 0755 0644
}

[ -d $TMP/system/etc/terminfo ] && {
	ui_print "Copying terminfo files to /system/etc/terminfo"
	mkdir -p $ETC;
    cp -r "$TMP/system/etc/terminfo" "$ETC/"
    set_perm_recursive "$ETC/terminfo" 0 0 0755 0644

}

[ -d $TMP/boot-patcher/system/etc/firmware ] && {
	ui_print "Copying Wifi firmwares to /system/etc/firmware"
	mkdir -p $ETC;
    cp -r "$TMP/system/etc/firmware" "$ETC/"
    set_perm_recursive "$ETC/firmware" 0 0 0755 0644
}

[ -d $TMP/system/lib ] && {
    ui_print "Copying 32-bit shared libraries to /system/lib"
    cp -r "$TMP/system/lib" "$TARGET/"
    set_perm_recursive "$TARGET/lib" 0 0 0755 0644

}

[ -d $TMP/system/lib64 ] && {
	ui_print "Copying 64-bit shared libraries to /system/lib64"
    cp -r "$TMP/system/lib64" "$TARGET/"
    set_perm_recursive "$TARGET/lib64" 0 0 0755 0644

}

[ -d $TMP/system/bin ] && {
    ui_print "Installing /system/bin binaries"
	cp -r "$TMP/system/bin" "$TARGET/"
	set_perm_recursive "$BIN" 0 0 0755 0755
}

[ -d $TMP/system/xbin ] && {
	ui_print "Installing /system/xbin binaries"
    cp -r "$TMP/system/xbin" "$TARGET/"
    set_perm_recursive "$XBIN" 0 0 0755 0755
}

[ -d $TMP/boot-patcher/system/xbin ] && {
	ui_print "Installing hid-keyboard to /system/xbin"
    cp -r "$TMP/boot-patcher/system/xbin" "$TARGET/"
    set_perm_recursive "$XBIN" 0 0 0755 0755
}

[ -d $TMP/data/local ] && {
	ui_print "Copying additional files to /data/local"
    mkdir -p /data/local
    cp -r "$TMP/data/local/*" "/data/local/"
    set_perm_recursive "/data/local" 0 0 0755 0644

}

[ -d $TMP/system/etc/init.d ] && {
    ui_print "Installing init.d scripts"
    cp -r "$TMP/system/etc/init.d" "$ETC/"
	# Create userinit.d and userinit.sh if they don't already exist
	rm -rf /data/local/userinit.d #Remove Previous One
	mkdir -p "/data/local/userinit.d"
	[ -f "/data/local/userinit.sh" ] || echo "#!/system/bin/sh" > "/data/local/userinit.sh"
	chmod 0755 "/data/local/userinit.sh"
	set_perm_recursive "$ETC/init.d" 0 0 0755 0644

}
 
[ -e $TMP/system/addon.d/80-nethunter.sh ] && {
	ui_print "Installing /system/addon.d backup scripts"
	mkdir -p "$TARGET/addon.d"
    cp "$TMP/system/addon.d/80-nethunter.sh" "$TARGET/"
	cp "$TMP/system/addon.d/80-nethunter.sh" "$TARGET/addon.d/"
	set_perm_recursive "$TARGET/addon.d" 0 0 0755 0644

}


# Symlink Bootkali Scripts for Using in Another Terminals
ui_print "Symlinking Kali boot scripts";
symlink "/data/data/com.offsec.nethunter/files/scripts/bootkali" "$TARGET/bin/bootkali"
symlink "/data/data/com.offsec.nethunter/files/scripts/bootkali_init" "$TARGET/bin/bootkali_init"
symlink "/data/data/com.offsec.nethunter/files/scripts/bootkali_login" "$TARGET/bin/bootkali_login"
symlink "/data/data/com.offsec.nethunter/files/scripts/bootkali_bash" "$TARGET/bin/bootkali_bash"
symlink "/data/data/com.offsec.nethunter/files/scripts/killkali" "$TARGET/bin/killkali"
set_perm_recursive "$BIN" 0 0 0755 0755

do_chroot() {
# Chroot Common Path    
NHSYS=/data/local/nhsystem

verify_fs() {
	# valid architecture?
	case $FS_ARCH in
		armhf|arm64|i386|amd64) ;;
		*) return 1 ;;
	esac
	# valid build size?
	case $FS_SIZE in
		full|minimal) ;;
		*) return 1 ;;
	esac
	return 0
}

# do_install [optional zip containing kalifs]
do_install() {
	ui_print "Found Kali chroot to be installed: $KALIFS"

	mkdir -p "$NHSYS"

	# HACK 1/2: Rename According FS_ARCH cause NetHunter App supports searching for best available arch
	CHROOT="$NHSYS/kali-$FS_ARCH" # Legacy rootfs directory prior to 2020.1
	ROOTFS="$NHSYS/kalifs"     # New symlink allowing to swap chroots via nethunter app on the fly
    PRECHROOT=`find /data/local/nhsystem -type d -iname kali-* | head -n 1` # previous chroot location 
        
# Remove previous chroot
[ -d "$PRECHROOT" ] && {
ui_print "Previous Chroot Detected!!"

f_kill_pids() {
    local lsof_full=$(lsof | awk '{print $1}' | grep -c '^lsof')
    if [ "${lsof_full}" -eq 0 ]; then
        local pids=$(lsof | grep "$PRECHROOT" | awk '{print $1}' | uniq)
    else
        local pids=$(lsof | grep "$PRECHROOT" | awk '{print $2}' | uniq)
    fi
    if [ -n "${pids}" ]; then
        kill -9 ${pids} 2> /dev/null
        return $?
    fi
    return 0
}

f_restore_setup() {
    ## set shmmax to 128mb to free memory ##
    sysctl -w kernel.shmmax=134217728 2>/dev/null

    ## remove all the remaining chroot vnc session pid and log files..##
    rm -rf $PRECHROOT/tmp/.X11* $PRECHROOT/tmp/.X*-lock $PRECHROOT/root/.vnc/*.pid $PRECHROOT/root/.vnc/*.log > /dev/null 2>&1
}

f_umount_fs() {
    isAllunmounted=0
    if mountpoint -q $PRECHROOT/$1; then
        if umount -f $PRECHROOT/$1; then
            if [ ! "$1" = "dev/pts" -a ! "$1" = "dev/shm" ]; then
                if ! rm -rf $PRECHROOT/$1; then
                      isAllunmounted=1
                fi
            fi
        else
            isAllunmounted=1
        fi
    else
        if [ -d $PRECHROOT/$1 ]; then
            if ! rm -rf $PRECHROOT/$1; then
                  isAllunmounted=1
            fi
        fi
    fi

}

f_dir_umount() {
    sync
    ui_print "Killing all running pids.."
    f_kill_pids
    f_restore_setup
    ui_print "Removing all fs mounts.."
    for i in "dev/pts" "dev/shm" dev proc sys system sdcard ; do
        f_umount_fs "$i"
    done
}

f_is_mntpoint() {
    if [ -d "$PRECHROOT" ]; then
        mountpoint -q "$PRECHROOT" && return 0
        return 1
    fi
}

do_umount() {
     f_is_mntpoint
     res=$?
     case $res in
           1) f_dir_umount ;;
           *) return 0 ;;
     esac

if [ -z "$(cat /proc/mounts | grep $PRECHROOT)" ]; then
    ui_print "All done."
    isAllunmounted=0
else
    ui_print "there are still mounted points not unmounted yet."
    isAllunmounted=1
fi

return $isAllunmounted
}

do_umount;
[ $? == 1 ] && { 
    ui_print "Aborting Chroot Installations.."
    ui_print "Remove the Previous Chroot and install the new chroot via NetHunter App"
    return 1
}
    ui_print "Removing Previous chroot.."
	rm -rf "$PRECHROOT"
	rm -f "$ROOTFS"
	}

	# Extract new chroot
	ui_print "Extracting Kali rootfs, this may take up to 25 minutes..."
	unzip -p "$ZIPFILE" "$KALIFS" | tar -xJf - -C "$NHSYS" --exclude "kali-$FS_ARCH/dev"
	
	[ $? = 0 ] || {
		ui_print "Error: Kali $FS_ARCH $FS_SIZE chroot failed to install!"
		ui_print "Maybe you ran out of space on your data partition?"
		return 1
	}

	# HACK 2/2: create a link to be used by apps effective 2020.1
	ln -sf "$CHROOT" "$ROOTFS"

	mkdir -m 0755 "$CHROOT/dev"
	ui_print "Kali $FS_ARCH $FS_SIZE chroot installed successfully!"

	# We should remove the rootfs archive to free up device memory or storage space (if not zip install)
	[ "$1" ] || rm -f "$KALIFS"

	return 0
}

# Check zip for kalifs-* first
[ -e "$ZIPFILE" ] && {
	KALIFS=$(unzip -lqq "$ZIPFILE" | awk '$4 ~ /^kalifs-/ { print $4; exit }')
	# Check other locations if zip didn't contain a kalifs-*
	[ "$KALIFS" ] || {
	ui_print "No Kali rootfs found.Aborting...."
	return
    }
    
	FS_ARCH=$(echo "$KALIFS" | awk -F[-.] '{print $2}')
	FS_SIZE=$(echo "$KALIFS" | awk -F[-.] '{print $3}')
	verify_fs && do_install
}


}

do_chroot;

ui_print "************************************************"
ui_print "*       Kali NetHunter is now installed!       *"
ui_print "*   Don't forget to start the NetHunter app    *"
ui_print "*       to finish setting everything up!       *"
ui_print "************************************************"


# Random Important Magisk Stuff (Don't Remove)
cp -fp tools/module.prop $MNT/$MODID/;
touch $MNT/$MODID/auto_mount;
[ -e /data/adb/modules ] && IMGMNT=/data/adb/modules;
mkdir -p "$IMGMNT/$MODID";
touch "$IMGMNT/$MODID/update";
cp -fp tools/module.prop "$IMGMNT/$MODID/";

ui_print "Unmounting...";
cd /;

# restore environmet after Installations
if [ -d /dev/block/mapper ]; then
          for block in system; do
            for slot in "" _a _b; do
              blockdev --setro /dev/block/mapper/$block$slot 2>/dev/null;
            done;
          done;
fi;
[ "$SAR" ] && mount -o ro,remount -t auto / || mount -o ro,remount -t auto /system;

# Restore also additional settings we did before
settings put global verifier_verify_adb_installs ${VERIFY}
${ENFORCE} && setenforce 1

# clear up
rm -rf $TMPDIR;
umask $UMASK;
ui_print " ";
ui_print "Done!";
exit 0;

