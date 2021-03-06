#!/bin/bash

ARANYM_IP=192.168.251.2
if [[ $(uname -r) =~ Microsoft$ ]]
then
	ARANYM_MMU=aranym-mmu.exe
else
	ARANYM_MMU=aranym-mmu
fi

if [ ! -f .aranym-mmu ]
then
	if [ -f .aranym-jit ]
	then
		ssh root@${ARANYM_IP} shutdown
		sleep 10
		rm .aranym-jit
	fi
	SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy ${ARANYM_MMU} -c config/aranym.config &
	sleep 10
	touch .aranym-mmu
fi
