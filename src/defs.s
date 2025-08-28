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

%assign EXECUTION_MODE_OPTIONS         11
%assign HEADER_SIZE_DEFAULT      0x100000 ;   1 MB
%assign HEADER_SIZE_LIMIT       0x1000000 ;  16 MB
%assign MAXIMUM_BLOCK_SIZE        0x40000 ; 256 KB - cannot be higher without changing the file format
%assign MAXIMUM_BUFFERED_OUTPUT    0x4000 ;  16 KB
%assign TOTAL_OPTION_FLAGS             14

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
