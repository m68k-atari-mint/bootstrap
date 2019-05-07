Bootstrap plan:
- we need to create three images:
	1. Cross compiled binaries (to compile sources natively)
	2. Natively compiled binaries (to compile sources for the final image)
	3. Final image with only bash, openssh and opkg
- install to the host drive:
	- emutos
	- freemint
- install to the cross image:
	- awk
	- bash
	- binutils
	- coreutils
	- diffutils
	- fdlibm (cross-compiled source)
	- gcc
	- grep
	- make
	- mintbin
	- mintlib (cross-compiled source)
	- oldstuff from SpareMiNT (most importantly, `shutdown`)
	- openssh
	- sed
- ssh to the cross image, build and install to the native image (also create an .ipk for each of them):
	- awk
	- bash
	- binutils (just copy over for now)
	- coreutils
	- diffutils
	- fdlibm
	- gcc (just copy over for now)
	- grep
	- make
	- mintbin
	- mintlib
	- oldstuff from SpareMiNT (most importantly, `shutdown`)
	- sed
- (later...):
	- zlib
	- openssl
	- openssh
	- libarchive
	- opkg
	- (auto tools but this shouldn't be needed when ./configure is available)
	- (binutils)
	- (gcc)
