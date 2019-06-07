#!/bin/bash

ARANYM_IP=192.168.251.2
if [[ $(uname -r) =~ Microsoft$ ]]
then
	ARANYM_JIT="aranym-jit.exe --fixedmem 0x9a000000"
else
	ARANYM_JIT=aranym-jit
fi

if [ ! -f .aranym-jit ]
then
	if [ -f .aranym-mmu ]
	then
		ssh root@${ARANYM_IP} shutdown
		sleep 10
		rm .aranym-mmu
	fi
	SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy ${ARANYM_JIT} -c config/aranym.config 2> /dev/null &
	sleep 10
	touch .aranym-jit
fi
