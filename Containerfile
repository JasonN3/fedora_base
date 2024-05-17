FROM quay.io/fedora/fedora-bootc:40

COPY rootfs/ /

RUN dnf install -y vault ansible-core tmux

# Install packages for domain joining
RUN dnf install -y chrony krb5-workstation \
samba-common-tools oddjob-mkhomedir samba-common \
sssd authselect

RUN dnf clean all

# Don't reboot unexpectedly
RUN rm -f /usr/lib/systemd/system/default.target.wants/bootc-fetch-apply-updates.timer

# Trust the domain certificate
RUN trust anchor /usr/etc/sssd/pki/sssd_auth_ca_db.pem
