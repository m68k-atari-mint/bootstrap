#!/bin/sh

ARANYM_IP=192.168.251.2
#ARANYM_JIT="aranym-jit.exe --fixedmem 0x9a000000"
ARANYM_JIT=aranym-jit

if [ ! -f .aranym-jit ]
then
	if [ -f .aranym-mmu ]
	then
		ssh root@${ARANYM_IP} shutdown
		sleep 7
		rm .aranym-mmu
	fi
	SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy ${ARANYM_JIT} -c aranym.config 2> /dev/null &
	sleep 7
	touch .aranym-jit
fi
