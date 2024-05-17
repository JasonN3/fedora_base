#!/bin/bash

data=$(vault read -format=raw secrets/data/immutable-os/common)

export DOMAIN=$(echo $data | jq -r '.data.data.domain' | tr '[:lower:]' '[:upper:]')
export AD_CERTIFICATE=$(echo $data | jq -r '.data.data.domain_certificate')
export GLOBAL_ADMINS_ESCAPED=$(echo $GLOBAL_ADMINS | sed 's/ /\\ /g')
export MACHINE_ADMINS_FORMAT_ESCAPED=$(echo $MACHINE_ADMINS_FORMAT | sed 's/ /\\ /g')

temploc=$(mktemp -d)

while read -r line
do
  if [[ -z "${line}" ]]
  then
    continue
  fi
  file=$(echo $line | cut -d' ' -f1)
  cat ${file} | envsubst "$(echo $line | cut -d' ' -f2-)" > ${temploc}/file
  mv ${temploc}/file ${file}
done < $(dirname -- $0)/files_to_update