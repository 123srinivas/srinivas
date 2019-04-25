#!/usr/bin/python

# All SSH libraries for Python are junk (2011-10-13).
# Too low-level (libssh2), too buggy (paramiko), too complicated
# (both), too poor in features (no use of the agent, for instance)

# Here is the right solution today:

import subprocess
import sys

HOST="sjbste219v"
# Ports are handled in ~/.ssh/config since we use OpenSSH
COMMAND='cd /etc/ansible; ls -al; cd logs, ls -al'
#COMMAND='ansible-playbook -i /etc/ansible/logs/hosts --vault-password-file /etc/ansible/files/vintela.file -e "@/etc/ansible/vars/vintela.vars.yml" /etc/ansible/vas-join-domain.yml' 

ssh = subprocess.Popen(["ssh", "%s" % HOST, COMMAND],
                       shell=False,
                       stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
result = ssh.stdout.readlines()
if result == []:
    error = ssh.stderr.readlines()
    print >>sys.stderr, "ERROR: %s" % error
else:
    print result
