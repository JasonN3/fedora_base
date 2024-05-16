FROM quay.io/fedora/fedora-bootc:40

COPY rootfs/ /

RUN dnf install -y vault ansible-core 

# Install packages for domain joining
RUN dnf install -y chrony krb5-workstation \
samba-common-tools oddjob-mkhomedir samba-common \
sssd authselect

RUN dnf clean all

# Don't reboot unexpectedly
RUN systemctl disable bootc-fetch-apply-updates.timer

# Scripts
COPY scripts /tmp
## update_files
RUN bash /tmp/scripts/update_files/update_files.sh

## set_perms
RUN bash /tmp/scripts/set_perms/set_perms.sh

## Cleanup Scripts
RUN rm -Rf /temp/scripts