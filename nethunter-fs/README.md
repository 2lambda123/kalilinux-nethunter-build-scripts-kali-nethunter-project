# Kali NetHunter FileSystem (FS)

Build a Kali chroot with various [custom scripts](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-utils) to create the [Kali NetHunter](https://www.kali.org/get-kali/#kali-mobile) filesystem.

- - -

## Install

### Docker

You can use the [pre-created container](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project/container_registry), or build it locally yourself.

To pull the image from GitLab's registry:

```console
$ apt install docker.io qemu-user-static
$ docker pull registry.gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project:latest
$ docker run --privileged --interactive --tty --rm --volume "$(pwd)/output:/srv/nethunter-fs/output" registry.gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project
$ docker run --privileged --interactive --tty --rm --volume "$(pwd)/output:/srv/nethunter-fs/output" registry.gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project --full
```

Otherwise, you can build the image using the [Dockerfile](./Dockerfile):

```console
$ apt install git docker.io qemu-user-static
$ git clone https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project.git
$ cd kali-nethunter-project/nethunter-fs/
$ docker build -t nethunter .
$ docker run --privileged --interactive --tty --rm --volume "$(pwd)/output:/srv/nethunter-fs/output" nethunter
$ docker run --privileged --interactive --tty --rm --volume "$(pwd)/output:/srv/nethunter-fs/output" nethunter --full
```
<!--
Alt commands/methods:
```console
$ docker run --privileged --interactive --tty --rm --volume ./output:/srv/nethunter-fs/output --env BUILD_MIRROR=http://kali.download/kali nethunter
$
$ docker run --privileged --interactive --tty --name nethunter-build nethunter 2>&1 | tee output.log
$ docker cp nethunter-build:/srv/nethunter-fs/output .
```
-->

- - -

### Bare Metal

This could be built on any [Debian-based](https://www.debian.org/derivatives/) system but we recommend building on [Kali Linux](https://www.kali.org/).

The following package dependencies is required to build:

<!-- If editing, needs to match whats in ./Dockerfile, ./README.md and ./build-fs.sh -->
```console
$ sudo apt-get install \
      binfmt-support \
      ca-certificates \
      curl \
      debootstrap \
      qemu-user-static \
      xz-utils
$ apt install git
$ cd kali-nethunter-project/nethunter-fs/
$ ./build-fs.sh
$ sudo ./build-fs.sh --full
```

## Commands

### Help

```console
$ ./build-fs.sh --help
Usage: ./build-fs.sh [arguments]
  -f, --full             build a rootfs with all the recommended packages (biggest)
  -m, --minimal          build a rootfs with only the most basic packages (smallest)
  -n, --nano             build a rootfs designed for Kali NetNunter watch (middle ground)
  -a, --arch [arch]      select a different architecture (default: armhf)
                         possible options: armhf, arm64, i386, amd64
      --mirror [mirror]  mirror to use during build process (default: http://http.kali.org/kali)
  -h, --help             display this help message
$
````

### Examples

To create a **full** Kali NetHunter filesystem:

```console
$ sudo ./build-fs.sh --full
```

To create a **minimal** Kali NetHunter filesystem for amd64

```console
$ sudo ./build-fs.sh -m -a arm64
```



Sat  1 Jun 2024 04:06:05 UTC
