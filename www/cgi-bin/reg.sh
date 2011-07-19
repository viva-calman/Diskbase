#!/bin/bash
USER=$1
PASSWD=$2
#
#Adding system user
#
useradd $USER -m
echo $USER:$PASSWD | chpasswd
(echo $PASSWD; echo $PASSWD)|smbpasswd -a -s $USER 
mkdir /home/$USER/help
ln -s /home/$USER/help /home/$USER/disk

