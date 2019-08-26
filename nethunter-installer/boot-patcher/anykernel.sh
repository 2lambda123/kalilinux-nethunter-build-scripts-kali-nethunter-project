# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

# Customized for NetHunter

## AnyKernel setup
# begin properties
properties() { '
kernel.string=
do.devicecheck=1
do.modules=
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
block=;
is_slot_device=1;
ramdisk_compression=;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## NetHunter additions

SYSTEM="/system"

setperm() {
	find "$3" -type d -exec chmod "$1" {} \;
	find "$3" -type f -exec chmod "$2" {} \;
}

install() {
	setperm "$2" "$3" "$home$1"
	if [ "$4" ]; then
		cp -r "$home$1" "$(dirname "$4")/"
		return
	fi
	cp -r "$home$1" "$(dirname "$1")/"
}

[ -d $home/system/etc/firmware ] && {
	install "/system/etc/firmware" 0755 0644 "$SYSTEM/etc/firmware"
}

[ -d $home/system/etc/init.d ] && {
	install "/system/etc/init.d" 0755 0755 "$SYSTEM/etc/init.d"
}

[ -d $home/system/lib ] && {
	install "/system/lib" 0755 0644 "$SYSTEM/lib"
}

[ -d $home/system/lib64 ] && {
	install "/system/lib64" 0755 0644 "$SYSTEM/lib64"
}

[ -d $home/system/bin ] && {
	install "/system/bin" 0755 0755 "$SYSTEM/bin"
}

[ -d $home/system/xbin ] && {
	install "/system/xbin" 0755 0755 "$SYSTEM/xbin"
}

[ -d $home/data/local ] && {
	install "/data/local" 0755 0644
}

## End NetHunter additions

## Trim partitions
fstrim -v /cache;
fstrim -v /data;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;

## AnyKernel install
dump_boot;

# begin ramdisk changes

if [ -d $ramdisk/.backup ]; then
  patch_cmdline "skip_override" "skip_override";
else
  patch_cmdline "skip_override" "";
fi;

# end ramdisk changes

write_boot;
## end install

