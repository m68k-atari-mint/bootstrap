#!/bin/sh

if [ $(which rpmextract.sh) ]
then
	rpmextract.sh "$1"
else
	rpm2cpio "$1" | cpio -i --make-directories
fi
