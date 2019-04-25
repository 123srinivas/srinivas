#!/bin/bash

#check if anyone is running the ansible 

if [ -f hostname.file ]
then
	echo someone is running ansible config, please run it later
	exit
fi

echo Please enter the hostname:

read hostname

echo hostname is $hostname, yes/no?

read hostnameanswer

if [ $hostnameanswer = 'no' ]
then
exit
fi

# Create trust from Ansible Master
scp -q ssh-key.file $hostname:/tmp
ssh -q $hostname "cd /root/.ssh; cp -p authorized_keys authorized_keys.orig; cat /tmp/ssh-key.file >> /root/.ssh/authorized_keys; rm /tmp/ssh-key.file"

# Add the host to Ansible Master
echo $hostname > hostname.file
scp -q hostname.file sjbste219v:/etc/ansible/hosts-history
ssh -q sjbste219v 'cd /etc/ansible/hosts-history; cp hosts.orig hosts; cat hostname.file >> hosts; cd /etc/ansible; ansible-playbook -i /etc/ansible/hosts-history/hosts vas-install-start-new.yml; ansible-playbook -i /etc/ansible/hosts-history/hosts -e "@/etc/ansible/vintela.vars.yml" vas-join-domain.yml' 

# Remove trust from Ansible Master and save the history
ssh -q $hostname "cd /root/.ssh; cp -p authorized_keys.orig authorized_keys"

# Save the host configuration history
ssh -q sjbste219v "cd /etc/ansible/hosts-history; date >> hosts-config-history; cat hostname.file >> hosts-config-history"

# Remove the hostname.file
rm hostname.file
