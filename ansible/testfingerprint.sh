#!/bin/bash

DIR=/apps/priv/sa-priv/webex-config

#check if anyone is running the ansible 

if [ -f lockfile ]
then
	cat lockfile
	exit
fi

echo Please enter the hostname:
read hostname

#export hostname
# print some output
echo please wait, doing authentication setup

# add fingerprint to Ansible Master
#fingerprint=`ssh -q sjbste219v "grep $hostname /root/.ssh/known_hosts; echo $?|tail -n 1"`
ssh -q sjbste219v "echo $hostname; grep $hostname /root/.ssh/known_hosts > /tmp/fingerprint.status"
fingerprint=`ssh -q sjbste219v "ls -al /tmp/fingerprint.status | awk '{print $5}'"`
echo $fingerprint
#ssh -q sjbste219v 'grep sjdmde227v /root/.ssh/known_hosts; echo $?'

#if [ $fingerprint -ne 0 ]
#then
#ssh -q sjbste219v "ssh-keyscan $hostname >> ~/.ssh/known_hosts"
#fi
#
