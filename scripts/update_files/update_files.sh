#!/bin/bash

data=$(vault read -format=raw secrets/data/immutable-os/common)

export DOMAIN=$(echo "${data}" | jq -r '.data.data.domain' | tr '[:lower:]' '[:upper:]')
export AD_CERTIFICATE=$(echo "${data}" | jq -r '.data.data.domain_certificate')
export GLOBAL_ADMINS_ESCAPED="${GLOBAL_ADMINS// /\\ }"
export MACHINE_ADMINS_FORMAT_ESCAPED="${MACHINE_ADMINS_FORMAT// /\\ }"

temploc=$(mktemp -d)

while read -r line
do
  if [[ -z "${line}" ]]
  then
    continue
  fi
  file=$(echo "${line}" | cut -d' ' -f1)
  envsubst "$(echo "${line}" | cut -d' ' -f2-)" > "${temploc}/file" < "${file}"
  mv "${temploc}/file" "${file}"
done < "$(dirname -- "$0")/files_to_update"