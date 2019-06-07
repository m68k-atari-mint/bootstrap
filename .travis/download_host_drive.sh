#!/bin/sh

# $1: stage
# $2: drive letter

wget -q --no-check-certificate -c "https://dl.bintray.com/m68k-atari-mint/opkg-bootstrap/images/${TRAVIS_COMMIT}/${1}/drive_${2}.img.bz2" -O - | tar xjf -
