# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

# Customized for NetHunter

## AnyKernel setup
# begin properties
properties() { '
kernel.string=
do.devicecheck=0#Use value 1 while using boot-patcher standalone
do.modules=1
do.systemless=0#Never use this for NetHunter kernels as it prevents us from writing to /lib/modules
do.cleanup=0
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
device.name6=
device.name7=
device.name8=
device.name9=
device.name10=
supported.versions=
'; } # end properties

# shell variables

#NetHunter Addition
ramdisk_compression=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## NetHunter additions

SYSTEM="/system";
SYSTEM_ROOT="/system_root";
file_contexts="$ramdisk/file_contexts";

setperm() {
	find "$3" -type d -exec chmod "$1" {} \;
	find "$3" -type f -exec chmod "$2" {} \;
}

install() {
	setperm "$2" "$3" "$home$1";
	if [ "$4" ]; then
		cp -r "$home$1" "$(dirname "$4")/";
		return;
	fi;
	cp -r "$home$1" "$(dirname "$1")/";
}

print() {
	if [ "$1" ]; then
		echo "ui_print -- $1" > "$console"
	else
		echo "ui_print  " > "$console"
	fi
	echo
}

# replace a file, preserving metadata (using cat)
replace_file() {
	cat "$2" > "$1" || return
	rm -f "$2"
}

# use this to set selinux contexts of file paths
context_set() {
	$found_file_contexts || return
	awk -vfile="$1" -vcontext="$2" '
		function pfcon() {
			printf "%-48s %s\n", file, context
			set = 1
		}
		$1 == file && !set { pfcon() }
		$1 == file { next }
		{ print }
		END { if (!set) pfcon() }
	' "$file_contexts" > "$file_contexts-"
	replace_file "$file_contexts" "$file_contexts-"
}

[ -d $home/system/etc/firmware ] && {
	install "/system/etc/firmware" 0755 0644 "$SYSTEM/etc/firmware";
}

[ -d $home/system/etc/init.d ] && {
	install "/system/etc/init.d" 0755 0755 "$SYSTEM/etc/init.d";
}

[ -d $home/system/lib ] && {
	install "/system/lib" 0755 0644 "$SYSTEM/lib";
}

[ -d $home/system/lib64 ] && {
	install "/system/lib64" 0755 0644 "$SYSTEM/lib64";
}

[ -d $home/system/bin ] && {
	install "/system/bin" 0755 0755 "$SYSTEM/bin";
}

[ -d $home/system/xbin ] && {
	install "/system/xbin" 0755 0755 "$SYSTEM/xbin";
}

[ -d $home/data/local ] && {
	install "/data/local" 0755 0644;
}

[ -d $home/ramdisk-patch ] && {
	setperm "0755" "0750" "$home/ramdisk-patch";
        chown root:shell $home/ramdisk-patch/*;
	cp -rp $home/ramdisk-patch/* "$SYSTEM_ROOT/";
}

if [ ! "$(grep /init.nethunter.rc $SYSTEM_ROOT/init.rc)" ]; then
  insert_after_last "$SYSTEM_ROOT/init.rc" "import .*\.rc" "import /init.nethunter.rc";
fi;

if [ ! "$(grep /dev/hidg* $SYSTEM_ROOT/ueventd.rc)" ]; then
  insert_after_last "$SYSTEM_ROOT/ueventd.rc" "/dev/kgsl.*root.*root" "# HID driver\n/dev/hidg* 0666 root root";
fi;

for p in $(find ak_patches/ -type f); do
  ui_print "- Applying $p";
  . $p;
done;

## End NetHunter additions


## AnyKernel file attributes
##set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;


## AnyKernel install
dump_boot;

#This part has no effect on SAR devices
ui_print "- Patching the ramdisk for NetHunter & init.d...";
# begin ramdisk changes
patch_prop "$ramdisk/default.prop" "ro.adb.secure" "1";
patch_prop "$ramdisk/default.prop" "ro.secure" "1";

import_rc init.nethunter.rc

# ensure /dev/hidg0 and /dev/hidg1 have the correct access rights
patch_ueventd "$ramdisk/ueventd.rc" "/dev/hidg*" "0666" "root" "root"

found_file_contexts=false
[ -f "$file_contexts" ] && found_file_contexts=true
context_set "/dev/hidg[0-9]*" "u:object_r:input_device:s0"


# migrate from /overlay to /overlay.d to enable SAR Magisk
if [ -d $ramdisk/overlay ]; then
  rm -rf $ramdisk/overlay;
fi;

if [ -d $ramdisk/.backup ]; then
  patch_cmdline "skip_override" "skip_override";
else
  patch_cmdline "skip_override" "";
fi;

# end ramdisk changes

write_boot;
## end install

