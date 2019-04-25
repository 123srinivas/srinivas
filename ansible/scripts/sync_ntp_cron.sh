#!/bin/bash
echo "this script is used for adding cron job to get time sync'd hourly"

ssh -q sjbste219v 'ansible-playbook -i /etc/ansible/hosts-history/hosts /etc/ansible/ntp_sync.yml' 
ssh -q sjbste219v 'echo running ntp_sync.yml >> /etc/ansible/hosts-history/hosts-config-history'
