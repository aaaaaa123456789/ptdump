# ptdump — Partition table dumper

This program will dump the partition table of a disk (or disk image file), along with the contents of the first few
sectors for non-GPT partition tables (which often contain boot code, etc.).
The contents of said partition tables are dumped in a compact custom binary format, documented [here](datafile.md).

Requires a reasonably recent version of NASM to build (2.16 should work), as well as LD or a compatible linker.
Use `make` to build the binary.
Once built, `ptdump -h` will show usage instructions.
(`make debug` and `make clean` will also behave as expected.)

The version number will be set to the date of the last commit at the time of building.
To set it to some other date, set the `BUILD_DATE` environment variable to any ISO 8601 date.
(For example, pass `BUILD_DATE=1970-01-01` as an argument to `make`.)

### Documentation files

- [`datafile.md`](datafile.md): document describing the data file format.
- [`schema.json`](schema.json): [JSON Schema][jsonschema] file documenting the schema for the program's JSON output in
  the `-j`/`--json` execution mode.

[jsonschema]: https://json-schema.org/draft/2020-12/json-schema-core
