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

cd "$tmp/tools"
for bb in busybox_nh-*; do 
    print "Installing $bb..."
    rm -f $xbin/$bb
    cp $bb $xbin/$bb
    chmod 0755 $xbin/$bb
done

cd $xbin
rm -f busybox_nh
busybox_nh=`(/sbin/busybox_nh ls -v busybox_nh-* || ls busybox_nh-*) | tail -n 1`
print "Setting $busybox_nh as default"
ln -s $xbin/$busybox_nh busybox_nh
$xbin/busybox_nh --install -s $xbin


[ -e $xbin/busybox ] || {
	print "$xbin/busybox not found! Symlinking..."
	$BB ln -sf $xbin/busybox_nh $xbin/busybox 2>/dev/null
}
