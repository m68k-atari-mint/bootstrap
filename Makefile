SHELL		:= /bin/bash

HOST_DRIVE	= drive_d
TARGET_DRIVE	= drive_e
FINAL_DRIVE	= drive_f

HOST_IMAGE	= $(HOST_DRIVE).img
HOST_IMAGE_SIZE	= 256

TARGET_IMAGE	= $(TARGET_DRIVE).img
TARGET_IMAGE_SIZE = 1024

FINAL_IMAGE	= $(FINAL_DRIVE).img
FINAL_IMAGE_SIZE = 512

CONFIG_DIR	:= $(PWD)/config
DOWNLOADS_DIR	:= $(PWD)/downloads
TOOLS_DIR	:= $(PWD)/tools
PATCHES_DIR	:= $(PWD)/patches
SOURCES_DIR	:= $(PWD)/sources

WGET		:= wget -q --no-check-certificate -O
CONFIGURE	:= source /etc/profile; ./configure CFLAGS='-O2 -fomit-frame-pointer -I/usr/local/include' LDFLAGS='-L/usr/local/lib'
BASH_CONFIGURE	:= source /etc/profile; /bin/bash ./configure CFLAGS='-O2 -fomit-frame-pointer -I/usr/local/include' LDFLAGS='-L/usr/local/lib'
ARANYM_JIT	:= SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy aranym-jit -c aranym.config 2> /dev/null &
ARANYM_MMU	:= SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy aranym-mmu -c aranym.config 2> /dev/null &
SSH		:= ssh root@192.168.251.2

###############################################################################

default: emutos/.done freemint/.done $(HOST_IMAGE) $(TARGET_IMAGE) aranym.config freemint/mint/1-19-cur/mint.cnf freemint/mint/bin/eth0-config.sh freemint/mint/bin/nfeth-config
	$(ARANYM_JIT)
	sleep 3
	$(SSH) "cp -ra --no-preserve=ownership /g/$(TARGET_DRIVE)/* /e"
	-$(SSH) "shutdown"
	sleep 7

	# ./configure in an MMU-enabled setup to avoid any nasty surprises
	$(ARANYM_MMU)
	sleep 3
	$(SSH) "cd /e/root/bash-minimal && $(CONFIGURE) --prefix=/usr --exec-prefix=/ --disable-nls --enable-minimal-config"
	$(SSH) "cd /e/root/bash && $(CONFIGURE) --prefix=/usr --exec-prefix=/ --disable-nls"
	-$(SSH) "shutdown"
	sleep 7
	# make && make install in a fastest possible way
	$(ARANYM_JIT)
	sleep 3
	$(SSH) "cd /e/root/bash-minimal && make && make install-strip DESTDIR=/e"
	# a bit hackish but this will ensure the safest ./configure environment for other packages
	$(SSH) "mv /e/bin/bash /e/bin/sh && rm /bin/sh && cp /e/bin/sh /bin"
	$(SSH) "cd /e/root/bash && make && make install-strip DESTDIR=/e"
	$(SSH) "rm /bin/bash && cp /e/bin/bash /bin"
	-$(SSH) "shutdown"
	sleep 7

	$(ARANYM_MMU)
	sleep 3
	$(SSH) "cd /e/root/gawk && $(CONFIGURE) --prefix=/usr --exec-prefix=/ --disable-nls"
	# grep is lying, its ./configure needs full bash to work properly
	$(SSH) "cd /e/root/grep && $(BASH_CONFIGURE) --prefix=/usr --exec-prefix=/ --disable-nls"
	$(SSH) "cd /e/root/sed && $(CONFIGURE) --prefix=/usr --exec-prefix=/ --disable-nls --disable-i18n"
	$(SSH) "cd /e/root/make && $(CONFIGURE) --prefix=/usr --exec-prefix=/ --disable-nls"
	-$(SSH) "shutdown"
	sleep 7

	$(ARANYM_JIT)
	sleep 3
	$(SSH) "cd /e/root/gawk && make && make install-strip DESTDIR=/e"
	$(SSH) "cd /e/root/grep && make && make install-strip DESTDIR=/e"
	$(SSH) "cd /e/root/sed && make && make install-strip DESTDIR=/e"
	$(SSH) "cd /e/root/make && make && make install-strip DESTDIR=/e"

	# needs m4
	#ssh root@192.168.251.2 "cd /e/root/bison && $(CONFIGURE) --prefix=/usr --disable-nls && make && make install DESTDIR=/e"

	#cp -ra $(SOURCES_DIR)/coreutils $(TARGET_DRIVE)/root
	#cp -ra $(SOURCES_DIR)/diffutils $(TARGET_DRIVE)/root
	#cp -ra $(SOURCES_DIR)/fdlibm $(TARGET_DRIVE)/root
	#cp -ra $(SOURCES_DIR)/mintbin $(TARGET_DRIVE)/root
	# needs bison, flex, bash
	#cp -ra $(SOURCES_DIR)/mintlib $(TARGET_DRIVE)/root

.PHONY: configure
configure:

.PHONY: build
build:

freemint/mint/1-19-cur/mint.cnf: $(CONFIG_DIR)/mint.cnf
	cp $< $@

freemint/mint/bin/eth0-config.sh: $(TOOLS_DIR)/eth0-config.sh
	mkdir -p freemint/mint/bin
	cp $< $@
freemint/mint/bin/nfeth-config: $(TOOLS_DIR)/nfeth-config
	mkdir -p freemint/mint/bin
	cp $< $@

aranym.config:
	# unfortunately, ARAnyM can't have config in a subfolder
	cp $(CONFIG_DIR)/aranym.config .

$(HOST_IMAGE): $(HOST_DRIVE)/.done
	genext2fs -b $$(($(HOST_IMAGE_SIZE) * 1024)) -d $(HOST_DRIVE) --squash $@

$(HOST_DRIVE)/.done: bash/.done oldstuff/.done openssh/.done binutils/.done gcc/.done mintbin/.done mintlib/.done fdlibm/.done coreutils/.done sed/.done gawk/.done grep/.done diffutils/.done make/.done bison/.done
	mkdir -p $(HOST_DRIVE)/{boot,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var}

	cp -ra $(CONFIG_DIR)/{etc,var} $(HOST_DRIVE)

	cp -ra bash/* $(HOST_DRIVE)
	cp -ra oldstuff/* $(HOST_DRIVE)
	cp -ra openssh/* $(HOST_DRIVE)
	cp -ra binutils/* $(HOST_DRIVE)
	cp -ra gcc/* $(HOST_DRIVE)
	cp -ra mintbin/* $(HOST_DRIVE)
	cp -ra mintlib/* $(HOST_DRIVE)
	cp -ra fdlibm/* $(HOST_DRIVE)
	cp -ra coreutils/* $(HOST_DRIVE)
	cp -ra sed/* $(HOST_DRIVE)
	cp -ra gawk/* $(HOST_DRIVE)
	cp -ra grep/* $(HOST_DRIVE)
	cp -ra diffutils/* $(HOST_DRIVE)
	cp -ra make/* $(HOST_DRIVE)
	cp -ra bison/* $(HOST_DRIVE)

	ln -s bash $(HOST_DRIVE)/bin/sh

	mkdir -p $(HOST_DRIVE)/root/.ssh && cat $(HOME)/.ssh/id_rsa.pub >> $(HOST_DRIVE)/root/.ssh/authorized_keys

	touch $@

$(TARGET_IMAGE): $(TARGET_DRIVE)/.done
	# unfortunately, we can't directly copy files to this image as with host drive
	# because genext2fs-produced images behave strangely when writing to them
	# so wait until aranym+sshd is running and copy the files then
	dd if=/dev/zero of=$@ bs=1M count=$(TARGET_IMAGE_SIZE)
	mkfs.ext2 $@

$(TARGET_DRIVE)/.done: binutils/.done gcc/.done oldstuff/.done $(SOURCES_DIR)/bash/.done $(SOURCES_DIR)/bison/.done $(SOURCES_DIR)/coreutils/.done $(SOURCES_DIR)/diffutils/.done $(SOURCES_DIR)/fdlibm/.done $(SOURCES_DIR)/gawk/.done $(SOURCES_DIR)/grep/.done $(SOURCES_DIR)/m4/.done $(SOURCES_DIR)/make/.done $(SOURCES_DIR)/mintbin/.done $(SOURCES_DIR)/mintlib/.done $(SOURCES_DIR)/sed/.done

	mkdir -p $(TARGET_DRIVE)
	mkdir -p $(TARGET_DRIVE)/{boot,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var}

	# cheat a little :)
	cp -ra binutils/* $(TARGET_DRIVE)
	cp -ra gcc/* $(TARGET_DRIVE)
	cp -ra oldstuff/* $(TARGET_DRIVE)

	cp -ra $(SOURCES_DIR)/bash $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/bash $(TARGET_DRIVE)/root/bash-minimal
	cp -ra $(SOURCES_DIR)/bison $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/coreutils $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/diffutils $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/fdlibm $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/gawk $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/grep $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/m4 $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/make $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/mintbin $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/mintlib $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/sed $(TARGET_DRIVE)/root

	mkdir -p $(TARGET_DRIVE)/root/.ssh && cat $(HOME)/.ssh/id_rsa.pub >> $(TARGET_DRIVE)/root/.ssh/authorized_keys

	touch $@

###############################################################################

emutos/.done: $(DOWNLOADS_DIR)/emutos.zip
	unzip -q $<
	mv emutos-aranym-* "emutos"
	touch $@

freemint/.done: $(DOWNLOADS_DIR)/freemint.zip
	unzip -q $< -d "freemint"
	touch $@

###############################################################################

bash/.done: $(DOWNLOADS_DIR)/bash.tar.bz2
	mkdir "bash" && tar xjf $< -C "bash"
	touch $@

oldstuff/.done: $(DOWNLOADS_DIR)/oldstuff.rpm
	mkdir "oldstuff" && cd "oldstuff" && rpmextract.sh $<
	#\
	#if [ $(shell which rpm2cpio) ]; \
	#then \
	#	rpm2cpio $< | cpio -i --make-directories; \
	#else \
	#	rpmextract.sh $<; \
	#fi
	touch $@

openssh/.done: $(DOWNLOADS_DIR)/openssh.tar.bz2
	mkdir "openssh" && tar xjf $< -C "openssh"
	touch $@

binutils/.done: $(DOWNLOADS_DIR)/binutils.tar.bz2
	mkdir "binutils" && tar xjf $< -C "binutils"
	touch $@

gcc/.done: $(DOWNLOADS_DIR)/gcc.tar.bz2
	mkdir "gcc" && tar xjf $< -C "gcc"
	touch $@

mintbin/.done: $(DOWNLOADS_DIR)/mintbin.tar.bz2
	mkdir "mintbin" && tar xjf $< -C "mintbin"
	touch $@

mintlib/.done: mintlib-src/.done
	cd "mintlib-src" && \
	make SHELL=/bin/bash CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no prefix="/usr" && \
	make SHELL=/bin/bash CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no prefix="/usr" install DESTDIR=$(PWD)/mintlib
	touch $@

mintlib-src/.done: $(DOWNLOADS_DIR)/mintlib-src.tar.gz
	tar xzf $<
	mv mintlib-master "mintlib-src"
	touch $@

fdlibm/.done: fdlibm-src/.done
	cd "fdlibm-src" && \
	./configure --host=m68k-atari-mint --prefix="/usr" && \
	make CPU-FPU-TYPES=68020-60.68881 && \
	make CPU-FPU-TYPES=68020-60.68881 install DESTDIR=$(PWD)/fdlibm
	mv fdlibm/usr/lib/m68020-60/* fdlibm/usr/lib && rmdir fdlibm/usr/lib/m68020-60
	touch $@

fdlibm-src/.done: $(DOWNLOADS_DIR)/fdlibm-src.tar.gz
	tar xzf $<
	mv fdlibm-master "fdlibm-src"
	touch $@

coreutils/.done: $(DOWNLOADS_DIR)/coreutils.tar.bz2
	mkdir "coreutils" && tar xjf $< -C "coreutils"
	touch $@

sed/.done: $(DOWNLOADS_DIR)/sed.tar.bz2
	mkdir "sed" && tar xjf $< -C "sed"
	touch $@

gawk/.done: $(DOWNLOADS_DIR)/gawk.tar.bz2
	mkdir "gawk" && tar xjf $< -C "gawk"
	touch $@

grep/.done: $(DOWNLOADS_DIR)/grep.tar.bz2
	mkdir "grep" && tar xjf $< -C "grep"
	touch $@

diffutils/.done: $(DOWNLOADS_DIR)/diffutils.tar.bz2
	mkdir "diffutils" && tar xjf $< -C "diffutils"
	touch $@

make/.done: $(DOWNLOADS_DIR)/make.tar.bz2
	mkdir "make" && tar xjf $< -C "make"
	touch $@

bison/.done: $(DOWNLOADS_DIR)/bison.tar.bz2
	mkdir "bison" && tar xjf $< -C "bison"
	touch $@

###############################################################################

$(SOURCES_DIR)/bash/.done: $(SOURCES_DIR)/bash.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv bash-* "bash"
	cd $(SOURCES_DIR)/bash && cat $(PATCHES_DIR)/bash-4.4-patches/* | patch -p0
	touch $@

$(SOURCES_DIR)/bison/.done: $(SOURCES_DIR)/bison.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv bison-* "bison"
	touch $@

$(SOURCES_DIR)/coreutils/.done: $(SOURCES_DIR)/coreutils.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv coreutils-* "coreutils"
	touch $@

$(SOURCES_DIR)/diffutils/.done: $(SOURCES_DIR)/diffutils.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv diffutils-* "diffutils"
	touch $@

$(SOURCES_DIR)/fdlibm/.done: $(SOURCES_DIR)/fdlibm.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv fdlibm-master "fdlibm"
	touch $@

$(SOURCES_DIR)/gawk/.done: $(SOURCES_DIR)/gawk.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv gawk-* "gawk"
	touch $@

$(SOURCES_DIR)/grep/.done: $(SOURCES_DIR)/grep.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv grep-* "grep"
	touch $@

$(SOURCES_DIR)/m4/.done: $(SOURCES_DIR)/m4.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv m4-* "m4"
	touch $@

$(SOURCES_DIR)/make/.done: $(SOURCES_DIR)/make.tar.bz2
	cd $(SOURCES_DIR) && tar xjf $< && mv make-* "make"
	touch $@

$(SOURCES_DIR)/mintbin/.done: $(SOURCES_DIR)/mintbin.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv mintbin-master "mintbin"
	touch $@

$(SOURCES_DIR)/mintlib/.done: $(SOURCES_DIR)/mintlib.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv mintlib-master "mintlib"
	touch $@

$(SOURCES_DIR)/sed/.done: $(SOURCES_DIR)/sed.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv sed-* "sed"
	touch $@

###############################################################################

$(DOWNLOADS_DIR)/emutos.zip:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://downloads.sourceforge.net/project/emutos/snapshots/20190505-153546-7d0cad1/emutos-aranym-20190505-153546-7d0cad1.zip"

$(DOWNLOADS_DIR)/freemint.zip:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://bintray.com/freemint/freemint/download_file?file_path=snapshots-cpu%2F1-19-a3af9bdb%2Ffreemint-1-19-cur-040.zip"

$(DOWNLOADS_DIR)/bash.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/bash/bash-4.4.12-bin-mint020-20170617.tar.bz2"

$(DOWNLOADS_DIR)/oldstuff.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/oldstuff-1.0-3.m68kmint.rpm"

$(DOWNLOADS_DIR)/openssh.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/openssh/openssh-6.4p1-bin-mint020-20131219.tar.bz2"

$(DOWNLOADS_DIR)/binutils.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://github.com/freemint/m68k-atari-mint-binutils-gdb/releases/download/binutils-2_30-mint/binutils-2.30-m68020-60mint.tar.bz2"

$(DOWNLOADS_DIR)/gcc.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://github.com/freemint/m68k-atari-mint-gcc/releases/download/gcc-7_4_0-mint-20190228/gcc-7.4.0-m68020-60mint.tar.bz2"

$(DOWNLOADS_DIR)/mintbin.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://github.com/freemint/freemint.github.io/raw/master/builds/mintbin/master/mintbin-6108285.tar.bz2"

$(DOWNLOADS_DIR)/mintlib-src.tar.gz:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://github.com/freemint/mintlib/archive/master.tar.gz"

$(DOWNLOADS_DIR)/fdlibm-src.tar.gz:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://github.com/freemint/fdlibm/archive/master.tar.gz"

$(DOWNLOADS_DIR)/coreutils.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/coreutils/coreutils-8.21-mint-20131205-bin-mint020-20131219.tar.bz2"

$(DOWNLOADS_DIR)/sed.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/sed/sed-4.2.2-bin-mint020-20131119.tar.bz2"

$(DOWNLOADS_DIR)/gawk.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/gawk/gawk-4.1.0-bin-mint020-20131120.tar.bz2"

$(DOWNLOADS_DIR)/grep.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/grep/grep-2.15-bin-mint020-20131117.tar.bz2"

$(DOWNLOADS_DIR)/diffutils.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/diffutils/diffutils-3.3-bin-mint020-20131120.tar.bz2"

$(DOWNLOADS_DIR)/make.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/make/make-4.0-bin-mint020-20131109.tar.bz2"

$(DOWNLOADS_DIR)/bison.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/bison/bison-3.0.1-bin-mint020-20131121.tar.bz2"

###############################################################################

$(SOURCES_DIR)/bash.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/bash/bash-4.4.tar.gz"

$(SOURCES_DIR)/bison.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/bison/bison-3.3.2.tar.xz"

$(SOURCES_DIR)/coreutils.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/coreutils/coreutils-8.31.tar.xz"

$(SOURCES_DIR)/diffutils.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz"

$(SOURCES_DIR)/fdlibm.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://github.com/freemint/fdlibm/archive/master.tar.gz"

$(SOURCES_DIR)/gawk.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/gawk/gawk-5.0.0.tar.xz"

$(SOURCES_DIR)/grep.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/grep/grep-3.3.tar.xz"

$(SOURCES_DIR)/m4.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz"

$(SOURCES_DIR)/make.tar.bz2:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/make/make-4.2.1.tar.bz2"

$(SOURCES_DIR)/mintbin.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://github.com/freemint/mintbin/archive/master.tar.gz"

$(SOURCES_DIR)/mintlib.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://github.com/freemint/mintlib/archive/master.tar.gz"

$(SOURCES_DIR)/sed.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/sed/sed-4.7.tar.xz"

###############################################################################

.PHONY: driveclean
driveclean:
	rm -f $(HOST_IMAGE) $(TARGET_IMAGE) $(FINAL_IMAGE)
	rm -rf $(HOST_DRIVE) $(TARGET_DRIVE) $(FINAL_DRIVE)

.PHONY: clean
clean: driveclean
	rm -f *~
	rm -f aranym.config
	rm -rf emutos freemint bash oldstuff openssh binutils gcc mintbin
	rm -rf mintlib-src mintlib fdlibm-src fdlibm
	rm -rf coreutils sed gawk grep diffutils make bison
	rm -rf $(SOURCES_DIR)/{bash,bison,coreutils,diffutils,fdlibm,gawk,grep,m4,make,mintbin,mintlib,sed}

.PHONY: distclean
distclean: clean
	rm -rf $(DOWNLOADS_DIR) $(SOURCES_DIR)
