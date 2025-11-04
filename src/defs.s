struc inputdev
	.filename:                        resb 8
	.size:                            resb 8 ; in blocks!
	.block_size:                      resb 4
	.header_size:                     resb 4
	.header_contents:                 resb 8
	.header_copy_location:            resb 8 ; actual block number for the copied blocks
	.partition_table_location_1:      resb 8
	.partition_table_location_2:      resb 8
	.partition_table_copy_location:   resb 8
	.partition_table_data_1:          resb 8 ; copy from here if data is copied
	.partition_table_data_2:          resb 8
	.partition_table_size_1:          resb 2
	.partition_table_size_2:          resb 2
	.partition_table_copy_size:       resb 2
	.header_copy_sector_offset:       resb 2
	.header_copy_sector_count:        resb 2
	.filename_length:                 resb 2
	.block_list_offset:               resb 4
	.output_offsets:
	.header_output_offset:            resb 4
	.partition_table_output_offset_1: resb 4
	.partition_table_output_offset_2: resb 4
	.extra_sector_output_offset:      resb 4
	.filename_output_offset:          resb 4
	.extra_sector_count:              resb 4
	.extra_sector_table:              resb 8 ; table of (number, pointer); (0, pointer) continues, (0, 0) ends
endstruc

struc inputsect
	.input_filename:    resb 8
	.output_filename:   resb 8
	.range_list:        resb 8 ; table of (start, length, output offset)
	.block_list_offset:
	.range_count:       resb 4
	.total_sectors:     resb 4
	.block_size:        resb 4
	.file_descriptor:   resb 4
	.filename_offset:   resb 4
	.filename_length:   resb 2
	                    resb 2 ; padding
endstruc

struc partitiondata
	.type:                   resb  1 ; 0 = none; 0xff = invalid; others: see derived structs
	                         resb  3 ; padding
	.block_table_entries:    resb  4
	.block_table:            resb  8
endstruc

struc partitiondataMBR
	; derives from partitiondata
	.type:                   resb  1 ; = 1
	.partition_count_small:  resb  1 ; 0-4 = partition count; >4: has extended partitions (bits 4-7: extended flags)
	                         resb  2 ; padding
	.block_table_entries:    resb  4
	.block_table:            resb  8
	.partition_table:        resb  8
	; the following fields only exist if .partition_count_small > 4
	.partition_count:        resb  4
	.extended_count:         resb  4
	.extended_tables:        resb  8
	assert .type == partitiondata.type
	assert .block_table_entries == partitiondata.block_table_entries
	assert .block_table == partitiondata.block_table
endstruc

struc partitiondataGPT
	; derives from partitiondata
	.type:                   resb  1 ; = 2
	.table_header_count:     resb  1
	.selected_table_header:  resb  1
	.table_header_flags:     resb  1 ; 2 bits per table (0 = nonmatching, 1 = matching, 2 = selected, 3 = invalid)
	.block_table_entries:    resb  4
	.block_table:            resb  8
	.partition_table:        resb  8
	.partition_count:        resb  4
	.table_header_locations: resb 12 ; 3 values, 4 bytes each
	.table_header_blocks:    resb 24 ; 3 values, 8 bytes each
	assert .type == partitiondata.type
	assert .block_table_entries == partitiondata.block_table_entries
	assert .block_table == partitiondata.block_table
endstruc

struc extendedtable
	.block:            resb 4
	.parent:           resb 4
	.block_high:       resb 1
	.parent_high:      resb 1
	.parent_entry:     resb 1 ; 0-3
	.next:             resb 1 ; 0-3; 0xff = none
	.location:         resb 4
endstruc

struc partitionMBR
	.number:         resb 4
	.length:         resb 4
	.start:          resb 4
	.table:          resb 4
	.start_high:     resb 1
	.table_high:     resb 1
	.entry_flags:    resb 1 ; bits 0-1: entry (0-3); bit 7: bootable flag
	.type:           resb 1
	.table_location: resb 4
endstruc

struc partitionGPT
	.number:   resb 4
	.location: resb 4 ; location of the entry that describes the partition
endstruc

%assign EXECUTION_MODE_OPTIONS               16
%assign HEADER_SIZE_DEFAULT            0x100000 ;   1 MB
%assign HEADER_SIZE_LIMIT             0x1000000 ;  16 MB
%assign JSON_OUTPUT_BUFFER_SIZE         0x50000 ; 320 KB - must be at least 0x3fffd bytes to handle evil filenames
%assign MAXIMUM_BLOCK_SIZE              0x40000 ; 256 KB - cannot be higher without changing the file format
%assign MAXIMUM_BUFFERED_OUTPUT          0x4000 ;  16 KB
%assign MAXIMUM_PARTITION_TYPE_LENGTH        60 ; this value is assumed, not checked!
%assign MULTIPLE_LABEL_CODE                0xf0 ; the actual threshold for a multilabel is this value + 2
%assign PARTITION_TYPE_LIST_MAX_SIZE     0x7000 ; this value is assumed, not checked!
%assign TOTAL_OPTION_FLAGS                   19

; Linux x64 syscall IDs (in: (rdi, rsi, rdx, r10, r8, r9); out: rax)
%assign read         0 ; (fd, buf, count)
%assign write        1 ; (fd, buf, count)
%assign open         2 ; (pathname, flags, mode)
%assign close        3 ; (fd)
%assign fstat        5 ; (fd, statbuf)
%assign mmap         9 ; (addr, length, prot, flags, fd, offset)
%assign munmap      11 ; (addr, length)
%assign ioctl       16 ; (fd, op, argp)
%assign pread64     17 ; (fd, buf, count, offset)
%assign mremap      25 ; (old_address, old_size, new_size, flags, new_address)
%assign dup2        33 ; (oldfd, newfd)
%assign getpid      39 ; ()
%assign kill        62 ; (pid, sig)
%assign fcntl       72 ; (fd, op, arg)
%assign fsync       74 ; (fd)
%assign creat       85 ; (pathname, mode)
%assign exit_group 231 ; (status)

; errors and signals
%assign EINTR    4
%assign EBADF    9
%assign EAGAIN  11
%assign ENODEV  19
%assign EINVAL  22
%assign SIGABRT  6

; kernel API constants and flags
; ignore O_LARGEFILE because it's a no-op on 64-bit systems
%assign F_GETFL             3
%assign MAP_PRIVATE         2
%assign MAP_ANONYMOUS    0x20
%assign MREMAP_MAYMOVE      1
%assign O_ACCMODE           3
%assign O_RDONLY            0
%assign O_WRONLY            1
%assign PROT_READ           1
%assign PROT_WRITE          2
%assign S_IFBLK        0x6000
%assign S_IFCHR        0x2000
%assign S_IFIFO        0x1000
%assign S_IFMT         0xf000
%assign S_IFREG        0x8000
%assign S_IFSOCK       0xc000

; ioctl command values
%assign BLKGETSIZE64 0x80081272
%assign BLKRRPART        0x125f
%assign BLKSSZGET        0x1268

; offsets into struct stat (no need for the whole struct)
%assign st_mode           24 ; dword
%assign st_rdev           40 ; qword
%assign st_size           48 ; qword
%assign struct_stat_size 144
