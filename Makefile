.PHONY: all debug clean
.SUFFIXES:

BUILD_DATE ?= $(shell date +%F -d @$$(git log -n 1 --format='format:%ct' 2>/dev/null || date +%s))
export BUILD_DATE

all: ptdump.s ldscript.txt $(wildcard src/*)
	nasm -felf64 $< -o ptdump.o
	ld -s -T ldscript.txt ptdump.o -o ptdump

debug: ptdump.s ldscript.txt $(wildcard src/*)
	nasm -g -felf64 $< -o ptdump.o
	ld -T ldscript.txt ptdump.o -o ptdump

clean:
	rm -f ptdump.o ptdump
