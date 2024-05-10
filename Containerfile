FROM quay.io/fedora/fedora-bootc:40

COPY rootfs/ /

RUN \
  dnf install -y vault ansible-core

