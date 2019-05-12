SHELL		:= /bin/bash

BOOT_DRIVE	:= $(PWD)/drive_c
HOST_DRIVE	:= $(PWD)/drive_d
TARGET_DRIVE	:= $(PWD)/drive_e

TARGET_IMAGE	= $(TARGET_DRIVE).img
TARGET_IMAGE_SIZE = 256

FINAL_IMAGE	= drive_f.img
FINAL_IMAGE_SIZE = 512

CONFIG_DIR	:= $(PWD)/config
DOWNLOADS_DIR	:= $(PWD)/downloads
TOOLS_DIR	:= $(PWD)/tools
PATCHES_DIR	:= $(PWD)/patches
SOURCES_DIR	:= $(PWD)/sources

WGET		:= wget -q --no-check-certificate -O
CONFIGURE	:= configure CFLAGS='-O2 -fomit-frame-pointer' --config-cache --prefix=/usr --exec-prefix=/
ARANYM_JIT	:= SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy aranym-jit -c aranym.config 2> /dev/null &
ARANYM_MMU	:= SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy aranym-mmu -c aranym.config 2> /dev/null &
SSH		:= ssh root@192.168.251.2

###############################################################################

default: emutos/.done $(BOOT_DRIVE)/.done $(HOST_DRIVE)/.done $(TARGET_IMAGE) aranym.config
	$(ARANYM_MMU)
	sleep 7
	$(SSH) "cp -ra /h/drive_e/* /e && chown -R root:root /e && chmod 700 /e/root/.ssh && chmod 600 /e/root/.ssh/authorized_keys"

	# ./configure in an MMU-enabled setup to avoid any nasty surprises
	$(SSH) "source /etc/profile; mkdir /e/root/bash && cd /e/root/bash && /root/bash/$(CONFIGURE) --disable-nls"
	$(SSH) "source /etc/profile; mkdir /e/root/bash-minimal && cd /e/root/bash-minimal && /root/bash-minimal/$(CONFIGURE) --disable-nls --enable-minimal-config --enable-alias --enable-strict-posix-default"
	$(SSH) "source /etc/profile; mkdir /e/root/bison && cd /e/root/bison && /root/bison/$(CONFIGURE) --disable-nls"
	$(SSH) "source /etc/profile; mkdir /e/root/gawk && cd /e/root/gawk && /root/gawk/$(CONFIGURE) --disable-nls"
	$(SSH) "source /etc/profile; mkdir /e/root/grep && cd /e/root/grep && /root/grep/$(CONFIGURE) --disable-nls"
	$(SSH) "source /etc/profile; mkdir /e/root/m4 && cd /e/root/m4 && /root/m4/$(CONFIGURE) --disable-nls"
	$(SSH) "source /etc/profile; mkdir /e/root/make && cd /e/root/make && /root/make/$(CONFIGURE) --disable-nls"
	$(SSH) "source /etc/profile; mkdir /e/root/sed && cd /e/root/sed && /root/sed/$(CONFIGURE) --disable-nls --disable-i18n"
	-$(SSH) "shutdown"
	sleep 7

	# make && make install in a fastest possible way
	$(ARANYM_JIT)
	sleep 7
	$(SSH) "source /etc/profile; cd /e/root/make && build.sh && strip -s make && cp make /bin && make install-strip DESTDIR=/e"
	# fdlibm, mintbin, mintlib (mam to uz v /root) - ostatne cez cross cc
	-$(SSH) "shutdown"

	#$(ARANYM_JIT)
	#sleep 7
	#$(SSH) "cd /e/root/bash-minimal && make && make install-strip DESTDIR=/e"
	# a bit hackish but this will ensure the safest ./configure environment for other packages
	#$(SSH) "mv /e/bin/bash /e/bin/sh && rm /bin/sh && cp /e/bin/sh /bin/sh"
	#$(SSH) "cd /e/root/bash && make && make install-strip DESTDIR=/e"
	#$(SSH) "rm /bin/bash && cp /e/bin/bash /bin/bash"
	#$(SSH) "cd /e/root/gawk && make && make install-strip DESTDIR=/e"
	#$(SSH) "cd /e/root/grep && make && make install-strip DESTDIR=/e"
	#$(SSH) "cd /e/root/sed && make && make install-strip DESTDIR=/e"

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

aranym.config:
	# unfortunately, ARAnyM can't have config in a subfolder
	cp $(CONFIG_DIR)/aranym.config .

$(HOST_DRIVE)/.done: $(HOST_DRIVE)/.bash.done oldstuff/.done $(HOST_DRIVE)/.openssh.done \
		binutils/.done gcc/.done $(HOST_DRIVE)/.mintbin.done $(HOST_DRIVE)/.mintlib.done $(HOST_DRIVE)/.fdlibm.done \
		$(HOST_DRIVE)/.fileutils.done $(HOST_DRIVE)/.sh-utils.done $(HOST_DRIVE)/.textutils.done $(HOST_DRIVE)/.sed.done $(HOST_DRIVE)/.gawk.done \
		$(HOST_DRIVE)/.grep.done $(HOST_DRIVE)/.diffutils.done $(HOST_DRIVE)/.bison.done $(HOST_DRIVE)/.m4.done $(HOST_DRIVE)/.hostname.done \
		$(SOURCES_DIR)/bash/.done $(SOURCES_DIR)/bison/.done $(SOURCES_DIR)/coreutils/.done $(SOURCES_DIR)/diffutils/.done $(SOURCES_DIR)/gawk/.done \
		$(SOURCES_DIR)/grep/.done $(SOURCES_DIR)/m4/.done $(SOURCES_DIR)/make/.done $(SOURCES_DIR)/sed/.done
	mkdir -p $(HOST_DRIVE)/{boot,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var}

	cp -ra $(CONFIG_DIR)/{etc,var} $(HOST_DRIVE)

	cp -ra oldstuff/* $(HOST_DRIVE)
	cp -ra binutils/* $(HOST_DRIVE)
	cp -ra gcc/* $(HOST_DRIVE)

	cp -ra $(SOURCES_DIR)/bash $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/bash $(HOST_DRIVE)/root/bash-minimal
	cp -ra $(SOURCES_DIR)/bison $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/coreutils $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/diffutils $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/gawk $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/grep $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/m4 $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/make $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/sed $(HOST_DRIVE)/root

	# no clue what is this about but it doesn't work
	rm $(HOST_DRIVE)/bin/awk
	rm $(HOST_DRIVE)/usr/bin/awk
	rm $(HOST_DRIVE)/usr/bin/gawk
	mkdir -p $(HOST_DRIVE)/root/.ssh && cat $(HOME)/.ssh/id_rsa.pub >> $(HOST_DRIVE)/root/.ssh/authorized_keys
	# it's a hostfs drive...
	sed -i -e 's/^#StrictModes yes/StrictModes no/;' $(HOST_DRIVE)/etc/ssh/sshd_config

	touch $@

$(TARGET_IMAGE): $(TARGET_DRIVE)/.done
	# unfortunately, we can't directly copy files to this image as with host drive
	# because genext2fs-produced images behave strangely when writing to them
	# so wait until aranym+sshd is running and copy the files then
	dd if=/dev/zero of=$@ bs=1M count=$(TARGET_IMAGE_SIZE)
	mkfs.ext2 $@

$(TARGET_DRIVE)/.done: binutils/.done gcc/.done oldstuff/.done $(SOURCES_DIR)/fdlibm/.done $(SOURCES_DIR)/mintbin/.done $(SOURCES_DIR)/mintlib/.done

	mkdir -p $(TARGET_DRIVE)
	mkdir -p $(TARGET_DRIVE)/{boot,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var}

	# cheat a little :)
	cp -ra binutils/* $(TARGET_DRIVE)
	cp -ra gcc/* $(TARGET_DRIVE)
	cp -ra oldstuff/* $(TARGET_DRIVE)

	cp -ra $(SOURCES_DIR)/fdlibm $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/mintbin $(TARGET_DRIVE)/root
	cp -ra $(SOURCES_DIR)/mintlib $(TARGET_DRIVE)/root

	mkdir -p $(TARGET_DRIVE)/root/.ssh && cat $(HOME)/.ssh/id_rsa.pub >> $(TARGET_DRIVE)/root/.ssh/authorized_keys

	touch $@

###############################################################################

emutos/.done: $(DOWNLOADS_DIR)/emutos.zip
	unzip -q $<
	mv emutos-aranym-* "emutos"
	touch $@

$(BOOT_DRIVE)/.done: $(DOWNLOADS_DIR)/freemint.zip $(CONFIG_DIR)/mint.cnf $(TOOLS_DIR)/eth0-config.sh $(TOOLS_DIR)/nfeth-config
	unzip -q $< -d $(BOOT_DRIVE)
	cp $(CONFIG_DIR)/mint.cnf $(BOOT_DRIVE)/mint/1-19-cur
	mkdir -p $(BOOT_DRIVE)/mint/bin
	cp $(TOOLS_DIR)/eth0-config.sh $(BOOT_DRIVE)/mint/bin
	cp $(TOOLS_DIR)/nfeth-config $(BOOT_DRIVE)/mint/bin
	touch $@

###############################################################################

$(HOST_DRIVE)/.bash.done: $(DOWNLOADS_DIR)/bash.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

oldstuff/.done: $(DOWNLOADS_DIR)/oldstuff.rpm
	mkdir -p $(HOST_DRIVE)
	mkdir "oldstuff" && cd "oldstuff" && rpmextract.sh $<
	#\
	#if [ $(shell which rpm2cpio) ]; \
	#then \
	#	rpm2cpio $< | cpio -i --make-directories; \
	#else \
	#	rpmextract.sh $<; \
	#fi
	touch $@

$(HOST_DRIVE)/.openssh.done: $(DOWNLOADS_DIR)/openssh.tar.bz2
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && tar xjf $<
	touch $@

binutils/.done: $(DOWNLOADS_DIR)/binutils.tar.bz2
	mkdir "binutils" && tar xjf $< -C "binutils"
	touch $@

gcc/.done: $(DOWNLOADS_DIR)/gcc.tar.bz2
	mkdir "gcc" && tar xjf $< -C "gcc"
	touch $@

$(HOST_DRIVE)/.mintbin.done: $(DOWNLOADS_DIR)/mintbin.tar.bz2
	cd $(HOST_DRIVE) && tar xjf $<
	touch $@

$(HOST_DRIVE)/.mintlib.done: mintlib-src/.done
	cd "mintlib-src" && \
	make SHELL=/bin/bash CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no prefix="/usr" && \
	make SHELL=/bin/bash CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no prefix="/usr" install DESTDIR=$(HOST_DRIVE)
	touch $@

mintlib-src/.done: $(DOWNLOADS_DIR)/mintlib-src.tar.gz
	tar xzf $<
	mv mintlib-master "mintlib-src"
	touch $@

$(HOST_DRIVE)/.fdlibm.done: fdlibm-src/.done
	cd "fdlibm-src" && \
	./configure --host=m68k-atari-mint --prefix="/usr" && \
	make CPU-FPU-TYPES=68020-60.68881 && \
	make CPU-FPU-TYPES=68020-60.68881 install DESTDIR=$(HOST_DRIVE)
	mv $(HOST_DRIVE)/usr/lib/m68020-60/* $(HOST_DRIVE)/usr/lib && rmdir $(HOST_DRIVE)/usr/lib/m68020-60
	touch $@

fdlibm-src/.done: $(DOWNLOADS_DIR)/fdlibm-src.tar.gz
	tar xzf $<
	mv fdlibm-master "fdlibm-src"
	touch $@

$(HOST_DRIVE)/.fileutils.done: $(DOWNLOADS_DIR)/fileutils.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@
$(HOST_DRIVE)/.sh-utils.done: $(DOWNLOADS_DIR)/sh-utils.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@
$(HOST_DRIVE)/.textutils.done: $(DOWNLOADS_DIR)/textutils.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

$(HOST_DRIVE)/.sed.done: $(DOWNLOADS_DIR)/sed.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

$(HOST_DRIVE)/.gawk.done: $(DOWNLOADS_DIR)/gawk.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

$(HOST_DRIVE)/.grep.done: $(DOWNLOADS_DIR)/grep.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

$(HOST_DRIVE)/.diffutils.done: $(DOWNLOADS_DIR)/diffutils.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

$(HOST_DRIVE)/.bison.done: $(DOWNLOADS_DIR)/bison.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

$(HOST_DRIVE)/.m4.done: $(DOWNLOADS_DIR)/m4.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

$(HOST_DRIVE)/.hostname.done: $(DOWNLOADS_DIR)/hostname.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && rpmextract.sh $<
	touch $@

###############################################################################

$(SOURCES_DIR)/bash/.done: $(SOURCES_DIR)/bash.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv bash-* "bash"
	cd $(SOURCES_DIR)/bash && cat $(PATCHES_DIR)/bash-4.2-patches/* | patch -p0
	cd $(SOURCES_DIR)/bash && cat $(PATCHES_DIR)/bash-4.2.53.patch | patch -p1
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

$(DOWNLOADS_DIR)/bash.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/mint/packages/bash-2.05a-4.m68kmint.rpm"

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

# coreutils
$(DOWNLOADS_DIR)/fileutils.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/fileutils-4.1-2.m68kmint.rpm"
$(DOWNLOADS_DIR)/sh-utils.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/sh-utils-2.0.11-1.m68kmint.rpm"
$(DOWNLOADS_DIR)/textutils.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/textutils-2.0.11-2.m68kmint.rpm"

$(DOWNLOADS_DIR)/sed.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/sed-4.2.1-1.m68kmint.rpm"

$(DOWNLOADS_DIR)/gawk.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/gawk-3.0.6-1.m68kmint.rpm"

$(DOWNLOADS_DIR)/grep.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/grep-2.4.2-1.m68kmint.rpm"

$(DOWNLOADS_DIR)/diffutils.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/diffutils-2.7-2.m68kmint.rpm"

$(DOWNLOADS_DIR)/bison.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/bison-1.875-2.m68kmint.rpm"

$(DOWNLOADS_DIR)/m4.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/m4-1.4.15-1.m68kmint.rpm"

$(DOWNLOADS_DIR)/hostname.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/hostname-2.07-1.m68kmint.rpm"

###############################################################################

$(SOURCES_DIR)/bash.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/bash/bash-4.2.tar.gz"

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
	rm -f $(TARGET_IMAGE) $(FINAL_IMAGE)
	rm -rf $(BOOT_DRIVE) $(HOST_DRIVE) $(TARGET_DRIVE)

.PHONY: clean
clean: driveclean
	rm -f *~
	rm -f aranym.config
	rm -rf emutos oldstuff binutils gcc
	rm -rf mintlib-src fdlibm-src
	rm -rf $(SOURCES_DIR)/{bash,bison,coreutils,diffutils,fdlibm,gawk,grep,m4,make,mintbin,mintlib,sed}

.PHONY: distclean
distclean: clean
	rm -rf $(DOWNLOADS_DIR) $(SOURCES_DIR)
