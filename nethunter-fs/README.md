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
$ docker run --privileged --interactive --tty --rm --volume ./output:/srv/nethunter-fs/output registry.gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project --help
$ docker run --privileged --interactive --tty --rm --volume ./output:/srv/nethunter-fs/output registry.gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project
```

Otherwise, you can build the image using the [Dockerfile](./Dockerfile):

```console
$ apt install git docker.io qemu-user-static
$ git clone https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project.git
$ cd kali-nethunter-project/kali-nethunter-project/
$ docker build -t nethunter .
$ docker run --privileged --interactive --tty --rm --volume ./output:/srv/nethunter-fs/output nethunter --help
$ docker run --privileged --interactive --tty --rm --volume ./output:/srv/nethunter-fs/output nethunter
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
```

## Commands

### Help

```console
$ ./build-fs.sh --help
Usage: ./build-fs.sh [arguments]
  -f, --full      build a rootfs with all the recommended packages (biggest)
  -m, --minimal   build a rootfs with only the most basic packages (smallest)
  -n, --nano      build a rootfs designed for Kali NetNunter watch (middle ground)
  -a, --arch      select a different architecture (default: armhf)
                  possible options: armhf, arm64, i386, amd64
  -h, --help      display this help message
$
````

### Examples

To create a **full** Kali NetHunter filesystem:

```console
$ ./build-fs.sh -f
```

To create a **minimal** Kali NetHunter filesystem for amd64

```console
$ ./build-fs.sh -m -a arm64
```



Wed 29 May 2024 14:31:47 UTC
