# ptdump — Partition table dumper

This program will dump the partition table of a disk (or disk image file), along with the contents of the first few
sectors for non-GPT partition tables (which often contain boot code, etc.).
The contents of said partition tables are dumped in a compact custom binary format, documented [here](datafile.md).

Requires a reasonably recent version of NASM to build (2.16 should work), as well as LD or a compatible linker.
Use `make` to build the binary.
Once built, `ptdump -h` will show usage instructions.
(`make debug` and `make clean` will also behave as expected.)
