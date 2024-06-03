#!/usr/bin/env bash
## $ ./$0 --help
## $ BUILD_MIRROR=http://kali.download ./$0 --full

## If we want to install packages from kali-experimental, set this:
#BUILD_REPO=kali-experimental

## If want to use a different mirror to build
BUILD_MIRROR=${BUILD_MIRROR:-http://http.kali.org/kali}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

set -e

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

display_help() {
  echo "Usage: $0 [arguments]"
  echo "  -f, --full             build a rootfs with all the recommended packages (biggest)"
  echo "  -m, --minimal          build a rootfs with only the most basic packages (smallest)"
  echo "  -n, --nano             build a rootfs designed for Kali NetNunter watch (middle ground)"
  echo "  -a, --arch [arch]      select a different architecture (default: armhf)"
  echo "                         possible options: armhf, arm64, i386, amd64"
  echo "      --mirror [mirror]  mirror to use during build process (default: $BUILD_MIRROR)"
  echo "  -h, --help             display this help message"
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
      echo "[+] Checking for: $dep"
      if ! rpm -q $dep; then
        echo "[-] Missing dependency: $dep"
        echo "[+] Attempting to install"
        zypper in -y "$dep"
      fi
    done
  else
    pkg_missing=""
    echo "[+] Checking for dependencies"
    for dep in $debian_deps; do
      echo "[+] Checking for: $dep"
      if ! dpkg-query -W --showformat='${Status}\n' "$dep" | grep -q "install ok installed"; then
        echo "[-] Missing dependency: $dep"
        pkg_missing="$pkg_missing $dep"
      fi
    done
    if [ -n "$pkg_missing" ]; then
      echo "[+] Identified missing dependencies"
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

check_umount() {
  if [ -e "${1}" ]; then
    echo "[i] umount: ${1}"
    umount -l -v "${1}" \
      || true
  else
    echo "[-] Path doesn't exist to umount: ${1}"
  fi
}

cleanup_host() {
  echo "[i] Cleaning up host"
  check_umount "$rootfs/dev/pts"
  check_umount "$rootfs/dev"
  check_umount "$rootfs/proc"
  check_umount "$rootfs/sys"

  ## Remove read only from nano
  #chattr -i $(which nano)
}

chroot_do() {
  echo "<--- Entering chroot for: $@ --->"
  DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
  LC_ALL=C LANGUAGE=C LANG=C \
  chroot "$rootfs" "$@"
  echo "<--- Exiting chroot from: $@ --->"
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
    --mirror)
      BUILD_MIRROR=$2
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

## Working location
rootfs="kali-$build_arch"
## Output
output_dir="output"
output_file=$rootfs-$build_size
build_output="$output_dir/$output_file"

mkdir -pv $output_dir/

## Capture all output from here on in kalifs-*.log
##   What would be nice is if able to detect if moreutils is installed, then pipe to `| ts -s`
exec &> >(tee -a "${build_output}.log")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "[+] Selected build size  : $build_size"
echo "[+] Selected architecture: $build_arch"
echo "[+] Selected build mirror: $BUILD_MIRROR"

if [ -n "$BUILD_REPO" ]; then
  echo "[+] Additional apt repo  : $BUILD_REPO"
fi

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

## CORE PACKAGES - every chroot will have these
##   - apt-transport-https for updates
##   - usbutils and pciutils is needed for wifite (unsure why)
pkg_core="abootimg
          apt-transport-https
          binutils
          ca-certificates
          cgpt
          console-common
          fake-hwclock
          git
          git-core
          initramfs-tools
          kali-archive-keyring
          kali-defaults
          less
          locales
          nano
          nethunter-utils
          ntpdate
          openssh-server
          pciutils
          python2.7-minimal
          sudo
          usbutils
          vboot-kernel-utils
          vboot-utils
          vim
          zsh"

## NANO PACKAGES - only necessary packages for watch
pkg_nano="aircrack-ng
          apache2
          bluelog
          blueranger
          bluetooth
          bluez
          bluez-obexd
          bluez-tools
          iw
          kali-menu
          libbluetooth-dev
          libbluetooth3
          net-tools
          nmap
          pixiewps
          python3
          redfang
          sox
          spooftooph
          u-boot-tools
          wpasupplicant"

## MINIMAL PACKAGES - only the most basic packages
pkg_minimal="locales-all"

## DEFAULT PACKAGES FULL INSTALL - all the recommended packages
##   REF: https://gitlab.com/kalilinux/packages/kali-meta/-/blob/kali/master/debian/control
pkg_full="kali-linux-nethunter
          proxmark3"

packages="$pkg_minimal"
[ "$build_size" = full ] &&
  packages="$packages $pkg_full"
[ "$build_size" = nano ] &&
  packages="$pkg_nano"

## Fix packages to be a single space delimited line using unquoted magic
packages=$( echo $packages )

## Set qemnu names
case $build_arch in
  armhf)
    qemu_arch=arm
    ;;
  arm64)
    qemu_arch=aarch64
    ;;
  i386)
    qemu_arch=i386
    ;;
  amd64)
    qemu_arch=x86_64
    ;;
esac

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## It's dangerous to leave these mounted if user cleans git after using Ctrl+C
trap cleanup_host EXIT

## Need to find where this error occurs, but we make nano read only during build and reset after installation is completed
#chattr +i $(which nano)

export build_arch build_size qemu_arch rootfs packages
export -f chroot_do

## Stage 1 - Debootstrap creates basic chroot
echo "[+] Starting stage 1 (debootstrap)"
. stages/stage1.sh

## Stage 2 - Adds repo, bash_profile, hosts file
echo "[+] Starting stage 2 (config)"
. stages/stage2.sh

## Stage 3 - Downloads all packages, modify configuration files
echo "[+] Starting stage 3 (packages)"
. stages/stage3.sh

## Stage 4 - Cleanup stage
echo "[+] Starting stage 4 (cleanup)"
. stages/stage4.sh

## Unmount and fix nano
cleanup_host

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Compress final file
echo "[+] Tarring and compressing kalifs. This can take a while..."
XZ_OPTS=-9 tar cJf "${build_output}.tar.xz" "$rootfs/"

echo "[+] Generating sha512sum of kalifs"
sha512sum "${build_output}.tar.xz" | sed "s|$output_dir/||" > "${build_output}.sha512sum"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Finish
echo "[+] Successful build! The following build artifacts were produced:"
find "$output_dir/" -maxdepth 1 -type f -name "$output_file*" | sed 's_^_* _'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## Extract on device
## xz -dc /sdcard/kalifs.tar.xz | tar xvf - -C /data/local/nhsystem
## or
## tar xJvf /sdcard/kalifs.tar.xz -C /data/local/nhsystem
