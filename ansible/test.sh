#!/bin/bash


echo Do you want to create new accounts? yes or no? it is case sensitive
read accountcreation

if [ $accountcreation = 'yes' ]
then
./scripts/yes.sh
fi

if [ $accountcreation = 'no' ]
then
./scripts/no.sh
fi


echo Do you want to create file systems? yes or no? case sensitive
read fscreation

if [ $fscreation = 'yes' ]
then
./scripts/yes.sh
fi

if [ $fscreation = 'no' ]
then
./scripts/no.sh
fi
