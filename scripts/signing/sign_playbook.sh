#!/bin/bash

insights-ansible-playbook-signer --playbook "$1" --key private.gpg
