#!/bin/bash

if [[ -n "${VAULT_TOKEN}" ]]
then
    echo "Token set"
    vault token lookup | grep policies
fi
data=$(vault read -format=raw secrets/data/immutable-os/common)

export DOMAIN=$(echo $data | jq -r '.data.data.domain')
export AD_CERTIFICATE=$(echo $data | jq -r '.data.data.domain_certificate')

temploc=$(mktemp -d)

while read -r line
do
    file=$(echo $line | cut -f1)
    envsubst "$(echo $line | cut -f2-)" < ${file} > ${temploc}/file
    mv ${temploc}/file ${file}
done < $(dirname -- $0)/files_to_update