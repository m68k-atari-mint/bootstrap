HOST_DRIVE	= drive_d
TARGET_DRIVE	= drive_e
FINAL_DRIVE	= drive_f

HOST_IMAGE	= $(HOST_DRIVE).img
HOST_IMAGE_SIZE	= 256

TARGET_IMAGE	= $(TARGET_DRIVE).img
TARGET_IMAGE_SIZE = 512

FINAL_IMAGE	= $(FINAL_DRIVE).img
FINAL_IMAGE_SIZE = 512

CONFIG_DIR	= config
DOWNLOADS_DIR	= downloads
TOOLS_DIR	= tools
PATCHES_DIR	= patches

WGET		:= wget -q --no-check-certificate -O

###############################################################################

default: emutos/.done freemint/.done $(HOST_IMAGE) $(TARGET_IMAGE) aranym.config freemint/mint/1-19-cur/mint.cnf freemint/mint/bin/eth0-config.sh freemint/mint/bin/nfeth-config
	SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy aranym-mmu -c aranym.config 2> /dev/null &

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

$(HOST_DRIVE)/.done: bash/.done oldstuff/.done openssh/.done binutils/.done gcc/.done mintlib/.done fdlibm/.done coreutils/.done sed/.done awk/.done grep/.done diffutils/.done make/.done
	mkdir -p $(HOST_DRIVE)/{boot,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var}

	cp -ra $(CONFIG_DIR)/{etc,var} $(HOST_DRIVE)

	cp -ra bash/* $(HOST_DRIVE)
	cp -ra oldstuff/* $(HOST_DRIVE)
	cp -ra openssh/* $(HOST_DRIVE)
	cp -ra binutils/* $(HOST_DRIVE)
	cp -ra gcc/* $(HOST_DRIVE)
	cp -ra mintlib/* $(HOST_DRIVE)
	cp -ra fdlibm/* $(HOST_DRIVE)
	cp -ra coreutils/* $(HOST_DRIVE)
	cp -ra sed/* $(HOST_DRIVE)
	cp -ra awk/* $(HOST_DRIVE)
	cp -ra grep/* $(HOST_DRIVE)
	cp -ra diffutils/* $(HOST_DRIVE)
	cp -ra make/* $(HOST_DRIVE)

	ln -s bash $(HOST_DRIVE)/bin/sh

	# host's ssh-keygen is for some reason rejected ...
	#ssh-keygen -t rsa -N "" -f $(HOST_DRIVE)/etc/ssh/ssh_host_rsa_key
	#ssh-keygen -t dsa -N "" -f $(HOST_DRIVE)/etc/ssh/ssh_host_dsa_key
	#ssh-keygen -t ecdsa -N "" -f $(HOST_DRIVE)/etc/ssh/ssh_host_ecdsa_key
	mkdir -p $(HOST_DRIVE)/root/.ssh && cat $(HOME)/.ssh/id_rsa.pub >> $(HOST_DRIVE)/root/.ssh/authorized_keys

	touch $@

$(TARGET_IMAGE): $(TARGET_DRIVE)/.done
	# unfortunately, we can't directly copy files to this image as with host drive
	# because genext2fs-produced images behave strangely when writing to them
	# so wait until aranym+sshd is running and copy the files then
	dd if=/dev/zero of=$@ bs=1M count=$(TARGET_IMAGE_SIZE)
	mkfs.ext2 $@

$(TARGET_DRIVE)/.done: binutils/.done gcc/.done
	mkdir -p $(TARGET_DRIVE)

	# cheat a little :)
	cp -ra binutils/* $(TARGET_DRIVE)
	cp -ra gcc/* $(TARGET_DRIVE)
	cp -ra oldstuff/* $(TARGET_DRIVE)

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
	mkdir "oldstuff" && cd "oldstuff" && rpmextract.sh ../$<
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

mintlib/.done: mintlib-src/.done
	cd "mintlib-src" && \
	make CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no prefix="/usr" && \
	make CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no prefix="/usr" install DESTDIR=$(PWD)/mintlib
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

awk/.done: $(DOWNLOADS_DIR)/awk.tar.bz2
	mkdir "awk" && tar xjf $< -C "awk"
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

$(DOWNLOADS_DIR)/awk.tar.bz2:
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

###############################################################################

driveclean:
	rm -f $(HOST_IMAGE) $(TARGET_IMAGE)

clean:
	rm -f aranym.config
	rm -f $(HOST_IMAGE) $(TARGET_IMAGE)
	rm -rf $(HOST_DRIVE) $(TARGET_DRIVE)
	rm -rf emutos freemint bash oldstuff openssh binutils gcc
	rm -rf mintlib-src mintlib fdlibm-src fdlibm
	rm -rf coreutils sed awk grep diffutils make

distclean: clean
	rm -rf $(DOWNLOADS_DIR)
