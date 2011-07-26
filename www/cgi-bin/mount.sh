#!/bin/bash
USER=$1
DISK=$2
STORAGE=
rm /home/$USER/disk
ln -s $STORAGE/$DISK /home/$USER/disk

