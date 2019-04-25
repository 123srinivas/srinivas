#!/bin/bash
echo "this script is used for configuing ifcfg-eth0 with static IP and gateway"

ssh -q sjbste219v 'ansible-playbook -i /etc/ansible/hosts-history/hosts /etc/ansible/eth0_config.yml' 
ssh -q sjbste219v 'echo running eth0_config.yml >> /etc/ansible/hosts-history/hosts-config-history'
