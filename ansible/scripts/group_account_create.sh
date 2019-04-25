#!/bin/bash

echo Please enter new generic group name:
read group_name

echo Please enter new generic account name:
read user_name
 
echo Please home directory
read home_dir

echo Do you need to specify group ID? yes or no
read group_ID

if [ $group_ID = 'yes' ]
then
  echo Please enter gid
  read gid_number 

     echo Do you need to specify user ID? yes or no
     read user_ID

     if [ $user_ID = 'yes' ]
     then
       echo Please enter uid
       read uid_number
       echo user_name: $user_name > account.var.yml
       echo group_name: $group_name >> account.var.yml
       echo uid_number: $uid_number >> account.var.yml
       echo gid_number: $gid_number >> account.var.yml
       echo home_dir: $home_dir >> account.var.yml
#######copy var file and run playbook
       echo create account
       scp -q account.var.yml sjbste219v:/etc/ansible/hosts-history
       ssh -q sjbste219v 'cd /etc/ansible/hosts-history; date >> hosts-config-history; cat account.var.yml >> hosts-config-history'
       ssh -q sjbste219v 'cd /etc/ansible; ansible-playbook -i /etc/ansible/hosts-history/hosts -e "@/etc/ansible/hosts-history/account.var.yml" group_account_create.yml' 
     else
       echo user_name: $user_name > account.var.yml
       echo group_name: $group_name >> account.var.yml
       echo gid_number: $gid_number >> account.var.yml
       echo home_dir: $home_dir >> account.var.yml
#######copy var file and run playbook
       echo create account
       scp -q account.var.yml sjbste219v:/etc/ansible/hosts-history
       ssh -q sjbste219v 'cd /etc/ansible/hosts-history; date >> hosts-config-history; cat account.var.yml >> hosts-config-history'
       ssh -q sjbste219v 'cd /etc/ansible; ansible-playbook -i /etc/ansible/hosts-history/hosts -e "@/etc/ansible/hosts-history/account.var.yml" group_account_nouid_create.yml' 
     fi
else
     echo Do you need to specify user ID? yes or no
     read user_ID

     if [ $user_ID = 'yes' ]
     then
       echo Please enter uid
       read uid_number
       echo user_name: $user_name > account.var.yml
       echo group_name: $group_name >> account.var.yml
       echo uid_number: $uid_number >> account.var.yml
       echo home_dir: $home_dir >> account.var.yml
#######copy var file and run playbook
       echo create account
       scp -q account.var.yml sjbste219v:/etc/ansible/hosts-history
       ssh -q sjbste219v 'cd /etc/ansible/hosts-history; date >> hosts-config-history; cat account.var.yml >> hosts-config-history'
       ssh -q sjbste219v 'cd /etc/ansible; ansible-playbook -i /etc/ansible/hosts-history/hosts -e "@/etc/ansible/hosts-history/account.var.yml" group_account_nogid_create.yml' 
     else
       echo user_name: $user_name > account.var.yml
       echo group_name: $group_name >> account.var.yml
       echo home_dir: $home_dir >> account.var.yml
#######copy var file and run playbook
       echo create account
       scp -q account.var.yml sjbste219v:/etc/ansible/hosts-history
       ssh -q sjbste219v 'cd /etc/ansible/hosts-history; date >> hosts-config-history; cat account.var.yml >> hosts-config-history'
       ssh -q sjbste219v 'cd /etc/ansible; ansible-playbook -i /etc/ansible/hosts-history/hosts -e "@/etc/ansible/hosts-history/account.var.yml" group_account_nogid_nouid_create.yml'
     fi
fi
