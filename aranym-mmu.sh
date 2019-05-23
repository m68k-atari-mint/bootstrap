#!/bin/sh

ARANYM_IP=192.168.251.2

if [ ! -f .aranym-mmu ]
then
	if [ -f .aranym-jit ]
	then
		ssh root@${ARANYM_IP} shutdown
		sleep 7
		rm .aranym-jit
	fi
	SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy aranym-mmu -c aranym.config 2> /dev/null &
	sleep 7 
	touch .aranym-mmu
fi
