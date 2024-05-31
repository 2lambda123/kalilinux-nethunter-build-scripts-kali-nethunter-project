############################################################
# Dockerfile to build a Kali NetHunter chroot Filesystem
############################################################

# Set the base image to Kali
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update \
  && apt-get -y dist-upgrade \
  && apt-get clean

## If editing, needs to match whats in ./Dockerfile, ./README.md and ./build-fs.sh
RUN apt-get install -y \
  binfmt-support \
  ca-certificates \
  curl \
  debootstrap \
  qemu-user-static \
  xz-utils

ENV KALI_WORKSPACE /root/nethunter-fs
RUN mkdir -p ${KALI_WORKSPACE}
COPY . ${KALI_WORKSPACE}
WORKDIR ${KALI_WORKSPACE}

CMD ["/root/nethunter-fs/build-fs.sh", "-f"]
