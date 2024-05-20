#!/bin/bash

set -e

vault write \
  -field=token \
  auth/approle/login \
  role_id=$(cat /usr/lib/vault/role_id) \
  secret_id=$(cat /etc/vault/secret_id) > ~/.vault-token

for script in $(ls "$(dirname -- $0)/scripts/*.sh")
do
  ${script}
done

rm /etc/vault/secret_id