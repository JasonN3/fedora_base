FROM quay.io/fedora/fedora-bootc:41

# Install and enable flightctl-agent
RUN dnf install -y dnf5-plugins && \
    dnf copr enable -y @redhat-et/flightctl && \
    dnf install -y flightctl-agent podman podman-compose && \
    dnf clean all && \
    systemctl enable flightctl-agent.service

# Copy files from repo
COPY rootfs/ /

# Install useful packages
RUN dnf install -y tmux && \
    dnf clean all

# Install packages for OIDC authentication
RUN dnf copr enable -y sbose/sssd-idp && \
    dnf install -y authselect chrony oddjobd oddjob-mkhomedir sssd-idp  && \
    dnf clean all && \
    systemctl enable sssd oddjobd && \
    authselect select sssd with-mkhomedir && \
    chgrp sssd /usr/libexec/sssd/sssd_pam

# Don't reboot unexpectedly
RUN rm -f /usr/lib/systemd/system/default.target.wants/bootc-fetch-apply-updates.timer

# Copy users and groups from packages
RUN cp /etc/passwd /usr/etc/passwd && \
    cp /etc/group /usr/etc/group
