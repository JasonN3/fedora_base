#!/binbash

timestamp=$(date +%s)

sed -i "s/timestamp: .*/timestamp: ${timestamp}/" revoked_playbooks.yaml

insights-ansible-playbook-signer --revocation-list --playbook revoked_playbooks.yaml --key private.gpg > rootfs/usr/lib/playbooks/revoked_playbooks.yaml
