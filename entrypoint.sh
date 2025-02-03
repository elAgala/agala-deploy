#!/bin/sh
set -e

# Create .ansible directory if it doesn't exist
mkdir -p ~/.ansible
mkdir -p ~/.ssh

op read -o ~/.ansible/inventory.yml "op://$OP_ANSIBLE_INVENTORY_FILE_ROUTE"
op read -o ~/.ssh/id_ed25519 "op://$OP_ANSIBLE_PRIVATE_KEY_ROUTE?ssh-format=openssh"

# Run Ansible
exec ansible-playbook "$ANSIBLE_PLAYBOOK" \
  --inventory ~/.ansible/inventory.yml \
  --limit "$ANSIBLE_LIMIT" \
  --diff \
  -e "app_version=${APP_VERSION}" \
  -e "ansible_ssh_private_key_file=~/.ssh/id_ed25519" \
  -e "ansible_host_key_checking=false"
