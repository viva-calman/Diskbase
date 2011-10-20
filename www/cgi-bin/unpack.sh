#!/bin/sh
PAT=
STOR=
MOUNT=
LIST=$( find $PAT \( -name '*.iso' -o -name '*.nrg' -o -name '*.mdf' \) )
ACT=$1
case $ACT in
    search)
	for i in $LIST ; do
		echo $i
		done
    ;;
    unpack)
	IMG=$3
	FOLD=$2
	fuseiso $IMG $MOUNT
	mkdir $STOR/$FOLD
	cp -r $MOUNT/* $STOR/$FOLD
	fusermount -u $MOUNT
	AUTORUN=$(find $STOR/$FOLD -iname autorun.inf -exec cat {} \; | awk -F= '/open/ {print $2}')
	echo $AUTORUN
	sleep 2
    ;;
    *)
    echo "fail"
    ;;
esac    
