TARGET           = bootstrap.tar.bz2

BINUTILS_ARCHIVE = /tmp/gcc.tar.bz2
GCC_ARCHIVE      = /tmp/binutils.tar.bz2
FREEMINT_ARCHIVE = /tmp/freemint.zip
EMUTOS_ARCHIVE   = /tmp/emutos.zip
OPENSSH_ARCHIVE  = /tmp/openssh.tar.gz
OPKG_ARCHIVE     = /tmp/opkg.tar.bz2

FREEMINT_DIR     = drive_c
EXT2_DIR         = drive_d
EXT2_IMAGE       = drive_d.img
EXT2_IMAGE_SIZE  = 512
EMUTOS_DIR       = emutos
OPENSSH_DIR      = openssh
OPKG_DIR         = opkg

$(TARGET): $(FREEMINT_DIR) $(EXT2_IMAGE) $(EMUTOS_DIR) aranym.config
	#tar cjf "$@" $^

$(FREEMINT_DIR): $(FREEMINT_ARCHIVE)
	mkdir -p "$@"
	cd "$@" && unzip ${FREEMINT_ARCHIVE} && cd -

$(EXT2_IMAGE): $(EXT2_DIR)
	genext2fs -b $$((${EXT2_IMAGE_SIZE} * 1024)) -d ${EXT2_DIR} "$@"
	rm -rf ${EXT2_DIR}

$(EXT2_DIR): $(BINUTILS_ARCHIVE) $(GCC_ARCHIVE) $(OPENSSH_DIR) $(OPKG_DIR)
	mkdir -p "$@"
	tar xjf ${BINUTILS_ARCHIVE} -C "$@"
	tar xjf ${GCC_ARCHIVE} -C "$@"

$(EMUTOS_DIR): $(EMUTOS_ARCHIVE)
	unzip ${EMUTOS_ARCHIVE}
	mv emutos-aranym-0.9.10 "$@"

$(OPENSSH_DIR):
	tar xzf ${OPENSSH_ARCHIVE}
	mv openssh-8.0p1 "$@"

$(OPKG_DIR):
	tar xjf ${OPKG_ARCHIVE}
	mv opkg-0.4.0 "$@"

$(BINUTILS_ARCHIVE):
	wget -O "$@" https://github.com/freemint/m68k-atari-mint-binutils-gdb/releases/download/binutils-2_30-mint/binutils-2.30-m68000mint.tar.bz2

$(GCC_ARCHIVE):
	wget -O "$@" https://github.com/freemint/m68k-atari-mint-gcc/releases/download/gcc-7_4_0-mint-20190228/gcc-7.4.0-m68000mint.tar.bz2

$(FREEMINT_ARCHIVE):
	wget -O "$@" https://bintray.com/freemint/freemint/download_file?file_path=snapshots-cpu%2F1-19-8c0c3f2f%2Ffreemint-1-19-cur-040.zip

$(EMUTOS_ARCHIVE):
	wget -O "$@" http://downloads.sourceforge.net/project/emutos/emutos/0.9.10/emutos-aranym-0.9.10.zip

$(OPENSSH_ARCHIVE):
	wget -O "$@" https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.0p1.tar.gz

$(OPKG_ARCHIVE):
	wget -O "$@" http://git.yoctoproject.org/cgit/cgit.cgi/opkg/snapshot/opkg-0.4.0.tar.bz2

clean:
	rm -rf ${FREEMINT_DIR}
	rm -rf ${EXT2_DIR}
	rm -rf ${EMUTOS_DIR}
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
	rm -f ${OPENSSH_ARCHIVE}
	rm -f ${OPKG_ARCHIVE}
