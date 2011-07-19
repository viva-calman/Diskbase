#!/bin/bash
USER=$1
DISK=$2
STORAGE='/home/calman/work/storage'
rm /home/$USER/disk
ln -s $STORAGE/$DISK /home/$USER/disk

