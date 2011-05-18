#!/bin/bash
USER=$1
PASSWD=$2
#
#Adding system user
#
useradd -p $(mkpasswd -Hmd5 $PASSWD) $USER -m
(echo $PASSWD; echo $PASSWD)|smbpasswd -a -s $USER 
mkdir /home/$USER/disk

