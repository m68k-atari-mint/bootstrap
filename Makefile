HOST_DRIVE	= drive_d
TARGET_DRIVE	= drive_e

CONFIG_DIR	= config
DOWNLOADS_DIR	= downloads

###############################################################################

default: $(HOST_DRIVE)/.done

$(HOST_DRIVE)/.done: emutos/.done freemint/.done bash/.done binutils/.done gcc/.done
	mkdir -p $(HOST_DRIVE)
	touch $@

$(TARGET_DRIVE)/.done:
	mkdir -p $(TARGET_DRIVE)
	touch $@

###############################################################################

emutos/.done: $(DOWNLOADS_DIR)/emutos.zip
	unzip -q $<
	mv emutos-aranym-* "emutos"
	touch $@

freemint/.done: $(DOWNLOADS_DIR)/freemint.zip
	unzip -q $< -d "freemint"
	touch $@

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

###############################################################################

clean:
	rm -rf $(HOST_DRIVE) $(TARGET_DRIVE)
	rm -rf emutos freemint bash openssh binutils gcc

distclean: clean
	rm -rf $(DOWNLOADS_DIR)
