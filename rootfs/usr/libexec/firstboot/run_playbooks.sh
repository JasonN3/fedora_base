#!/bin/bash

source $(dirname -- $0)/playbooks.env

for playbook in $(ls $(dirname -- $0)/playbooks)
do
  ansible-playbook ${playbook}
done