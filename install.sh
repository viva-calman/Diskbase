#!/bin/bash
echo "Enter site name (without http://):"
read SITENAME
echo "Enter server IP"
read SERVIP
echo "Enter path to storage directory:"
read STORAGE
echo "Enter admin password:"
read ADMINPASS
echo "Enter server ip"
read SERVADDR
echo
echo
echo "Creating storage directory:"
echo $STORAGE
mkdir $STORAGE
mkdir $STORAGE/mountdir
mkdir $STORAGE/newdisk
echo "Add \"admindisk\" user and creating admindisk group"
echo "Add users into 'admindisk' group if you want to give write privileges on $STORAGE"
addgroup admindisk
useradd admindisk -m -g admindisk -d $STORAGE
chown -R admindisk:admindisk $STORAGE
chmod -R 775 $STORAGE
echo admindisk:$ADMINPASS | chpasswd
(echo $ADMINPASS;echo $ADMINPASS)|smbpasswd -a -s admindisk
echo
echo "Set up domain name in scripts"
STOR=\\$STORAGE
FILES=$(ls ./www/cgi-bin)
sed -i -e "s/http:\/\/localhost/$SITENAME/" ./www/index.html
for I in $FILES
do
	echo -n .
     sed -i -e "s/http:\/\/localhost/$SITENAME/" ./www/cgi-bin/$I
done
echo
echo "Update shell scripts."
sed -i -e "s/PAT\=/PAT\=$STOR\/newdisk/" ./www/cgi-bin/unpack.sh
echo -n .
sed -i -e "s/STOR\=/STOR\=$STOR/" ./www/cgi-bin/unpack.sh
echo -n .
sed -i -e "s/MOUNT\=/MOUNT\=$STOR\/mountdir/" ./www/cgi-bin/unpack.sh
echo -n .
sed -i -e "s/STORAGE\=/STORAGE\=$STOR/" ./www/cgi-bin/mount.sh
echo -n .
sed -i -e "s/SDIR\=/SDIR\=$STOR/" ./www/cgi-bin/delete.sh
echo -n .
sed -i -e "/##SERVERADDRESS##/$SERVADDR/" ./www/cgi-bin/reg.sh
echo -n .
sed -i -e "/##SERVERADDRESS##/$SERVADDR/" ./www/cgi-bin/getbat.pl
echo -n .

echo
echo "Comlpete"

