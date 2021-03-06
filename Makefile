SHELL		:= /bin/bash

BOOT_DRIVE	:= $(PWD)/drive_c
HOST_DRIVE	:= $(PWD)/drive_d

TARGET_IMAGE	= drive_e.img
TARGET_IMAGE_SIZE = 512

FINAL_IMAGE	= drive_f.img
FINAL_IMAGE_SIZE = 512

BUILD_DIR	:= $(PWD)/build
CONFIG_DIR	:= $(PWD)/config
DOWNLOADS_DIR	:= $(PWD)/downloads
PATCHES_DIR	:= $(PWD)/patches
SOURCES_DIR	:= $(PWD)/sources
TOOLS_DIR	:= $(PWD)/tools

WGET		:= wget -q --no-check-certificate -O
RPM_EXTRACT	:= $(PWD)/rpm_extract.sh
CONFIGURE	:= configure CFLAGS=\'-O2 -fomit-frame-pointer\' --prefix=/usr --exec-prefix=
ARANYM_JIT	:= $(PWD)/aranym-jit.sh
ARANYM_MMU	:= $(PWD)/aranym-mmu.sh
SSH		:= ssh -o "StrictHostKeyChecking no" root@192.168.251.2 source /etc/profile\;
AND		:= \&\&

###############################################################################

.PHONY: prepare_boot
prepare_boot: emutos/.done id_rsa.pub $(BOOT_DRIVE)/.done

.PHONY: prepare
prepare: prepare_boot $(HOST_DRIVE)/.done $(TARGET_IMAGE) $(FINAL_IMAGE) setup_build

.PHONY: build
build: configure1 build1 configure2 build2 configure3 build3 configure4 build4 configure5 build5 configure6 build6 configure7 build7 configure8 build8

.PHONY: shutdown
shutdown:
	$(SSH) shutdown || sleep 1

###############################################################################

.PHONY: setup_build
setup_build: $(BUILD_DIR)/.setup.done

$(BUILD_DIR)/.setup.done:
	mkdir -p $(BUILD_DIR)

	$(ARANYM_MMU)

	$(SSH) mkdir -p /f/{boot,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var,var/log,var/run}
	$(SSH) cp -a /sbin/shutdown /f/sbin/shutdown
	$(SSH) cp -a /etc/{group,hostname,passwd} /f/etc
	$(SSH) cp -a /etc/profile.target /f/etc/profile
	$(SSH) touch /f/etc/utmp
	$(SSH) touch /f/var/log/lastlog
	$(SSH) touch /f/var/run/utmp
	$(SSH) mkdir -p /f/var/empty

	touch $@

# ./configure in an MMU-enabled setup to avoid nasty surprises

.PHONY: configure1
configure1: $(BUILD_DIR)/.zlib.configured

$(BUILD_DIR)/.zlib.configured:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_MMU)
	$(SSH) rm -rf /e/root/zlib $(AND) mkdir -p /e/root/zlib $(AND) cd /e/root/zlib \
		$(AND) export CFLAGS=\'-O2 -fomit-frame-pointer\' \
		$(AND) /root/zlib/configure --prefix=/usr --static
	touch $@

.PHONY: configure2
configure2: $(BUILD_DIR)/.openssl.configured

$(BUILD_DIR)/.openssl.configured:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_MMU)
	$(SSH) rm -rf /e/root/openssl $(AND) cp -ra /d/root/openssl /e/root/openssl $(AND) cd /e/root/openssl \
		$(AND) ./Configure -DB_ENDIAN -DOPENSSL_USE_IPV6=0 -DDEVRANDOM=\\\"/dev/urandom\\\",\\\"/dev/random\\\" -L/e/usr/lib -I/e/usr/include no-shared no-threads no-makedepend zlib --prefix=/usr gcc:gcc -O2 -fomit-frame-pointer
	touch $@

.PHONY: configure3
configure3: $(BUILD_DIR)/.libarchive.configured

$(BUILD_DIR)/.libarchive.configured:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_MMU)
	$(SSH) rm -rf /e/root/libarchive $(AND) mkdir -p /e/root/libarchive $(AND) cd /e/root/libarchive \
		$(AND) /root/libarchive/configure CFLAGS=\'-O2 -fomit-frame-pointer -I/e/usr/include\' LDFLAGS=\'-L/e/usr/lib\' --prefix=/usr
	touch $@

.PHONY: configure4
configure4: $(BUILD_DIR)/.openssh.configured

$(BUILD_DIR)/.openssh.configured:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_MMU)
	$(SSH) rm -rf /e/root/openssh $(AND) mkdir -p /e/root/openssh $(AND) cd /e/root/openssh \
		$(AND) /root/openssh/$(CONFIGURE) --sysconfdir=/etc/ssh --without-stackprotect --with-zlib=/e/usr --with-ssl-dir=/e/usr ac_cv_member_struct_stat_st_mtim=no
	touch $@

.PHONY: configure5
configure5: $(BUILD_DIR)/.opkg.configured

$(BUILD_DIR)/.opkg.configured:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_MMU)
	$(SSH) rm -rf /e/root/opkg $(AND) mkdir -p /e/root/opkg $(AND) cd /e/root/opkg \
		$(AND) export LIBARCHIVE_CFLAGS=\'-I/e/usr/include\' $(AND) export LIBARCHIVE_LIBS=\'-L/e/usr/lib -larchive\' \
		$(AND) /root/opkg/$(CONFIGURE) --disable-curl --disable-gpg
	touch $@

.PHONY: configure6
configure6: $(BUILD_DIR)/.sh.configured

$(BUILD_DIR)/.sh.configured:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_MMU)
	$(SSH) rm -rf /e/root/bash-minimal $(AND) mkdir -p /e/root/bash-minimal $(AND) cd /e/root/bash-minimal \
		$(AND) /root/bash-minimal/$(CONFIGURE) --disable-nls --enable-minimal-config --enable-alias --enable-strict-posix-default
	touch $@

.PHONY: configure7
configure7: $(BUILD_DIR)/.bash.configured

$(BUILD_DIR)/.bash.configured:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_MMU)
	$(SSH) rm -rf /e/root/bash $(AND) mkdir -p /e/root/bash $(AND) cd /e/root/bash \
		$(AND) /root/bash/$(CONFIGURE) --disable-nls
	touch $@

.PHONY: configure8
configure8: $(BUILD_DIR)/.coreutils.configured

$(BUILD_DIR)/.coreutils.configured:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_MMU)
	# We need mkdir, chown etc for public_key.sh (build it as part of /f for now, later: opkg)
	# We have to disable help2man because it requires Perl 5.8.0 while we have only 5.6.0
	$(SSH) rm -rf /e/root/coreutils $(AND) mkdir -p /e/root/coreutils $(AND) cd /e/root/coreutils \
		$(AND) export FORCE_UNSAFE_CONFIGURE=1 \
		$(AND) /root/coreutils/$(CONFIGURE) --disable-nls \
		$(AND) sed -i \'s/^\\\(run_help2man = $$\(PERL\)\\\)/#\\1/\;\' Makefile \
		$(AND) sed -i \'s/^#\\\(run_help2man = $$\(SHELL\)\\\)/\\1/\;\' Makefile
	touch $@

# make && make install in the fastest possible way

.PHONY: build1
build1: configure1 $(BUILD_DIR)/.zlib.done

$(BUILD_DIR)/.zlib.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/zlib $(AND) make $(AND) make install DESTDIR=/e
	touch $@

.PHONY: build2 build2.1 build2.2
build2: build2.1 build2.2
build2.1: configure2 $(BUILD_DIR)/.openssl-1.done
build2.2: $(BUILD_DIR)/.openssl-2.done

$(BUILD_DIR)/.openssl-1.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/openssl $(AND) make build_libs
	touch $@

$(BUILD_DIR)/.openssl-2.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/openssl $(AND) make $(AND) make install_sw INSTALL_PREFIX=/e
	touch $@

.PHONY: build3
build3: configure3 $(BUILD_DIR)/.libarchive.done

$(BUILD_DIR)/.libarchive.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/libarchive $(AND) make $(AND) make install-strip DESTDIR=/e
	touch $@

.PHONY: build4
build4: configure4 $(BUILD_DIR)/.openssh.done

$(BUILD_DIR)/.openssh.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/openssh $(AND) make \
		$(AND) mkdir -p /f/etc/ssh \
		$(AND) ./ssh-keygen -t rsa -f /f/etc/ssh/ssh_host_rsa_key -q -N \"\" \
		$(AND) ./ssh-keygen -t ecdsa -f /f/etc/ssh/ssh_host_ecdsa_key -q -N \"\" \
		$(AND) ./ssh-keygen -t ed25519 -f /f/etc/ssh/ssh_host_ed25519_key -q -N \"\" \
		$(AND) make install DESTDIR=/f
	touch $@

.PHONY: build5
build5: configure5 $(BUILD_DIR)/.opkg.done

$(BUILD_DIR)/.opkg.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/opkg $(AND) make $(AND) make install-strip DESTDIR=/f
	touch $@

.PHONY: build6
build6: configure6 $(BUILD_DIR)/.sh.done

$(BUILD_DIR)/.sh.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/bash-minimal $(AND) make $(AND) make install-strip DESTDIR=/f $(AND) mv /f/bin/bash /f/bin/sh
	touch $@

.PHONY: build7
build7: configure7 $(BUILD_DIR)/.bash.done

$(BUILD_DIR)/.bash.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/bash $(AND) make $(AND) make install-strip DESTDIR=/f
	touch $@

.PHONY: build8
build8: configure8 $(BUILD_DIR)/.coreutils.done

$(BUILD_DIR)/.coreutils.done:
	mkdir -p $(BUILD_DIR)
	$(ARANYM_JIT)
	$(SSH) cd /e/root/coreutils $(AND) make $(AND) make install-strip DESTDIR=/f
	touch $@

###############################################################################

id_rsa.pub:
	# mainly because of Windows vs. WSL $HOME inconsistency
	cp $(HOME)/.ssh/id_rsa.pub .

$(HOST_DRIVE)/.done: $(HOST_DRIVE)/.bash.done oldstuff/.done $(HOST_DRIVE)/.openssh.done \
		binutils/.done gcc/.done $(HOST_DRIVE)/.mintbin.done $(HOST_DRIVE)/.mintlib.done $(HOST_DRIVE)/.fdlibm.done \
		$(HOST_DRIVE)/.coreutils.done $(HOST_DRIVE)/.sed.done $(HOST_DRIVE)/.gawk.done $(HOST_DRIVE)/.grep.done $(HOST_DRIVE)/.diffutils.done \
		$(HOST_DRIVE)/.bison.done $(HOST_DRIVE)/.m4.done $(HOST_DRIVE)/.perl.done $(HOST_DRIVE)/.hostname.done $(HOST_DRIVE)/.make.done \
		$(HOST_DRIVE)/.texinfo.done \
		$(SOURCES_DIR)/bash/.done $(SOURCES_DIR)/bison/.done $(SOURCES_DIR)/coreutils/.done $(SOURCES_DIR)/diffutils/.done $(SOURCES_DIR)/gawk/.done \
		$(SOURCES_DIR)/grep/.done $(SOURCES_DIR)/libarchive/.done $(SOURCES_DIR)/m4/.done $(SOURCES_DIR)/make/.done $(SOURCES_DIR)/mintbin/.done \
		$(SOURCES_DIR)/openssh/.done $(SOURCES_DIR)/openssl/.done $(SOURCES_DIR)/opkg/.done $(SOURCES_DIR)/sed/.done $(SOURCES_DIR)/zlib/.done
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
	cp -ra $(SOURCES_DIR)/libarchive $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/mintbin $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/openssh $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/openssl $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/opkg $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/sed $(HOST_DRIVE)/root
	cp -ra $(SOURCES_DIR)/zlib $(HOST_DRIVE)/root

	# no clue what is this about but it doesn't work
	rm -f $(HOST_DRIVE)/bin/awk
	ln -s gawk $(HOST_DRIVE)/bin/awk
	rm -f $(HOST_DRIVE)/usr/bin/awk
	rm -f $(HOST_DRIVE)/usr/bin/gawk

	# SpareMiNT's makeinfo is too old (replacing it with a newer is far more hassle...)
	sed -i -e 's/^@copying/@ignore/;' $(HOST_DRIVE)/root/bash/doc/bashref.texi
	sed -i -e 's/^@end copying/@end ignore/;' $(HOST_DRIVE)/root/bash/doc/bashref.texi
	sed -i -e 's/^@copying/@ignore/;' $(HOST_DRIVE)/root/bash-minimal/doc/bashref.texi
	sed -i -e 's/^@end copying/@end ignore/;' $(HOST_DRIVE)/root/bash-minimal/doc/bashref.texi
	# SpareMiNT's sh is not really happy about this line
	sed -i -e 's/$${SHELL} $${INFOPOST} < $$(srcdir)\/bashref.info > $$@ ; \\/$${SHELL} $${INFOPOST} < $$(srcdir)\/bashref.info > $$@/;' $(HOST_DRIVE)/root/bash/doc/Makefile.in
	sed -i -e 's/$${SHELL} $${INFOPOST} < $$(srcdir)\/bashref.info > $$@ ; \\/$${SHELL} $${INFOPOST} < $$(srcdir)\/bashref.info > $$@/;' $(HOST_DRIVE)/root/bash-minimal/doc/Makefile.in
	# it's a hostfs drive...
	sed -i -e 's/^#StrictModes yes/StrictModes no/;' $(HOST_DRIVE)/etc/ssh/sshd_config

	touch $@

$(TARGET_IMAGE):
	dd if=/dev/zero of=$@ bs=1M count=$(TARGET_IMAGE_SIZE)
	mkfs.ext2 $@

$(FINAL_IMAGE):
	dd if=/dev/zero of=$@ bs=1M count=$(FINAL_IMAGE_SIZE)
	mkfs.ext2 $@

###############################################################################

emutos/.done: $(DOWNLOADS_DIR)/emutos.zip
	unzip -q $<
	mv emutos-aranym-* "emutos"
	touch $@

$(BOOT_DRIVE)/.done: $(DOWNLOADS_DIR)/freemint.zip $(CONFIG_DIR)/mint.cnf $(TOOLS_DIR)/eth0-config.sh $(TOOLS_DIR)/nfeth-config $(TOOLS_DIR)/public_key.sh
	unzip -q $< -d $(BOOT_DRIVE)
	cp $(CONFIG_DIR)/mint.cnf $(BOOT_DRIVE)/mint/1-19-cur
	mkdir -p $(BOOT_DRIVE)/mint/bin
	cp $(TOOLS_DIR)/eth0-config.sh $(BOOT_DRIVE)/mint/bin
	cp $(TOOLS_DIR)/nfeth-config $(BOOT_DRIVE)/mint/bin
	cp $(TOOLS_DIR)/public_key.sh $(BOOT_DRIVE)/mint/bin
	touch $@

###############################################################################

$(HOST_DRIVE)/.bash.done: $(DOWNLOADS_DIR)/bash.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

oldstuff/.done: $(DOWNLOADS_DIR)/oldstuff.rpm
	mkdir -p $(HOST_DRIVE)
	mkdir "oldstuff" && cd "oldstuff" && $(RPM_EXTRACT) $<
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
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && tar xjf $<
	touch $@

$(HOST_DRIVE)/.mintlib.done: mintlib-src/.done
	cd "mintlib-src" && \
	make SHELL=/bin/bash CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no && \
	make SHELL=/bin/bash CROSS=yes CC='m68k-atari-mint-gcc -m68020-60' WITH_020_LIB=no WITH_V4E_LIB=no prefix="$(HOST_DRIVE)/usr" install
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

$(HOST_DRIVE)/.coreutils.done: $(DOWNLOADS_DIR)/coreutils.tar.bz2
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && tar xjf $<
	touch $@

$(HOST_DRIVE)/.sed.done: $(DOWNLOADS_DIR)/sed.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

$(HOST_DRIVE)/.gawk.done: $(DOWNLOADS_DIR)/gawk.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

$(HOST_DRIVE)/.grep.done: $(DOWNLOADS_DIR)/grep.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

$(HOST_DRIVE)/.diffutils.done: $(DOWNLOADS_DIR)/diffutils.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

$(HOST_DRIVE)/.bison.done: $(DOWNLOADS_DIR)/bison.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

$(HOST_DRIVE)/.m4.done: $(DOWNLOADS_DIR)/m4.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

$(HOST_DRIVE)/.perl.done: $(DOWNLOADS_DIR)/perl.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

$(HOST_DRIVE)/.hostname.done: $(DOWNLOADS_DIR)/hostname.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

$(HOST_DRIVE)/.make.done: $(DOWNLOADS_DIR)/make.tar.bz2
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && tar xjf $<
	touch $@

$(HOST_DRIVE)/.texinfo.done: $(DOWNLOADS_DIR)/texinfo.rpm
	mkdir -p $(HOST_DRIVE)
	cd $(HOST_DRIVE) && $(RPM_EXTRACT) $<
	touch $@

###############################################################################

$(SOURCES_DIR)/bash/.done: $(SOURCES_DIR)/bash.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv bash-* "bash"
	cd $(SOURCES_DIR)/bash && cat $(PATCHES_DIR)/bash-4.2.53.patch | patch -p1
	touch $@

$(SOURCES_DIR)/bison/.done: $(SOURCES_DIR)/bison.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv bison-* "bison"
	touch $@

$(SOURCES_DIR)/coreutils/.done: $(SOURCES_DIR)/coreutils.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv coreutils-* "coreutils"
	cd $(SOURCES_DIR)/coreutils && cat $(PATCHES_DIR)/coreutils/* | patch -p1
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

$(SOURCES_DIR)/libarchive/.done: $(SOURCES_DIR)/libarchive.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv libarchive-* "libarchive"
	touch $@

$(SOURCES_DIR)/make/.done: $(SOURCES_DIR)/make.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv make-* "make"
	touch $@

$(SOURCES_DIR)/mintbin/.done: $(SOURCES_DIR)/mintbin.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv mintbin-master "mintbin"
	touch $@

$(SOURCES_DIR)/mintlib/.done: $(SOURCES_DIR)/mintlib.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv mintlib-master "mintlib"
	touch $@

$(SOURCES_DIR)/openssh/.done: $(SOURCES_DIR)/openssh.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv openssh-* "openssh"
	cd $(SOURCES_DIR)/openssh && cat $(PATCHES_DIR)/openssh.patch | patch -p1
	touch $@

$(SOURCES_DIR)/openssl/.done: $(SOURCES_DIR)/openssl.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv openssl-* "openssl"
	cd $(SOURCES_DIR)/openssl && cat $(PATCHES_DIR)/openssl.patch | patch -p1
	touch $@

$(SOURCES_DIR)/opkg/.done: $(SOURCES_DIR)/opkg.tar.gz
	cd $(SOURCES_DIR) && tar xzf $< && mv opkg-* "opkg"
	touch $@

$(SOURCES_DIR)/sed/.done: $(SOURCES_DIR)/sed.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv sed-* "sed"
	touch $@

$(SOURCES_DIR)/zlib/.done: $(SOURCES_DIR)/zlib.tar.xz
	cd $(SOURCES_DIR) && tar xJf $< && mv zlib-* "zlib"
	touch $@

###############################################################################

$(DOWNLOADS_DIR)/emutos.zip:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://downloads.sourceforge.net/project/emutos/emutos/1.0.1/emutos-aranym-1.0.1.zip"

$(DOWNLOADS_DIR)/freemint.zip:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://dl.bintray.com/freemint/freemint/snapshots-cpu/1-19-066b29f6/freemint-1-19-cur-040.zip"

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
	$(WGET) $@ "https://github.com/freemint/m68k-atari-mint-gcc/releases/download/gcc-7_5_0-mint-20191230/gcc-7.5.0-m68020-60mint.tar.bz2"

$(DOWNLOADS_DIR)/mintbin.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://dl.bintray.com/freemint/freemint/mintbin/0.3-d38d6ffe/mintbin-0.3-d38.tar.bz2"

$(DOWNLOADS_DIR)/mintlib-src.tar.gz:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://github.com/freemint/mintlib/archive/master.tar.gz"

$(DOWNLOADS_DIR)/fdlibm-src.tar.gz:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://github.com/freemint/fdlibm/archive/master.tar.gz"

$(DOWNLOADS_DIR)/coreutils.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/coreutils/coreutils-8.21-mint-20131205-bin-mint020-20131219.tar.bz2"

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

$(DOWNLOADS_DIR)/perl.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/perl-5.6.0-3.m68kmint.rpm"

$(DOWNLOADS_DIR)/hostname.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/hostname-2.07-1.m68kmint.rpm"

$(DOWNLOADS_DIR)/make.tar.bz2:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/mint/make/make-4.0-bin-mint020-20131109.tar.bz2"

$(DOWNLOADS_DIR)/texinfo.rpm:
	mkdir -p $(DOWNLOADS_DIR)
	$(WGET) $@ "https://freemint.github.io/sparemint/sparemint/RPMS/m68kmint/texinfo-4.0-2.m68kmint.rpm"

###############################################################################

$(SOURCES_DIR)/bash.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/bash/bash-4.2.53.tar.gz"

$(SOURCES_DIR)/bison.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/bison/bison-3.5.4.tar.xz"

$(SOURCES_DIR)/coreutils.tar.xz:
	mkdir -p $(SOURCES_DIR)
	# 8.32 requires an updated patch
	$(WGET) $@ "https://ftp.gnu.org/gnu/coreutils/coreutils-8.31.tar.xz"

$(SOURCES_DIR)/diffutils.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz"

$(SOURCES_DIR)/fdlibm.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://github.com/freemint/fdlibm/archive/master.tar.gz"

$(SOURCES_DIR)/gawk.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/gawk/gawk-5.1.0.tar.xz"

$(SOURCES_DIR)/grep.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/grep/grep-3.4.tar.xz"

$(SOURCES_DIR)/libarchive.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://www.libarchive.org/downloads/libarchive-3.4.2.tar.gz"

$(SOURCES_DIR)/m4.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz"

$(SOURCES_DIR)/make.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/make/make-4.3.tar.gz"

$(SOURCES_DIR)/mintbin.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://github.com/freemint/mintbin/archive/master.tar.gz"

$(SOURCES_DIR)/mintlib.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://github.com/freemint/mintlib/archive/master.tar.gz"

$(SOURCES_DIR)/openssh.tar.gz:
	mkdir -p $(SOURCES_DIR)
	# 8.2p1 requires an updated patch (SA_RESTART undefined)
	$(WGET) $@ "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.1p1.tar.gz"

$(SOURCES_DIR)/openssl.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://www.openssl.org/source/openssl-1.0.2u.tar.gz"

$(SOURCES_DIR)/opkg.tar.gz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://github.com/m68k-atari-mint/opkg/releases/download/0.4.0-mint/opkg-0.4.0.tar.gz"

$(SOURCES_DIR)/sed.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz"

$(SOURCES_DIR)/zlib.tar.xz:
	mkdir -p $(SOURCES_DIR)
	$(WGET) $@ "https://zlib.net/zlib-1.2.11.tar.xz"

###############################################################################

.PHONY: driveclean
driveclean:
	rm -f $(TARGET_IMAGE) $(FINAL_IMAGE)
	rm -rf $(BOOT_DRIVE) $(HOST_DRIVE)
	rm -rf $(BUILD_DIR)

.PHONY: clean
clean: driveclean
	rm -f *~
	rm -f aranym.config id_rsa.pub
	rm -rf emutos oldstuff binutils gcc
	rm -rf mintlib-src fdlibm-src
	rm -rf $(SOURCES_DIR)/{bash,bison,coreutils,diffutils,fdlibm,gawk,grep,libarchive,m4,make,mintbin,mintlib,openssh,openssl,opkg,sed,zlib}

.PHONY: distclean
distclean: clean
	rm -rf $(DOWNLOADS_DIR) $(SOURCES_DIR)
