TARGET           = bootstrap.tar.bz2

BINUTILS_ARCHIVE = /tmp/gcc.tar.bz2
GCC_ARCHIVE      = /tmp/binutils.tar.bz2
FREEMINT_ARCHIVE = /tmp/freemint.zip
EMUTOS_ARCHIVE   = /tmp/emutos.zip
MINTLIB_ARCHIVE  = /tmp/mintlib.tar.gz
FDLIBM_ARCHIVE   = /tmp/fdlibm.tar.gz
ZLIB_ARCHIVE     = /tmp/zlib.tar.gz
OPENSSL_ARCHIVE  = /tmp/openssl.tar.gz
OPENSSH_ARCHIVE  = /tmp/openssh.tar.gz
OPKG_ARCHIVE     = /tmp/opkg.tar.bz2

FREEMINT_DIR     = drive_c
EXT2_DIR         = drive_d
EXT2_IMAGE       = drive_d.img
EXT2_IMAGE_SIZE  = 512
EMUTOS_DIR       = emutos
MINTLIB_DIR      = mintlib
FDLIBM_DIR       = fdlibm
ZLIB_DIR         = zlib
OPENSSL_DIR      = openssl
OPENSSH_DIR      = openssh
OPKG_DIR         = opkg

$(TARGET): $(FREEMINT_DIR) $(EXT2_IMAGE) $(EMUTOS_DIR) aranym.config
	#tar cjf "$@" $^

$(FREEMINT_DIR): $(FREEMINT_ARCHIVE)
	mkdir -p "$@"
	cd "$@" && unzip ${FREEMINT_ARCHIVE} && cd -

$(EXT2_IMAGE): $(EXT2_DIR)
	genext2fs -b $$((${EXT2_IMAGE_SIZE} * 1024)) -d ${EXT2_DIR} "$@"
	#rm -rf ${EXT2_DIR}

$(EXT2_DIR): $(BINUTILS_ARCHIVE) $(GCC_ARCHIVE) $(OPENSSH_DIR) $(OPKG_DIR)
	mkdir -p "$@"
	tar xjf ${BINUTILS_ARCHIVE} -C "$@"
	tar xjf ${GCC_ARCHIVE} -C "$@"

$(EMUTOS_DIR): $(EMUTOS_ARCHIVE)
	unzip ${EMUTOS_ARCHIVE}
	mv emutos-aranym-0.9.10 "$@"

# cross compiled (m68000 gcc assumed!)
$(MINTLIB_DIR): $(MINTLIB_ARCHIVE)
	tar xzf "$<"
	mv mintlib-master "$@"
	cd "$@" && \
	make CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no && \
	make CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no prefix="${PWD}/${EXT2_DIR}/usr" install

# cross compiled (m68000 gcc assumed!)	
$(FDLIBM_DIR): $(FDLIBM_ARCHIVE)
	tar xzf "$<"
	mv fdlibm-master "$@"
	cd "$@" && \
	./configure --host=m68k-atari-mint && \
	make CPU-FPU-TYPES=68020-60.68881 && \
	make CPU-FPU-TYPES=68020-60.68881 prefix="${PWD}/${EXT2_DIR}/usr" install
	mv "${PWD}/${EXT2_DIR}/usr/lib/m68020-60"/* "${PWD}/${EXT2_DIR}/usr/lib" && rmdir "${PWD}/${EXT2_DIR}/usr/lib/m68020-60"

# cross compiled (m68000 gcc assumed!)
$(ZLIB_DIR): $(ZLIB_ARCHIVE)
	tar xzf "$<"
	mv zlib-1.2.11 "$@"
	cd "$@" && \
	CC='m68k-atari-mint-gcc' CFLAGS='-O2 -fomit-frame-pointer -m68020-60' AR='m68k-atari-mint-ar' RANLIB='m68k-atari-mint-ranlib' ./configure --prefix=/usr --static && \
	make && \
	make DESTDIR="${PWD}/${EXT2_DIR}" install

# cross compiled (m68000 gcc assumed!)
$(OPENSSL_DIR): $(OPENSSL_ARCHIVE) $(ZLIB_DIR) $(MINTLIB_DIR) $(FDLIBM_DIR)
	tar xzf "$<"
	mv openssl-1.0.2r "$@"
	cd "$@" && \
	./Configure -DB_ENDIAN no-shared no-threads --prefix=/usr gcc:m68k-atari-mint-gcc -O2 -fomit-frame-pointer -m68020-60 && \
	make AR='m68k-atari-mint-ar cr' RANLIB='m68k-atari-mint-ranlib' && \
	make INSTALL_PREFIX="${PWD}/${EXT2_DIR}" install

$(OPENSSH_DIR): $(OPENSSH_ARCHIVE) $(OPENSSL_DIR)
	tar xzf "$<"
	mv openssh-8.0p1 "$@"

$(OPKG_DIR): $(OPKG_ARCHIVE)
	tar xjf "$<"
	mv opkg-0.4.0 "$@"

$(BINUTILS_ARCHIVE):
	wget -O "$@" https://github.com/freemint/m68k-atari-mint-binutils-gdb/releases/download/binutils-2_30-mint/binutils-2.30-m68020-60mint.tar.bz2

$(GCC_ARCHIVE):
	wget -O "$@" https://github.com/freemint/m68k-atari-mint-gcc/releases/download/gcc-7_4_0-mint-20190228/gcc-7.4.0-m68020-60mint.tar.bz2

$(FREEMINT_ARCHIVE):
	wget -O "$@" https://bintray.com/freemint/freemint/download_file?file_path=snapshots-cpu%2F1-19-8c0c3f2f%2Ffreemint-1-19-cur-040.zip

$(EMUTOS_ARCHIVE):
	wget -O "$@" http://downloads.sourceforge.net/project/emutos/emutos/0.9.10/emutos-aranym-0.9.10.zip

$(MINTLIB_ARCHIVE):
	wget -O "$@" https://github.com/freemint/mintlib/archive/master.tar.gz

$(FDLIBM_ARCHIVE):
	wget -O "$@" https://github.com/freemint/fdlibm/archive/master.tar.gz

$(ZLIB_ARCHIVE):
	wget -O "$@" https://www.zlib.net/zlib-1.2.11.tar.gz

$(OPENSSL_ARCHIVE):
	wget -O "$@" https://www.openssl.org/source/openssl-1.0.2r.tar.gz

$(OPENSSH_ARCHIVE):
	wget -O "$@" https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.0p1.tar.gz

$(OPKG_ARCHIVE):
	wget -O "$@" http://git.yoctoproject.org/cgit/cgit.cgi/opkg/snapshot/opkg-0.4.0.tar.bz2

clean:
	rm -rf ${FREEMINT_DIR}
	rm -rf ${EXT2_DIR}
	rm -rf ${EMUTOS_DIR}
	rm -rf ${MINTLIB_DIR}
	rm -rf ${FDLIBM_DIR}
	rm -rf ${ZLIB_DIR}
	rm -rf ${OPENSSL_DIR}
	rm -rf ${OPENSSH_DIR}
	rm -rf ${OPKG_DIR}
	rm -f ${EXT2_IMAGE}
	rm -f ${TARGET}
	rm -f *~

distclean: clean
	rm -f ${BINUTILS_ARCHIVE}
	rm -f ${GCC_ARCHIVE}
	rm -f ${FREEMINT_ARCHIVE}
	rm -f ${EMUTOS_ARCHIVE}
	rm -f ${MINTLIB_ARCHIVE}
	rm -f ${FDLIBM_ARCHIVE}
	rm -f ${ZLIB_ARCHIVE}
	rm -f ${OPENSSL_ARCHIVE}
	rm -f ${OPENSSH_ARCHIVE}
	rm -f ${OPKG_ARCHIVE}
