#!/bin/bash

data=$(vault read -format=raw secrets/data/immutable-os/common)

join_user=$(echo $data | jq -r '.data.data.domain_join_user')
join_password=$(echo $data | jq -r '.data.data.domain_join_user')

source /etc/os-release
echo "${join_password}" | adcli join -U ${join_user} --stdin-password --os-name="${NAME}" \
  --os-version="${VERSION}" --os-service-pack="${VERSION_ID}"