#!/sbin/sh
# Install NetHunter's busybox

tmp=$(readlink -f "$0")
tmp=${tmp%/*/*}
. "$tmp/env.sh"

console=$(cat /tmp/console)
[ "$console" ] || console=/proc/$$/fd/1

print() {
	echo "ui_print - $1" > $console
	echo
}

BB=$tmp/tools/busybox_nh
xbin=/system/xbin
chmod 755 $BB

print "Installing busybox..."
rm -f $xbin/busybox_nh
cp "$tmp/tools/busybox_nh" $xbin/busybox_nh
chmod 0755 $xbin/busybox_nh
$xbin/busybox_nh --install -s $xbin 2>/dev/null

print "Installing legacy busybox as fall back..."
rm -f $xbin/busybox_nh-1.25
cp "$tmp/tools/busybox_nh-1.25" $xbin/busybox_nh-1.25
chmod 0755 $xbin/busybox_nh-1.25

[ -e $xbin/busybox ] || {
	print "$xbin/busybox not found! Symlinking..."
	$BB ln -sf $xbin/busybox_nh $xbin/busybox 2>/dev/null
}
