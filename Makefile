HOST_DRIVE	= drive_d
TARGET_DRIVE	= drive_e

HOST_IMAGE	= $(HOST_DRIVE).img
HOST_IMAGE_SIZE	= 256

TARGET_IMAGE	= $(TARGET_DRIVE).img
TARGET_IMAGE_SIZE = 256

CONFIG_DIR	= config
DOWNLOADS_DIR	= downloads
TOOLS_DIR	= tools
PATCHES_DIR	= patches

###############################################################################

default: emutos/.done freemint/.done $(HOST_IMAGE) aranym.config
	cp $(CONFIG_DIR)/mint.cnf freemint/mint/1-19-cur
	mkdir -p freemint/mint/bin
	cp $(TOOLS_DIR)/eth0-config.sh freemint/mint/bin
	cp $(TOOLS_DIR)/nfeth-config freemint/mint/bin
	aranym-mmu -c aranym.config

aranym.config:
	# unfortunately, ARAnyM can't have config in a subfolder
	cp $(CONFIG_DIR)/aranym.config .

$(HOST_IMAGE): $(HOST_DRIVE)/.done
	genext2fs -b $$(($(HOST_IMAGE_SIZE) * 1024)) -d $(HOST_DRIVE) --squash $@

$(HOST_DRIVE)/.done: bash/.done openssh/.done binutils/.done gcc/.done mintlib/.done fdlibm/.done
	mkdir -p $(HOST_DRIVE)/{boot,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var}

	cp -ra $(CONFIG_DIR)/{etc,var} $(HOST_DRIVE)

	cp -ra bash/* $(HOST_DRIVE)
	cp -ra openssh/* $(HOST_DRIVE)
	cp -ra binutils/* $(HOST_DRIVE)
	cp -ra gcc/* $(HOST_DRIVE)
	cp -ra mintlib/* $(HOST_DRIVE)
	cp -ra fdlibm/* $(HOST_DRIVE)

	# host's ssh-keygen is for some reason rejected ...
	#ssh-keygen -t rsa -N "" -f $(HOST_DRIVE)/etc/ssh/ssh_host_rsa_key
	#ssh-keygen -t dsa -N "" -f $(HOST_DRIVE)/etc/ssh/ssh_host_dsa_key
	#ssh-keygen -t ecdsa -N "" -f $(HOST_DRIVE)/etc/ssh/ssh_host_ecdsa_key
	mkdir -p $(HOST_DRIVE)/root/.ssh && cat $(HOME)/.ssh/id_rsa.pub >> $(HOST_DRIVE)/root/.ssh/authorized_keys

	touch $@

$(TARGET_DRIVE)/.done:
	mkdir -p $(TARGET_DRIVE)

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

mintlib-src/.done: $(DOWNLOADS_DIR)/mintlib.tar.gz
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

fdlibm-src/.done: $(DOWNLOADS_DIR)/fdlibm.tar.gz
	tar xzf $<
	mv fdlibm-master "fdlibm-src"
	touch $@

###############################################################################

$(DOWNLOADS_DIR)/emutos.zip:
	mkdir -p $(DOWNLOADS_DIR)
	wget -q -O $@ "http://downloads.sourceforge.net/project/emutos/emutos/0.9.10/emutos-aranym-0.9.10.zip"

$(DOWNLOADS_DIR)/freemint.zip:
	mkdir -p $(DOWNLOADS_DIR)
	wget -q -O $@ "https://bintray.com/freemint/freemint/download_file?file_path=snapshots-cpu%2F1-19-a3af9bdb%2Ffreemint-1-19-cur-040.zip"

$(DOWNLOADS_DIR)/bash.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	wget -q -O $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/bash/bash-4.4.12-bin-mint020-20170617.tar.bz2"

$(DOWNLOADS_DIR)/openssh.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	wget -q -O $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/openssh/openssh-6.4p1-bin-mint020-20131219.tar.bz2"

$(DOWNLOADS_DIR)/binutils.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	wget -q -O $@ "https://github.com/freemint/m68k-atari-mint-binutils-gdb/releases/download/binutils-2_30-mint/binutils-2.30-m68020-60mint.tar.bz2"

$(DOWNLOADS_DIR)/gcc.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	wget -q -O $@ "https://github.com/freemint/m68k-atari-mint-gcc/releases/download/gcc-7_4_0-mint-20190228/gcc-7.4.0-m68020-60mint.tar.bz2"

$(DOWNLOADS_DIR)/mintlib.tar.gz:
	mkdir -p $(DOWNLOADS_DIR)
	wget -q -O $@ "https://github.com/freemint/mintlib/archive/master.tar.gz"

$(DOWNLOADS_DIR)/fdlibm.tar.gz:
	mkdir -p $(DOWNLOADS_DIR)
	wget -q -O $@ "https://github.com/freemint/fdlibm/archive/master.tar.gz"

###############################################################################

clean:
	rm -f aranym.config
	rm -f $(HOST_IMAGE) $(TARGET_IMAGE)
	rm -rf $(HOST_DRIVE) $(TARGET_DRIVE)
	rm -rf emutos freemint bash openssh binutils gcc
	rm -rf mintlib-src mintlib fdlibm-src fdlibm

distclean: clean
	rm -rf $(DOWNLOADS_DIR)
