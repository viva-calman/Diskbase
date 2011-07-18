#!/bin/bash
SDIR="/home/calman/work/storage"
DELDIR=$1
#
# Не удаляется, переименовывается в директорию формата "Номер директории".deleted
# Директорию удаляют вручную
#
mv $SDIR/$DELDIR $SDIR/$DELDIR.deleted
chmod 766 $SDIR/$DELDIR.deleted -R

