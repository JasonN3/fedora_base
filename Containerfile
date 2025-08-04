ARG FEDORA_BOOTC_VERSION=43

FROM quay.io/fedora/fedora-bootc:${FEDORA_BOOTC_VERSION} as selinux

RUN dnf install -y checkpolicy \
                   make \
                   policycoreutils

RUN --mount=source=/selinux,target=/selinux,rw \
    cd /selinux && \
    make all && \
    mkdir /selinux-pp && \
    mv /selinux/*.pp /selinux-pp/

FROM quay.io/fedora/fedora-bootc:${FEDORA_BOOTC_VERSION}

# Install and enable flightctl-agent
RUN dnf install -y dnf5-plugins && \
    dnf copr enable -y @redhat-et/flightctl && \
    dnf install -y flightctl-agent podman podman-compose && \
    dnf clean all && \
    systemctl enable flightctl-agent.service

# Copy files from repo
COPY rootfs/ /

# Install useful packages
RUN dnf install -y cloud-init tmux which rsync && \
    dnf clean all

# Enable services
RUN systemctl enable nftables.service \
                     protect_etc.service \
                     pull_images.path \
                     cloud-init.target

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
      for module in /selinux/*.pp; do semodule -i "${module}"; done; \
    fi

# Cleanup
RUN rm -Rf /var/log/dnf5* \
           /var/cache/libdnf5 \
           /var/lib/dnf \
           /var/cache/ldconfig/aux-cache


RUN bootc container lint --fatal-warnings
