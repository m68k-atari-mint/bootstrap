Bootstrap plan:
- we need to create three drives:
	1. Cross compiled binaries (hostfs drive with essential tools for running ./configure scripts)
	2. Natively compiled binaries (ext2fs image for packages which need to be ./configure'd and/or install'ed natively)
	3. Final image with only bash, openssh and opkg
- install to the boot drive:
	- emutos
	- freemint
- install to the host drive:
	- bash (SpareMiNT)
	- binutils (FreeMiNT release)
	- bison (SpareMiNT)
	- coreutils (fileutils, sh-utils, textutils from SpareMiNT)
	- diffutils (SpareMiNT)
	- fdlibm (cross-compiled FreeMiNT snapshot)
	- gawk (SpareMiNT)
	- gcc (FreeMiNT release)
	- grep (SpareMiNT)
	- hostname (SpareMiNT)
	- m4 (SpareMiNT)
	- mintbin (FreeMiNT snapshot)
	- mintlib (cross-compiled FreeMiNT snapshot)
	- oldstuff (most importantly, `shutdown` from SpareMiNT)
	- openssh (Vincent Riviere's build)
	- perl (SpareMiNT)
	- sed (SpareMiNT)
- ssh to the host drive, ./configure and/or build on the native image, install to the final image
	- bash
	- zlib
	- openssl
	- openssh
	- libarchive
	- opkg
- ssh to the host drive, ./configure and/or build on the native image, create essential packages:
	- bison (needs new m4 installed)
	- coreutils
	- diffutils
	- fdlibm
	- gawk
	- grep
	- inetutils
	- m4
	- make
	- mintbin
	- mintlib
	- sed
- (later...):
	- binutils
	- gcc
	- oldstuff
	- perl
