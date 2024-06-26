#!/bin/bash


if [[ "$(dmidecode -s system-serial-number)" != "Not Specified" ]]
then
  new_hostname="${PREFIX}$(dmidecode -s system-serial-number | tr '[:upper:]' '[:lower:]').${DOMAIN}"
else
  address=$(ip a | grep -w inet | tail -n 1 | tr '/' ' ' | awk '{print $2}')
  new_hostname="${PREFIX}$(echo "${address}" | cut -d. -f3)-$(echo "${address}" | cut -d. -f4).${DOMAIN}"
fi

echo "New hostname: ${new_hostname}"

hostnamectl set-hostname "${new_hostname}"