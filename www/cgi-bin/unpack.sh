#!/bin/sh
PAT='/home/calman/work/imgs/'
STOR='/home/calman/work/storage'
MOUNT='/home/calman/work/mountdir'
LIST=$( find $PAT \( -name '*.iso' -o -name '*.nrg' -o -name '*.mdf' \) )
ACT=$1
#for i in $LIST ; do
#	fuseiso $i $MOUNT
#
#   done

case $ACT in
    search)
	for i in $LIST ; do
		echo $i
		done
    ;;
    unpack)
	IMG=$2
	FOLD=$3
	fuseiso $IMG $MOUNT
	mkdir $STOR/$FOLD
	cp -r $MOUNT/* $STOR/$FOLD
	fusermount -u $MOUNT
	sleep 2
    ;;
    *)
    echo "fail"
    ;;
esac    
