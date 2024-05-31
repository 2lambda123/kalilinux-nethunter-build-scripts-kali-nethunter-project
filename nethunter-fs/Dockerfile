############################################################
#  Dockerfile to build a Kali NetHunter chroot filesystem  #
############################################################

## Set the base image to Kali
##   REF: https://hub.docker.com/r/kalilinux/kali-rolling
FROM docker.io/kalilinux/kali-rolling

## Install build packages dependencies
##   If editing, needs to match whats in ./Dockerfile, ./README.md and ./build-fs.sh
RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
      binfmt-support \
      ca-certificates \
      curl \
      debootstrap \
      qemu-user-static \
      xz-utils \
    && \
  ## Clean up
    apt-get clean --yes && \
    apt-get autoremove --yes --purge && \
    rm -rf \
      /usr/share/doc \
      /usr/share/man \
      /var/lib/apt/lists/* \
      /tmp/* \
      /var/tmp/*

## Copy over app
ENV KALI_WORKSPACE /srv/nethunter-fs
RUN mkdir -pv ${KALI_WORKSPACE}
COPY . ${KALI_WORKSPACE}
WORKDIR ${KALI_WORKSPACE}

## Setup app
ENTRYPOINT ["/srv/nethunter-fs/build-fs.sh"]   # exec form, can't use variables, but will read in from CMD
#ENTRYPOINT ${KALI_WORKSPACE}/build-fs.sh      # shell form, can use variables, but CMD is blank
CMD ["-f"]
#CMD ["${KALI_WORKSPACE}/build.sh", "-f"]      # Not using this, as wanting it easier for users to alter arguments when running the container
