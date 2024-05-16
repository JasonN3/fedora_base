#!/bin/bash

source /etc/os-release
adcli join -U  --os-name="${NAME}" \
  --os-version="${VERSION}" --os-service-pack="${VERSION_ID}"