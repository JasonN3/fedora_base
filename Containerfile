FROM quay.io/fedora/fedora-bootc:42

# Install and enable flightctl-agent
RUN dnf install -y dnf5-plugins && \
    dnf copr enable -y @redhat-et/flightctl && \
    dnf install -y flightctl-agent && \
    dnf clean all && \
    systemctl enable flightctl-agent.service

COPY rootfs/ /

RUN dnf install -y vault ansible-core tmux && dnf clean all

# Install packages for domain joining
RUN dnf install -y chrony krb5-workstation \
        samba-common-tools oddjob-mkhomedir samba-common \
        sssd authselect && \
    dnf clean all

# Don't reboot unexpectedly
RUN rm -f /usr/lib/systemd/system/default.target.wants/bootc-fetch-apply-updates.timer
