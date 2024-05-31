# Kali NetHunter FileSystem (FS) - chroot Builder

Build a basic [Kali NetHunter](https://www.kali.org/get-kali/#kali-mobile) chroot filesystem.

- - -

## Docker

**[Dockerfile](Dockerfile)**:

```bash
docker build -t nethunter .
docker run --privileged --name nethunter_build -i -t nethunter 2>&1 | tee output.log
docker cp nethunter_build:/srv/nethunter-fs/output .
```

**[Docker registry](https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project/container_registry)**:

```bash
./docker-push.sh
```

- - -

## Installer

### Dependencies

This could be built on any [Debian-based](https://www.debian.org/derivatives/) system but we recommend building on [Kali Linux](https://www.kali.org/).

<!-- If editing, needs to match whats in ./Dockerfile, ./README.md and ./build-fs.sh -->
```bash
apt install -y \
  binfmt-support \
  ca-certificates \
  curl \
  debootstrap \
  qemu-user-static \
  xz-utils
```

### Examples

To create a **full** Kali NetHunter filesystem:

```bash
./build-fs.sh -f
```

To create a **minimal** Kali NetHunter filesystem:

```bash
./build-fs.sh -m
```


Sun May 29 22:51:35 UTC 2022
