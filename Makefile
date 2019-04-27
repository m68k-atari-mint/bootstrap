BINUTILS_ARCHIVE = /tmp/gcc.tar.bz2
GCC_ARCHIVE      = /tmp/binutils.tar.bz2

EXT2_DIR         = ext2_content
EXT2_IMAGE       = ext2.img
EXT2_IMAGE_SIZ E = 512

TARGET = $(EXT2_IMAGE)

default: $(TARGET)

$(TARGET): $(EXT2_DIR)
	genext2fs -b $$((${EXT2_IMAGE_SIZE} * 1024)) -d ${EXT2_DIR} "$@"

$(EXT2_DIR): $(BINUTILS_ARCHIVE) $(GCC_ARCHIVE)
	mkdir -p "$@"
	tar xjf ${BINUTILS_ARCHIVE} -C "$@"
	tar xjf ${GCC_ARCHIVE} -C "$@"
	# TODO: build opkg with latest mintlib (but don't include mintlib in the image?)
	
$(BINUTILS_ARCHIVE):
	wget -O "$@" https://github.com/freemint/m68k-atari-mint-binutils-gdb/releases/download/binutils-2_30-mint/binutils-2.30-m68000mint.tar.bz2

$(GCC_ARCHIVE):
	wget -O "$@" https://github.com/freemint/m68k-atari-mint-gcc/releases/download/gcc-7_4_0-mint-20190228/gcc-7.4.0-m68000mint.tar.bz2
	
clean:
	rm -rf ${EXT2_DIR}
	rm -f ${EXT2_IMAGE}
	rm -f *~

distclean: clean
	rm -f ${BINUTILS_ARCHIVE}
	rm -f ${GCC_ARCHIVE}
