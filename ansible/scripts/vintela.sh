#!/bin/bash

ssh -q sjbste219v 'cd /etc/ansible; ansible-playbook -i /etc/ansible/hosts-history/hosts --vault-password-file /etc/ansible/files/vintela.file -e "@/etc/ansible/vars/vintela.userpass.var.json" -e "@/etc/ansible/vars/vintela.install.var.json" vintela-install-join.yml'
ssh -q sjbste219v "echo running vintela-install-join.yml >> /etc/ansible/hosts-history/hosts-config-history"
