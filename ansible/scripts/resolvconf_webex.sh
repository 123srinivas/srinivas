#!/bin/bash
echo "this script is used for adding webex info to /etc/resolv.conf file"

ssh -q sjbste219v 'ansible-playbook -i /etc/ansible/hosts-history/hosts /etc/ansible/resolvconf_webex.yml' 
ssh -q sjbste219v "echo running resolvconf_webex.yml >> /etc/ansible/hosts-history/hosts-config-history"
