#!/bin/bash

images=$(jq -r '.spec.applications[].inline[].content' /var/lib/flightctl/desired.json | base64 -d | grep image | awk '{print $2}')
for image in ${images}
do
  echo "Checking ${image}"
  if [[ ${image} =~ ^ghcr.io/[Jj]ason[Nn]3/fedora_apps:.* ]]
  then
    podman pull --decryption-key /etc/pki/fedora_apps.pem "${image}"
  fi
done
