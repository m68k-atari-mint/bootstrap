EXT2_IMAGE = ext2.img
EXT2_IMAGE_SIZE = 128

TARGET = $(EXT2_IMAGE)

default: $(TARGET)

$(TARGET):
	dd if=/dev/zero of="$@" bs=1M count=${EXT2_IMAGE_SIZE}
	mkfs.ext2 "$@"

clean:
	rm -f ${EXT2_IMAGE}
	rm -f *~
