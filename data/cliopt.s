	align 4, db 0
ExecutionModeFunctions:
	dd DumpMappedMode
	dd DumpSectorsMode
	dd ListContentsMode
	dd ListContentsZeroMode
	dd ListBlocksMode
	dd ListEffectiveBlocksMode
	dd PartitionsMode
	dd SFDiskMode
	dd JSONMode
	dd GPTChecksumMode
	dd RestoreMode
	dd CopyMode
	dd 0 ; ...
	dd 0 ; ...
	dd 0 ; ...
	dd ShowPartitionTypesMode
	dd VersionMode
	dd HelpMode
	assert ($ - ExecutionModeFunctions) / 4 == EXECUTION_MODE_OPTIONS
	dd DefaultDumpMode

OptionTables:
	align 4, db 0
.long:
	dd ProgramInformation.map
	dd ProgramInformation.dump_sectors
	dd ProgramInformation.list_contents
	dd ProgramInformation.list_contents_0
	dd ProgramInformation.list_blocks
	dd ProgramInformation.list_effective_blocks
	dd ProgramInformation.partitions
	dd ProgramInformation.sfdisk
	dd ProgramInformation.json
	dd ProgramInformation.check_gpt_checksums
	dd ProgramInformation.restore
	dd ProgramInformation.copy
	dd ProgramInformation.merge
	dd ProgramInformation.extract
	dd ProgramInformation.extract_rename
	dd ProgramInformation.show_partition_types
	dd ProgramInformation.version
	dd ProgramInformation.help
	assert ($ - .long) / 4 == EXECUTION_MODE_OPTIONS
	dd ProgramInformation.data_file
	dd ProgramInformation.file_block_size
	dd ProgramInformation.max_header_size
	assert ($ - .long) / 4 == TOTAL_OPTION_FLAGS
.short:
	db "mDn0lLpkjCrcexRTvhdbs"
	assert ($ - .short) == TOTAL_OPTION_FLAGS
.lengths:
	db ProgramInformation.map_end - ProgramInformation.map
	db ProgramInformation.dump_sectors_end - ProgramInformation.dump_sectors
	db ProgramInformation.list_contents_end - ProgramInformation.list_contents
	db ProgramInformation.list_contents_0_end - ProgramInformation.list_contents_0
	db ProgramInformation.list_blocks_end - ProgramInformation.list_blocks
	db ProgramInformation.list_effective_blocks_end - ProgramInformation.list_effective_blocks
	db ProgramInformation.partitions_end - ProgramInformation.partitions
	db ProgramInformation.sfdisk_end - ProgramInformation.sfdisk
	db ProgramInformation.json_end - ProgramInformation.json
	db ProgramInformation.check_gpt_checksums_end - ProgramInformation.check_gpt_checksums
	db ProgramInformation.restore_end - ProgramInformation.restore
	db ProgramInformation.copy_end - ProgramInformation.copy
	db ProgramInformation.merge_end - ProgramInformation.merge
	db ProgramInformation.extract_end - ProgramInformation.extract
	db ProgramInformation.extract_rename_end - ProgramInformation.extract_rename
	db ProgramInformation.show_partition_types_end - ProgramInformation.show_partition_types
	db ProgramInformation.version_end - ProgramInformation.version
	db ProgramInformation.help_end - ProgramInformation.help
	assert ($ - .lengths) == EXECUTION_MODE_OPTIONS
	db ProgramInformation.data_file_end - ProgramInformation.data_file
	db ProgramInformation.file_block_size_end - ProgramInformation.file_block_size
	db ProgramInformation.max_header_size_end - ProgramInformation.max_header_size
	assert ($ - .lengths) == TOTAL_OPTION_FLAGS
