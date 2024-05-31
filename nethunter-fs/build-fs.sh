#!/bin/bash

## If we want to install packages from kali-experimental, set this:
#build_repo=kali-experimental

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

display_help() {
  echo "Usage: $0 [arguments]"
  echo "  -f, --full      build a rootfs with all the recommended packages"
  echo "  -m, --minimal   build a rootfs with only the most basic packages"
  echo "  -n, --nano      build a rootfs with only necessary packages for watch"
  echo "  -a, --arch      select a different architecture (default: armhf)"
  echo "                  possible options: armhf, arm64, i386, amd64"
  echo "  -h, --help      display this help message"
  exit 0
}

exit_help() {
  echo "[-] Error: $1"
  exit 1
}

## OS check
os_check() {
  if [ -f /etc/SUSE-brand ]; then
    suse=true
  fi
}

## Package dependency checks, whats required to build rather than whats inside the chroot/filesystem
##   If editing, needs to match whats in ./Dockerfile, ./README.md and ./build-fs.sh
dep_check() {
  debian_deps="binfmt-support
               ca-certificates
               curl
               debootstrap
               qemu-user-static
               xz-utils"
  suse_deps="gpg2 flex bison gperf zip curl libncurses6 glibc-devel-32bit
    parted kpartx pixz qemu-linux-user abootimg vboot bc xz lzop automake autoconf m4 dosfstools rsync u-boot-tools
    schedtool e2fsprogs dtc ccache dos2unix debootstrap dpkg"

  if [ "$suse" = true ]; then
    for dep in $suse_deps; do
      echo "[+] Checking for installed dependency: $dep"
      if ! rpm -q $dep; then
        echo "[-] Missing dependency: $dep"
        echo "[+] Attempting to install"
        zypper in -y "$dep"
      fi
    done
  else
    pkg_missing=""
    for dep in $debian_deps; do
      echo "[+] Checking for installed dependency: $dep"
      if ! dpkg-query -W --showformat='${Status}\n' "$dep" | grep -q "install ok installed"; then
        echo "[-] Missing dependency: $dep"
        pkg_missing="$pkg_missing $dep"
      fi
    done
    if [ -n "$pkg_missing" ]; then
      apt-get update
      for dep in $pkg_missing; do
        echo "[+] Attempting to install: $dep"
        apt-get install --yes "$dep"
      done
    fi
  fi

  echo "[+] All done! Creating hidden file .dep_check so we don't have preform check again"
  touch .dep_check
}

cleanup_host() {
  umount -v -l "$rootfs/dev/pts" &>/dev/null
  umount -v -l "$rootfs/dev" &>/dev/null
  umount -v -l "$rootfs/proc" &>/dev/null
  umount -v -l "$rootfs/sys" &>/dev/null

  ## Remove read only from nano
  chattr -i $(which nano)
}

chroot_do() {
  DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
  LC_ALL=C LANGUAGE=C LANG=C \
  chroot "$rootfs" "$@"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## no arguments provided? show help
if [ $# -eq 0 ]; then
  display_help
fi

## process arguments
while [[ $# -gt 0 ]]; do
  arg=$1
  case $arg in
    -h|--help)
      display_help
      ;;
    -f|--full)
      build_size=full
      ;;
    -m|--minimal)
      build_size=minimal
      ;;
    -n|--nano)
      build_size=nano
      ;;
    -a|--arch)
      case $2 in
        armhf|arm64|i386|amd64)
          build_arch=$2
          ;;
        *)
          exit_help "Unknown architecture: $2"
          ;;
      esac
      shift
      ;;
    *)
      exit_help "Unknown argument: $arg"
      ;;
  esac
  shift
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Check for root
if [[ $EUID -ne 0 ]]; then
  exit_help "Please run this as root"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

[ "$build_size" ] || exit_help "Build size not specified!"

## Set default architecture for most Android devices if not specified
[ "$build_arch" ] || build_arch=armhf

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rootfs="kali-$build_arch"
build_output="output/kalifs-$build_arch-$build_size"

mkdir -pv output/

## Capture all output from here on in kalifs-*.log
##   What would be nice is if able to detect if moreutils is installed, then pipe to `| ts -s`
exec &> >(tee -a "${build_output}.log")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Selected build size: $build_size"
echo "[+] Selected architecture: $build_arch"
if [ -n "$build_repo" ]; then
  echo "[+] Additional apt repo: $build_repo"
fi
sleep 1

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

os_check

## Run dependency check once (see above for dep check)
if [ ! -f ".dep_check" ]; then
  dep_check
else
  echo "[+] Dependency check previously conducted. To rerun remove file .dep_check"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -d "$rootfs" ]; then
  echo "[i] Detected prebuilt chroot"
  echo
  read -rp "Would you like to create a new chroot? (Y/n): " createrootfs
  case $createrootfs in
  n*|N*)
    echo "[i] Exiting"
    exit
    ;;
  *)
    echo "[i] Removing previous chroot"
    rm -rfv "$rootfs"
    ;;
  esac
else
  echo "[i] Previous rootfs build not found. Ready to build"
  sleep 1
fi

if [ -f "${build_output}.tar.xz" ]; then
  echo "[i] Detected previously created chroot output file: ${build_output}.tar.xz"
  echo
  read -rp "Would you like to create a new file? (Y/n): " createnewxz
  case $createnewxz in
  n*|N*)
    echo "[i] Exiting"
    exit
    ;;
  *)
    echo "[i] Removing previous chroot"
    rm -fv "${build_output}.tar.xz" "${build_output}.sha512sum"
    ;;
  esac
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Packages that will be installed inside the chroot/filesystem

## NANO PACKAGES - only necessary packages for watch
pkg_nano="kali-menu wpasupplicant kali-defaults initramfs-tools u-boot-tools nmap
  openssh-server kali-archive-keyring apt-transport-https ntpdate usbutils pciutils sudo vim git-core binutils ca-certificates
  locales console-common less nano git bluetooth bluez
  bluez-tools bluez-obexd libbluetooth3 sox spooftooph libbluetooth-dev
  redfang bluelog blueranger hcitool usbutils net-tools iw aircrack-ng
  nethunter-utils apache2 zsh abootimg cgpt fake-hwclock vboot-utils vboot-kernel-utils python3 pixiewps python2.7-minimal"

## NANO PACKAGES - only necessary packages for watch
# - apt-transport-https for updates
# - usbutils and pciutils is needed for wifite (unsure why)
pkg_minimal="locales-all openssh-server kali-defaults kali-archive-keyring
  apt-transport-https ntpdate usbutils pciutils sudo vim python2.7-minimal"

# DEFAULT PACKAGES FULL INSTALL
pkg_full="kali-linux-nethunter proxmark3"

# ARCH SPECIFIC PACKAGES
pkg_nano_armhf=""
pkg_nano_arm64=""
pkg_nano_i386=""
pkg_nano_amd64=""

pkg_minimal_armhf="abootimg cgpt fake-hwclock vboot-utils vboot-kernel-utils nethunter-utils zsh"
pkg_minimal_arm64="$pkg_minimal_armhf"
pkg_minimal_i386="$pkg_minimal_armhf"
pkg_minimal_amd64="$pkg_minimal_armhf"

pkg_full_armhf=""
pkg_full_arm64=""
pkg_full_i386=""
pkg_full_amd64=""

# Set packages to install by arch and size
case $build_arch in
  armhf)
    qemu_arch=arm
    packages="$pkg_minimal $pkg_minimal_armhf"
    [ "$build_size" = full ] &&
      packages="$packages $pkg_full $pkg_full_armhf"
    [ "$build_size" = nano ] &&
      packages="$pkg_nano"
    ;;
  arm64)
    qemu_arch=aarch64
    packages="$pkg_minimal $pkg_minimal_arm64"
    [ "$build_size" = full ] &&
      packages="$packages $pkg_full $pkg_full_arm64"
    [ "$build_size" = nano ] &&
      packages="$pkg_nano"
    ;;
  i386)
    qemu_arch=i386
    packages="$pkg_minimal $pkg_minimal_i386"
    [ "$build_size" = full ] &&
      packages="$packages $pkg_full $pkg_full_i386"
    [ "$build_size" = nano ] &&
      packages="$pkg_nano"
    ;;
  amd64)
    qemu_arch=x86_64
    packages="$pkg_minimal $pkg_minimal_amd64"
    [ "$build_size" = full ] &&
      packages="$packages $pkg_full $pkg_full_amd64"
    [ "$build_size" = nano ] &&
      packages="$pkg_nano"
    ;;
esac

# Fix packages to be a single space delimited line using unquoted magic
packages=$(echo $packages)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## It's dangerous to leave these mounted if user cleans git after using Ctrl+C
trap cleanup_host EXIT

## Need to find where this error occurs, but we make nano read only during build and reset after installation is completed
chattr +i $(which nano)

export build_arch build_size qemu_arch rootfs packages
export -f chroot_do

## Stage 1 - Debootstrap creates basic chroot
echo "[+] Starting stage 1 (debootstrap)"
. stages/stage1

## Stage 2 - Adds repo, bash_profile, hosts file
echo "[+] Starting stage 2 (repo/config)"
. stages/stage2

## Stage 3 - Downloads all packages, modify configuration files
echo "[+] Starting stage 3 (packages/installation)"
. stages/stage3

## Stage 4 - Cleanup stage
echo "[+] Starting stage 4 (cleanup)"
. stages/stage4

## Unmount and fix nano
cleanup_host

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Compress final file
echo "[+] Tarring and compressing kalifs. This can take a while..."
XZ_OPTS=-9 tar cJf "${build_output}.tar.xz" "$rootfs/"

echo "[+] Generating sha512sum of kalifs"
sha512sum "${build_output}.tar.xz" | sed "s|output/||" > "${build_output}.sha512sum"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Finish
echo "[+] Finished!  Check output folder for chroot"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Extract on device
## xz -dc /sdcard/kalifs.tar.xz | tar xvf - -C /data/local/nhsystem
## or
## tar xJvf /sdcard/kalifs.tar.xz -C /data/local/nhsystem
