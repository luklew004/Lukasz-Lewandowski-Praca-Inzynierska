#!/bin/bash
terraform -chdir=terraform/server apply -auto-approve
sleep 10
ansible-playbook ansible/Netplan_config.yaml -i ansible/hosts
ansible-playbook ansible/frr2.yaml -i ansible/hosts
ansible-playbook ansible/pcs_config.yaml -i ansible/hosts