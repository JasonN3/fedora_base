ARG FEDORA_BOOTC_VERSION=43

FROM quay.io/fedora/fedora-bootc:${FEDORA_BOOTC_VERSION} as iapv

ENV LC_ALL=C.UTF-8

COPY external/insights-ansible-playbook-verifier /iapv

RUN cd /iapv && \
    python -m venv venv && \
    source venv/bin/activate && \
    dnf clean all && \
    mkdir -p /iapv/root && \
    pip install . 

FROM quay.io/fedora/fedora-bootc:${FEDORA_BOOTC_VERSION} as rwp

ENV LC_ALL=C.UTF-8
ENV GOCACHE=/var/gocache
ENV GOMODCACHE=/var/gomodcache

COPY external/rhc-worker-playbook /rwp

RUN dnf install -y 'pkgconfig(yggdrasil)' 'pkgconfig(dbus-1)' 'pkgconfig(systemd)' ansible-core go meson tree cmake python3-pip

RUN cd /rwp && \
    meson build . \
        --prefix=/usr && \
    cd build && \
    meson install --destdir=/rwp/root

FROM quay.io/fedora/fedora-bootc:${FEDORA_BOOTC_VERSION} as selinux

ENV LC_ALL=C.UTF-8

RUN dnf install -y checkpolicy \
                   make \
                   policycoreutils

RUN --mount=source=/selinux,target=/selinux,rw \
    cd /selinux && \
    make all && \
    make move

FROM quay.io/fedora/fedora-bootc:${FEDORA_BOOTC_VERSION}

ENV LC_ALL=C.UTF-8

# Copy files from repo
COPY --from=iapv /iapv/venv/ /opt/insights_ansible_playbook_verifier
COPY --from=rwp /rwp/root/ /
COPY rootfs/. /

# Install yggdrasil
RUN dnf install -y podman yggdrasil && \
    dnf clean all

# Install useful packages
RUN dnf install -y cloud-init tmux which rsync && \
    dnf clean all

# Enable services
RUN systemctl enable nftables.service \
                     protect_etc.service \
                     pull_images.path \
                     fix_perms_nm.path \
                     cloud-init.target \
                     yggdrasil.service

# Install packages for OIDC authentication
RUN dnf install -y authselect \
                   chrony \
                   oddjobd \
                   oddjob-mkhomedir \
                   sssd-idp && \
    dnf clean all && \
    systemctl enable sssd \
                     oddjobd && \
    authselect select sssd with-mkhomedir && \
    chgrp sssd /usr/libexec/sssd/sssd_pam && \
    sed -i 's/^ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config.d/50-redhat.conf && \
    sed -i 's/^KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config.d/50-redhat.conf

# Don't reboot unexpectedly
RUN rm -f /usr/lib/systemd/system/default.target.wants/bootc-fetch-apply-updates.timer

RUN --mount=from=selinux,source=/selinux-pp,target=/selinux \
    if ls /selinux/*.pp 1> /dev/null 2>&1; then \
      for module in /selinux/*.pp; do semodule -vi "${module}"; done; \
    fi

# Cleanup
RUN rm -Rf /var/log/dnf5* \
           /var/cache/libdnf5 \
           /var/lib/dnf \
           /var/cache/ldconfig/aux-cache


RUN bootc container lint --fatal-warnings
