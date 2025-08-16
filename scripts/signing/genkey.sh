#!/bin/bash

instructions="$(mktemp)"

cat << EOF > "$instructions"
Key-Type: EDDSA
  Key-Curve: ed25519
Subkey-Type: ECDH
  Subkey-Curve: cv25519
Name-Real: Integration test key
Expire-Date: 0
%no-protection
%commit
EOF

gpg --batch --generate-key --pinentry-mode loopback "$instructions"

gpg --export --armor | tee public.key > rootfs/usr/lib/playbooks/public.gpg

gpg --export-secret-keys --pinentry-mode loopback --yes --armor >> private.key
