Messages:
.allocation_error:                withend db `error: failed to allocate memory\n`
.argument_given_to_option_error:  withend db "error: argument given to option "
.bad_block_size:                  withend db "error: bad block size for "
.bad_device_size:                 withend db "error: invalid size obtained for "
.bad_input_type_error:            withend db "error: file is not a regular file or block device: "
.block_size_mismatch:             withend db "error: device block size does not match data file: "
.data_file_open_paren:            withend db "error: data file ("
.data_file_not_valid:             withend db "error: data file is not valid: "
.duplicate_filename_close_paren:  withend db ") contains a duplicate filename: "
.duplicate_input_filename:        withend db "error: duplicate input filename: "
.empty_argument_error:            withend db `error: invalid empty argument\n`
.filename_not_found_error:        withend db "error: filename not found in data file: "
.filename_too_long_error:         withend db "error: filename too long: "
.get_block_size_error:            withend db "error: failed to get block size for "
.get_device_size_error:           withend db "error: failed to get size for "
.inputs_not_paired_error:         withend db `error: input filenames must be specified in pairs for this mode\n`
.inputs_not_valid_error:          withend db `error: input filenames must not be specified for this mode\n`
.invalid_block_size_error:        withend db "error: invalid block size: "
.invalid_sector_list:             withend db "error: sector list invalid or too large: "
.invalid_size_error:              withend db "error: invalid size: "
.multiple_data_files_error:       withend db `error: multiple data files specified\n`
.multiple_execution_modes_error:  withend db `error: multiple execution modes specified\n`
.multiple_file_block_sizes_error: withend db `error: multiple file block sizes specified\n`
.no_inputs_1:                     withend db "No inputs given. Use "
.no_inputs_2:                     withend db ` -h for help.\n`
.no_standard_input:               withend db `error: standard input is not open for reading\n`
.no_standard_output:              withend db `error: standard output is not open for writing\n`
.open_error:                      withend db "error: failed to open file: "
.output_error:                    withend db `error: failed to write output\n`
.output_too_large_error:          withend db `error: output file too large\n`
.range_beyond_the_end_error:      withend db "error: sector range extends beyond the end of "
.read_error:                      withend db `error: failed to read from input\n`
.read_error_file:                 withend db "error: failed to read from "
.restore_write_error:             withend db `error: failed to write data to the following files or devices:\n`
.sizes_not_valid_error:           withend db `error: size options must not be specified for this mode\n`
.small_device_error:              withend db "error: output file or device too small: "
.stat_error:                      withend db "error: failed to stat file: "
.unexpected_EOF:                  withend db `error: unexpected end of input\n`
.unexpected_EOF_file:             withend db "error: unexpected end of file: "
.unknown_option_error:            withend db "error: unknown option: "
.unknown_partition_table:         withend db "error: unknown partition table type for "

JSONText:
.attributes:          withend db '","attributes":'
.block_size:          withend db '","block_size":'
.blocks_bracket:      withend db ',"blocks":['
.entry_bootable:      db ',"entry":1' ; out of order because it continues in the next entry
.bootable:            withend db ',"bootable":'
.brace_block:         withend db '{"block":'
.brace_filename:      withend db '{"filename":'
.brace_header:        withend db '{"header":'
.brace_number:        withend db '{"number":'
.bracket_status:      withend db '],"status":'
.count:               withend db ',"count":'
.diskID_quote:        withend db ',"diskID":"'
.effective_blocks:    withend db ',"effective_blocks":['
.endCHS:              withend db '],"endCHS":['
.entries:             withend db ',"entries":'
.entry_one_brace:     withend db ',"entry":1},'
.entry_size:          withend db ',"entry_size":'
.extended_tables:     withend db ',"extended_partition_tables":['
.first_block:         withend db '","first_block":'
.last_block:          withend db ',"last_block":'
.length:              withend db ',"length":'
.offset:              withend db ',"offset":'
.parent:              withend db ',"parent":'
.partition_tables:    withend db ',"partition_tables":['
.partition_type:      withend db ',"partition_type":"'
.partitions_brackets: withend db '],"partitions":[]'
.quote_type:          withend db '","type":"'
.required:            withend db ',"required":'
.start:               withend db ',"start":'
.startCHS:            withend db ',"startCHS":['
.table:               withend db ',"table":'
.typeID_quote:        withend db ',"typeID":"'

MiscStrings:
.dev_null: db "/dev/null", 0
.stdin: withend db "<standard input>", 0
.size_suffixes: db "BkMGTPEZY" ; the last few are only there to catch invalid sizes in tables
.unknown_type: withend db "unknown type 0x"

TableHeaders: withend db `           block#    count  bsize      offset filename\n`
.one_file:    withend db `           block#    count  bsize      offset\n`

Headers:
.MBR_types: withend db `MBR partition types:\n`
.GPT_types: withend db `\nGPT partition types:\n`
.partition_list: withend db " partition table, block size: "

ProgramInformation:
	; version information first; will be printed on its own by -v/--version
	db "ptdump - partition table dumper - version "
	db %substr(BUILD_DATE, 1, 4), ".", %substr(BUILD_DATE, 6, 2), ".", %substr(BUILD_DATE, 9, 2), `\n`

.usage:
	db ` [options] [--] filename...\n\n`
	db `By default, it will dump the partition tables of all disk and disk images\n`
	db `specified by the filenames into the data file. Option flags may select a\n`
	db `different behavior. If not specified by the -d or --data-file option, the data\n`
	db `file is written to standard output or read from standard input.\n\n`
	db `Arguments to options given in short form may immediately follow the option\n`
	db `letter (-dout.bin) or be separate (-d out.bin). Arguments to options in long\n`
	db `form must be separate (--data-file out.bin).\n`
	db `Command-line arguments not associated with any option are interpreted as\n`
	db `filenames. (Filenames that begin with dashes can be escaped with ./; that\n`
	db `prefix will be stripped from the filename.)\n\n`
	db `Alternate execution modes:\n`
	db "-m, --"
.map: withend db "map"
	db `:\n`
	db `\tDumps partition tables, as in the default operation mode, but mapping\n`
	db `\tthe corresponding disk or disk images to the specified filenames.\n`
	db `\tFilename arguments for this option must be specified in pairs: for each\n`
	db `\tpair, the first argument indicates the name of the disk or disk image\n`
	db `\tto back up, and the second argument indicates the filename to store in\n`
	db `\tthe data file.\n`
	db "-D, --"
.dump_sectors: withend db "dump-sectors"
	db `:\n`
	db `\tDumps specific sectors from disks or disk images. Arguments for this\n`
	db `\toption must be specified in pairs: for each pair, the first argument\n`
	db `\tindicates the name of the disk or disk image to use as a source, and\n`
	db `\tthe second argument indicates the list of sectors or sector ranges to\n`
	db `\tback up. Multiple sectors are separated by commas (e.g., 40,50), and\n`
	db `\tranges are separated by a hyphen (e.g., 40-50) and inclusive on both\n`
	db `\tends. An alternate filename can be specified after the list after a\n`
	db `\tcolon (e.g., 40,50-60,70,80-90:filename.bin).\n`
	db "-n, --"
.list_contents: withend db "list-contents"
	db `:\n`
	db `\tList the contents of a data file (filenames only). Filename arguments\n`
	db `\tare not allowed for this mode.\n`
	db "-0, --"
.list_contents_0: withend db "list-contents-0"
	db `:\n`
	db `\tLike the previous mode, but filenames are separated by null bytes\n`
	db `\tinstead of newlines (as expected by xargs -0 and similar tools).\n`
	db "-l, --"
.list_blocks: withend db "list-blocks"
	db `:\n`
	db `\tList the contents of a data file (filenames and blocks for each file).\n`
	db `\tIf filename arguments are specified, only the selected disks'\n`
	db `\tinformation will be shown.\n`
	db "-L, --"
.list_effective_blocks: withend db "list-effective-blocks"
	db `:\n`
	db `\tLike the previous mode, but after deduplicating blocks and merging\n`
	db `\tconsecutive block ranges. This mode lists the effective blocks for\n`
	db `\teach file, i.e., the block data that the program will use for other\n`
	db `\tmodes. (Like for the previous mode, filename arguments will filter.)\n`
	db "-p, --"
.partitions: withend db "partitions"
	db `:\n`
	db `\tPrint a list of detected partitions for each disk in a data file. If\n`
	db `\tfilename arguments are specified, only the selected disks' partition\n`
	db `\ttables will be shown.\n`
	db "-k, --"
.sfdisk: withend db "sfdisk"
	db `:\n`
	db `\tGenerate output like that of sfdisk -d for each disk in a data file.\n`
	db `\tIf filename arguments are specified, only the selected disks'\n`
	db `\tpartition tables will be shown.\n`
	db "-j, --"
.json: withend db "json"
	db `:\n`
	db `\tGenerate a JSON document (minified, terminated by a newline) describing\n`
	db `\tthe contents of a data file. (A JSON Schema file for this document is\n`
	db `\tavailable in the project's repository.) Filename arguments are not\n`
	db `\tallowed for this mode.\n`
	db "-r, --"
.restore: withend db "restore"
	db `:\n`
	db `\tRestore the contents of a data file to the corresponding disks or disk\n`
	db `\timages. If filename arguments are specified, only the selected disks\n`
	db `\twill be restored. This mode of operation assumes that the disks or disk\n`
	db `\timages have the same names as in the data file; use the -c or --copy\n`
	db `\toption to manually specify the name of the outputs.\n`
	db "-c, --"
.copy: withend db "copy"
	db `:\n`
	db `\tCopy the contents of the partition tables for specific disk or disk\n`
	db `\timages stored in the data file to designated locations. (This mode can\n`
	db `\talso be used to restore a partition table when the destination has a\n`
	db `\tdifferent name from the one stored in the data file.) Filename\n`
	db `\targuments for this option must be specified in pairs: for each pair,\n`
	db `\tthe first argument indicates the filename stored in the data file, and\n`
	db `\tthe second argument indicates the destination filename.\n`
	db "-e, --"
.merge: withend db "merge"
	db `:\n`
	db `\tCompacts and merges multiple data files into a single one. (For this\n`
	db `\tmode, the filename arguments are the input data files.) Use "-" as a\n`
	db `\tfilename argument to read from standard input.\n`
	db "-x, --"
.extract: withend db "extract"
	db `:\n`
	db `\tExtracts the contents for one or more disks (or disk images) from a\n`
	db `\tdata file into a new one. The first filename argument for this mode is\n`
	db `\tthe data file to extract from (use "-" to read from standard input);\n`
	db `\tother filename arguments represent the filenames to extract.\n`
	db "-T, --"
.show_partition_types: withend db "show-partition-types"
	db `: list all known partition types and IDs.\n`
	db "-v, --"
.version: withend db "version"
	db `: show version information and exit.\n`
	db "-h, --"
.help: withend db "help"
	db `: show this help screen and exit.\n\n`
	db `Other options:\n`
	db "-d filename, --"
.data_file: withend db "data-file"
	db ` filename:\n`
	db `\tIndicates the location where the data file will be written to (or read\n`
	db `\tfrom, if appropriate). Default: standard output/input.\n`
	db "-b size, --"
.file_block_size: withend db "file-block-size"
	db ` size:\n`
	db `\tDetermines the block size to be used for regular files being treated as\n`
	db `\tdisk images. (Actual block devices always use their true block sizes.)\n`
	db `\tBlock sizes must be between 512 and 262,144 bytes, and they must be\n`
	db `\tmultiples of 8 bytes; the 'k' suffix may be used to indicate that the\n`
	db `\tvalue is in kiB (1k = 1,024 bytes). Default: 512 bytes.\n`
	db "-s size, --"
.max_header_size: withend db "max-header-size"
	db ` size:\n`
	db `\tSpecifies the maximum size of a disk's header to be dumped into the\n`
	db `\tdata file. This option is position-sensitive: it will only apply to\n`
	db `\tfilename arguments that come after it. Values that are smaller than\n`
	db `\ttwice the device's block size will be ignored. The 'k' and 'M' suffixes\n`
	db `\tmay be used to indicate values in kiB or MiB (1M = 1,048,576 bytes.)\n`
.end:
