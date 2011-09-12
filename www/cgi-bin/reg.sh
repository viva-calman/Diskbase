#!/bin/bash
USER=$1
PASSWD=$2
#
#Adding system user
#
useradd $USER -m -g www-data
chown $USER:www-data /home/$USER
chmod 775 /home/$USER
echo $USER:$PASSWD | chpasswd
(echo $PASSWD; echo $PASSWD)|smbpasswd -a -s $USER 
mkdir /home/$USER/help
ln -s /home/$USER/help /home/$USER/disk
BAT='net use z: \\##SERVERADDRESS##\$USER\disk \* /user:$USER'
echo $BAT > /home/$USER/connect.bat

