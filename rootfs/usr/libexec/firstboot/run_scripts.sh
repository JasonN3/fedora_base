#!/bin/bash

vault write auth/approle/login \
  -field=token -format=raw \
  role_id=$(cat /usr/lib/vault/role_id) \
  secret_id=$(cat /etc/vault/secret_id) > ~/.vault-token

for script in $(ls $(dirname -- $0)/scripts)
do
  ./scripts/${script}
done

# rm ~/.vault-token