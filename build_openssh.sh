#!/bin/sh

./configure --prefix=/usr --sysconfdir=/etc/ssh CFLAGS='-O2 -fomit-frame-pointer' ac_cv_member_struct_stat_st_mtim=no && \
make && \
make install
