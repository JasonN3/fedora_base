#!/bin/bash

prefix=""
domain=""

new_hostname="${prefix}$(dmidecode -s system-serial-number | tr '[:upper:]' '[:lower:]').${domain}"

hostnamectl set-hostname ${new_hostname}