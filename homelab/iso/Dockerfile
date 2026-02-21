FROM ubuntu:24.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl xorriso rsync sed gawk coreutils \
    isolinux syslinux-common \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY scripts/build-autoinstall-iso.sh /usr/local/bin/build-autoinstall-iso
RUN chmod +x /usr/local/bin/build-autoinstall-iso

ENTRYPOINT ["/usr/local/bin/build-autoinstall-iso"]

