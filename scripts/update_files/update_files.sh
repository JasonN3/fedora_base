#!/bin/bash

data=$(vault read -format=raw secrets/data/immutable-os/common)

export DOMAIN=$(echo $data | jq -r '.data.data.domain')
export AD_CERTIFICATE=$(ehco $data | jq -r '.data.data.domain_certificate')

temploc=$(mktemp -d)

while read -r line
do
    envsubst "$(echo $line | cut -f2-)" < $(echo $line | cut -f1) > ${temploc}/file
    mv ${temploc}/file $(echo $line | cut -f1)
done < $(dirname -- $0)/files_to_update