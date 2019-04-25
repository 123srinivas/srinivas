hostname=sjbkprxy001
keystatus=`ssh -q $hostname 'grep sjbste219v /root/.ssh/authorized_keys; echo $?'|tail -n 1`
echo $keystatus
if [ $keystatus -ne 0 ]
then
#scp -q $DIR/files/ssh-key.file $hostname:/tmp
#ssh -q $hostname "cd /root/.ssh; cp -p authorized_keys authorized_keys.orig; cat /tmp/ssh-key.file >> /root/.ssh/authorized_keys; rm /tmp/ssh-key.file"
#ssh -q sjbste219v "ssh-keyscan $hostname >> ~/.ssh/known_hosts"
echo $keystatus
fi
