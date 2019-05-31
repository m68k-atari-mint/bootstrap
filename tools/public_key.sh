#!/bin/sh

mkdir -p /root/.ssh \
	&& cat /h/id_rsa.pub > /root/.ssh/authorized_keys \
	&& chown -R root:root /root/.ssh \
	&& chmod 700 /root/.ssh \
	&& chmod 600 /root/.ssh/authorized_keys
