#!/bin/bash

# Prompt for admin user
admin_user=""
while [[ ${admin_user} == "" ]]
do
  echo "Enter a username for the break glass local admin account:"
  read -e admin_user
done

# Prompt for auth method
auth_method=0
while [[ ! "${auth_method}" =~ [123] ]]
do
  echo "How will that user to authenticate:"
  echo "1 - Password"
  echo "2 - SSH Key"
  echo "3 - Both"
  echo "Enter the number of your selection"
  read -e auth_method
done

# Password auth
if [[ $(( auth_method & 1 )) != 0 ]]
then
  echo "Enter the password for ${admin_user}"
  admin_hash=$(mkpasswd)
fi

# SSH auth
if [[ $(( auth_method & 2 )) != 0 ]]
then
  admin_key=""
  while [[ ${admin_key} == "" ]]
  do
    echo "Enter the SSH key for ${admin_user}"
    read -e admin_key
  done
fi

base64_file=$(flightctl certificate request | base64 -w0)
if [[ $? != 0 ]]
then
    echo "Error generating flightctl config"
    exit 1
fi

echo "Writing cloud-init.yaml"
cat << EOF > cloud-init.yaml
write_files:
  - path: /etc/flightctl/config.yaml
    encoding: b64
    content: ${base64_file}
    owner: root:root
    permissions: '0640'

users:
  - name: ${admin_user}
    gecos: ${admin_user}
EOF
# Appending password auth
if [[ $(( auth_method & 1 )) != 0 ]]
then
cat << EOF >> cloud-init.yaml
    sudo: ["ALL=(ALL) ALL"]
    passwd: ${admin_hash}
EOF
else
cat << EOF >> cloud-init.yaml
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
EOF
fi

# Appending SSH auth
if [[ $(( auth_method & 2 )) != 0 ]]
then
cat << EOF >> cloud-init.yaml
    ssh_authorized_keys:
      - ${admin_key}
EOF
fi
