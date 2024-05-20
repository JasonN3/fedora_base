#!/bin/bash

export HOSTNAME_SHORT=$(hostname -s)

temploc=$(mktemp -d)

while read -r line
do
  if [[ -z "${line}" ]]
  then
    continue
  fi
  file=$(echo "${line}" | cut -d' ' -f1)
  cat "${file}" | envsubst "$(echo $line | cut -d' ' -f2-)" > "${temploc}/file"
  mv "${temploc}/file" "${file}"
done < "$(dirname -- "$0")/update_files"