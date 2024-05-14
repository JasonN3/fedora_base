#!/bin/bash

prefix=""
domain=""

if [[ -n "$(dmidecode -s system-serial-number)" ]]
then
  new_hostname="${prefix}$(dmidecode -s system-serial-number | tr '[:upper:]' '[:lower:]').${domain}"
else
  address=$(ip a | grep -w inet | tail -n 1 | tr '/' ' ' | awk '{print $2}')
  new_hostname="${prefix}$(echo ${address} | cut -d. -f3)-$(echo ${address} | cut -d. -f4).${domain}"
fi

hostnamectl set-hostname ${new_hostname}