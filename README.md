[![Build Status](https://travis-ci.org/m68k-atari-mint/bootstrap.svg?branch=master)](https://travis-ci.org/m68k-atari-mint/bootstrap)

Bootstrap plan:
- we need to create three drives:
	1. Cross compiled binaries (hostfs drive with essential tools for running ./configure scripts)
	2. Natively compiled binaries (ext2fs image for packages compiled natively and possibly installed to the final image)
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
- ssh to the host drive, ./configure and build on the native image, install to the final image (+create packages)
	- bash
	- oldstuff (copy over for now)
	- zlib (install only locally)
	- openssl (install only locally)
	- openssh
	- libarchive (install only locally)
	- opkg
- apart from that, create essential packages:
	- bison (needs new m4 installed)
	- coreutils
	- diffutils
	- gawk
	- grep
	- inetutils
	- m4
	- make
	- mintbin
	- sed
- (later...):
	- binutils (just package it for now)
	- fdlibm (can be 100% cross compiled & packaged)
	- gcc (just package it for now)
	- mintlib (can be 100% cross compiled & packaged)
	- perl (depends on the situation with dynamic modules)
