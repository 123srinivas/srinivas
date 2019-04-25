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

echo Please enter yourid:
read userid

#export hostname
# print some output
echo please wait, doing authentication setup

# add fingerprint to Ansible Master
ssh -q sjbste219v "ssh-keyscan $hostname >> ~/.ssh/known_hosts"

# Create trust from Ansible Master
keystatus=`ssh -q $hostname 'grep sjbste219v /root/.ssh/authorized_keys; echo $?'|tail -n 1`
if [ $keystatus -ne 0 ]
then
scp -q $DIR/files/ssh-key.file $hostname:/tmp
ssh -q $hostname "cd /root/.ssh; cp -p authorized_keys authorized_keys.orig; cat /tmp/ssh-key.file >> /root/.ssh/authorized_keys; rm /tmp/ssh-key.file"
fi

# Add the host to Ansible Master
echo $hostname > hostname.file
echo $userid is working on $hostname > lockfile
scp -q hostname.file sjbste219v:/etc/ansible/hosts-history
ssh -q sjbste219v 'cd /etc/ansible/hosts-history; cp hosts.orig hosts; cat hostname.file >> hosts; date >> hosts-config-history; cat hostname.file >> hosts-config-history'

###update cfg-eth0 from DHCP to static IP

echo Do you want to update cfg-eth0 from DHCP to static IP? yes or no? it is case sensitive
read cfgeth0update

if [ $cfgeth0update = 'yes' ]
then
$DIR/scripts/eth0-config.sh
fi

###group and account creation

echo Do you want to create new group and account? yes or no? it is case sensitive
read accountcreation

if [ $accountcreation = 'yes' ]
then
$DIR/scripts/group_account_create.sh
fi

#if [ $accountcreation = 'no' ]
#then
#echo ok
#fi

###vintela installation

echo Do you want to install vintela and join domain? yes or no? it is case sensitive
read installvintela

if [ $installvintela = 'yes' ]
then
$DIR/scripts/vintela.sh
fi

### update /etc/resolv.conf
echo Do you want to update /etc/resolv.conf for webex? yes or no? it is case sensitive
read resolvconf

if [ $resolvconf = 'yes' ]
then
$DIR/scripts/resolvconf_webex.sh
fi

### setup cron to update time
echo Do you want to setup cron for time sync? yes or no? it is case sensitive
read timesync

if [ $timesync = 'yes' ]
then
$DIR/scripts/sync_ntp_cron.sh
fi
# Remove trust from Ansible Master and save the history
ssh -q $hostname "cd /root/.ssh; cp -p authorized_keys.orig authorized_keys"

# Remove the /etc/ansible/hosts-history/hosts file in master
ssh -q sjbste219v 'rm /etc/ansible/hosts-history/hosts; rm /etc/ansible/hosts-history/hostname.file'


# Remove the hostname.file and lockfile
rm hostname.file
rm lockfile
