DumpMappedMode:
	endbr64
	mov esi, [zInputCount]
	test esi, esi
	jz NoInputsExit
	test esi, 1
	mov ebp, Messages.inputs_not_paired_error
	mov ebx, Messages.inputs_not_paired_error_end - Messages.inputs_not_paired_error
	jnz BadInvocationExit
	mov r12, rsi
	assert inputdev_size == 128
	shl r12, 6
	lea rsi, [r12 + 4 * rsi]
	call Allocate
	assert zInputFilenames == zInputDevices
	mov rsi, [zInputFilenames]
	mov [zInputDevices], rax
	add r12, rax
	mov [zRealFilenames], r12
	xor edx, edx
	mov ebp, [zSizeSpecCount]
	neg rbp

	xor ecx, ecx
	xor edi, edi
.next_size_spec:
	dec rdx
	mov ebx, [rsi + 8 * rdx]
.initial_setup_loop:
	cmp rdx, rbp
	jz .skip_size_spec_check
	cmp ecx, [rsi + 8 * rdx - 4]
	jnc .next_size_spec
.skip_size_spec_check:
	mov r10, [rsi + 8 * rdi]
	mov [r12 + 8 * rcx], r10
	mov rdi, [rsi + 8 * rdi + 8]
	mov [rax + inputdev.filename], rdi
	mov [rax + inputdev.header_size], ebx
	add rax, inputdev_size
	inc ecx
	lea edi, [ecx + ecx]
	cmp edi, [zInputCount]
	jc .initial_setup_loop
	shr dword[zInputCount], 1
	jmp DumpPartitionTables

DefaultDumpMode:
	endbr64
	mov esi, [zInputCount]
	test esi, esi
	jz NoInputsExit
	assert inputdev_size == 128
	shl rsi, 7
	call Allocate
	assert zInputFilenames == zInputDevices
	mov rsi, [zInputFilenames]
	mov [zInputDevices], rax
	xor edx, edx
	mov ebp, [zSizeSpecCount]
	neg rbp
	mov [zRealFilenames], edx

	xor ecx, ecx
.next_size_spec:
	dec rdx
	mov ebx, [rsi + 8 * rdx]
.initial_setup_loop:
	cmp rdx, rbp
	jz .skip_size_spec_check
	cmp ecx, [rsi + 8 * rdx - 4]
	jnc .next_size_spec
.skip_size_spec_check:
	mov rdi, [rsi + 8 * rcx]
	mov [rax + inputdev.filename], rdi
	mov [rax + inputdev.header_size], ebx
	add rax, inputdev_size
	inc ecx
	cmp ecx, [zInputCount]
	jc .initial_setup_loop
	; fallthrough

DumpPartitionTables:
	; in: rax: pointer to the end of zInputDevices
	; process inputs backwards, for simplicity
	mov r12, rax
	cmp dword[zDefaultFileBlockSize], 0
	jnz .process_input_loop
	mov dword[zDefaultFileBlockSize], 512
.process_input_loop:
	dec ecx
	mov [zCurrentInputIndex], ecx
	sub r12, inputdev_size
	mov rsi, [zRealFilenames]
	test rsi, rsi
	mov r15, [r12 + inputdev.filename]
	jz .open
	mov r15, [rsi + 8 * rcx]
.open:
	mov rdi, r15
	assert O_RDONLY == 0
	xor esi, esi
	mov eax, open
	syscall
	cmp rax, -EINTR
	jz .open
	cmp rax, -0x1000
	mov ebp, Messages.open_error
	mov ebx, Messages.open_error_end - Messages.open_error
	jnc FilenameErrorExit
	mov [zCurrentFD], eax
	mov edi, eax
	mov esi, zStatBuffer
	mov eax, fstat
	syscall
	cmp rax, -0x1000
	mov ebp, Messages.stat_error
	mov ebx, Messages.stat_error_end - Messages.stat_error
	jnc FilenameErrorExit
	mov eax, [zStatBuffer + st_mode]
	and eax, S_IFMT
	cmp eax, S_IFREG
	jz .regular_file_input
	cmp eax, S_IFBLK
	mov ebp, Messages.bad_input_type_error
	mov ebx, Messages.bad_input_type_error_end - Messages.bad_input_type_error
	jnz FilenameErrorExit

	mov edi, [zCurrentFD]
	mov esi, BLKSSZGET
	mov edx, zGenericDataBuffer
	mov eax, ioctl
	syscall
	cmp rax, -0x1000
	mov ebp, Messages.get_block_size_error
	mov ebx, Messages.get_block_size_error_end - Messages.get_block_size_error
	jnc FilenameErrorExit
	mov eax, [zGenericDataBuffer]
	cmp eax, MAXIMUM_BLOCK_SIZE
	mov ebp, Messages.bad_block_size
	mov ebx, Messages.bad_block_size_end - Messages.bad_block_size
	ja FilenameErrorExit
	cmp eax, 512
	jc FilenameErrorExit
	test al, 7
	jnz FilenameErrorExit
	mov [r12 + inputdev.block_size], eax
	mov edi, [zCurrentFD]
	mov esi, BLKGETSIZE64
	mov edx, zGenericDataBuffer
	mov eax, ioctl
	syscall
	cmp rax, -0x1000
	mov ebp, Messages.get_device_size_error
	mov ebx, Messages.get_device_size_error_end - Messages.get_device_size_error
	jnc FilenameErrorExit
	mov rax, [zGenericDataBuffer]
	mov edi, [r12 + inputdev.block_size]
	jmp .got_input_size

.regular_file_input:
	; zStatBuffer still contains the result of fstat
	mov rax, [zStatBuffer + st_size]
	mov edi, [zDefaultFileBlockSize]
	mov [r12 + inputdev.block_size], edi
.got_input_size:
	xor edx, edx
	div rdi
	test edx, edx
	mov ebp, Messages.bad_device_size
	mov ebx, Messages.bad_device_size_end - Messages.bad_device_size
	jnz FilenameErrorExit
	cmp rax, 2
	jc FilenameErrorExit
	mov [r12 + inputdev.size], rax

	mov edx, [r12 + inputdev.header_size]
	lea r14d, [edi + edi]
	cmp r14d, edx
	cmovc r14d, edx
	cmp r14, rax
	cmovnc r14, rax
	mov eax, r14d
	xor edx, edx
	mov edi, [r12 + inputdev.block_size]
	div edi
	test edx, edx
	jz .header_size_exact
	sub r14d, edx
	add r14d, edi
	inc eax
.header_size_exact:
	mov r13d, eax
	mov esi, r14d
	call AllocateCurrentBuffer
	mov ebx, r14d
	mov rbp, [zCurrentBuffer]
	call ReadData
	mov rdi, [zCurrentBuffer]
	mov esi, [r12 + inputdev.block_size]
	call GetPartitionTableType
	cmp al, 1
	mov ebp, Messages.unknown_partition_table
	mov ebx, Messages.unknown_partition_table_end - Messages.unknown_partition_table
	jc FilenameErrorExit
	mov [zPartitionTableType], al
	ja .calculate_GPT_header_size
	; for MBR: find the lowest valid starting sector for a partition (0 if nothing is found)
	mov eax, -1
	%assign index 0
	%rep 4
		cmp dword[rdi + 0x1ca + index * 0x10], 0
		jz .skip_check_partition_%[index]
		cmp byte[rdi + 0x1c2 + index * 0x10], 0
		jz .skip_check_partition_%[index]
		mov edx, [rdi + 0x1c6 + index * 0x10]
		dec edx
		cmp edx, eax
		cmovc eax, edx
.skip_check_partition_%[index]:
		%assign index index + 1
	%endrep
	inc eax
	jmp .got_calculated_header_size

.calculate_GPT_header_size:
	; for GPT: min(table LBA + ceil(entries * entry size / block size), first usable LBA)
	mov eax, [rdi + rsi + 80]
	mov edx, [rdi + rsi + 84]
	imul rax, rdx
	xor edx, edx
	div rsi
	test edx, edx
	lea rdx, [rax + 1]
	cmovz rdx, rax
	add rdx, [rsi + rdi + 72]
	mov rax, [rsi + rdi + 40]
	cmp rax, rdx
	cmovnc rax, rdx

.got_calculated_header_size:
	; treat calculated header sizes that exceed the header size limit as zero
	; true header size is min(ceil(requested header / block size), calculated); if zero, default to ceil(default / block size)
	; r13 = min(ceil(requested header / block size), 2); use this as a stand-in for the requested header size if nonzero
	mov rcx, rax
	imul rax, rsi
	cmp rax, HEADER_SIZE_LIMIT + 1
	sbb eax, eax
	cmovz ecx, eax
	cmp dword[r12 + inputdev.header_size], 0
	jz .skip_requested_header_size_check
	cmp r13d, ecx
	cmovc ecx, r13d
.skip_requested_header_size_check:
	cmp ecx, 2
	jnc .got_header_size
	xor edx, edx
	mov eax, HEADER_SIZE_DEFAULT
	div esi
	add edx, -1
	adc eax, 0
	mov ecx, eax

.got_header_size:
	mov [r12 + inputdev.header_size], ecx ; now in blocks!
	cmp ecx, r13d
	jz .got_header
	imul esi, ecx
	call ResizeCurrentBuffer
	mov ebx, [r12 + inputdev.header_size]
	sub ebx, r13d
	mov ebp, [r12 + inputdev.block_size]
	imul ebx, ebp
	imul ebp, r13d
	add rbp, [zCurrentBuffer]
	call ReadData
.got_header:
	mov r13, [zCurrentBuffer]
	mov [r12 + inputdev.header_contents], r13
	mov esi, 0x1000
	call AllocateAligned
	mov [r12 + inputdev.extra_sector_table], rax
	mov [zInputBlockListPointer], rax
	mov byte[zRemainingBufferBlocks], 0
	cmp byte[zPartitionTableType], 1
	ja .load_GPT_partition_tables
	%assign index 0
	%rep 4
		mov r14d, [r13 + 0x1c6 + index * 0x10]
		test r14d, r14d
		jz .skip_dump_partition_%[index]
		mov rax, [r12 + inputdev.size]
		cmp r14, rax
		jnc .skip_dump_partition_%[index]
		mov esi, [r13 + 0x1ca + index * 0x10]
		test esi, esi
		jz .skip_dump_partition_%[index]
		sub rax, r14
		cmp rsi, rax
		cmova esi, eax
		mov al, [r13 + 0x1c2 + index * 0x10]
		call IsExtendedPartitionCode
		jz .skip_dump_partition_%[index]
		call DumpExtendedPartition
.skip_dump_partition_%[index]:
		%assign index index + 1
	%endrep
	jmp .loaded_tables

.load_GPT_partition_tables:
	mov rdi, [r12 + inputdev.size]
	dec rdi
	mov r14, rdi
	call AppendBlock
	mov edx, [r12 + inputdev.block_size]
	mov rdi, [r13 + rdx + 32]
	cmp rdi, r14
	jz .no_extra_alternate_GPT_table
	call AppendBlock
.no_extra_alternate_GPT_table:
	mov ecx, [r12 + inputdev.block_size]
	mov eax, [rsi + 80]
	mov edx, [rsi + 84]
	imul rax, rdx
	xor edx, edx
	div rcx
	add rdx, -1
	xor r14d, r14d
	adc r14, rax
	mov eax, [r13 + rcx + 80]
	mov edx, [r13 + rcx + 84]
	imul rax, rdx
	xor edx, edx
	div rcx
	add rdx, -1
	xor ebx, ebx
	adc rbx, rax
	mov rbp, [r13 + rcx + 72]
	mov r13, [rsi + 72]
	mov r11, [r12 + inputdev.size]
	mov r8, rbp
	neg r8
	add r8, r11
	sbb rax, rax
	and r8, rax
	mov r9, r13
	neg r9
	add r9, r11
	sbb rax, rax
	and r9, rax
	xor edx, edx
	cmp rbx, r8
	cmova rbx, rdx
	cmp r14, r9
	cmova r14, rdx
	mov eax, HEADER_SIZE_LIMIT
	div ecx
	add edx, -1
	adc eax, 0
	xor edx, edx
	cmp rbx, rax
	cmova ebx, edx
	cmp r14, rax
	cmova r14d, edx
	ja .got_primary_GPT_table
	test ebx, ebx
	jz .exchange_GPT_tables
	cmp rbp, r13
	jbe .got_primary_GPT_table
.exchange_GPT_tables:
	xchg rbp, r13
	xchg ebx, r14d
.got_primary_GPT_table:
	test ebx, ebx
	jz .loaded_tables
	cmp ebx, r14d
	setz [zPartitionTableSizesMatch]
	mov [r12 + inputdev.header_copy_sector_offset], bp
	mov [zHeaderPartitionTableSize], bx
	mov eax, [r12 + inputdev.header_size]
	lea rdx, [rbp + rbx]
	cmp rax, rdx
	jnc .loaded_primary_GPT_table
	sub rax, rbp
	jbe .load_primary_GPT_table
	add ebp, eax
	sub ebx, eax
.load_primary_GPT_table:
	sub [zHeaderPartitionTableSize], bx
	mov [r12 + inputdev.partition_table_location_1], rbp
	mov [r12 + inputdev.partition_table_size_1], bx
	mov esi, [r12 + inputdev.block_size]
	imul ebx, esi
	imul rbp, rsi
	mov esi, ebx
	call Allocate
	mov [r12 + inputdev.partition_table_data_1], rax
	mov r10, rbp
	mov rbp, rax
	call ReadDataAtOffset
.loaded_primary_GPT_table:
	test r14d, r14d
	jz .loaded_tables
	mov esi, [r12 + inputdev.block_size]
	imul esi, r14d
	mov ebx, esi
	call AllocateCurrentBuffer
	mov rbp, rax
	mov r10d, [r12 + inputdev.block_size]
	imul r10, r13
	call ReadDataAtOffset
	mov rsi, [zCurrentBuffer]
	movzx edi, word[r12 + inputdev.header_copy_sector_offset]
	mov ebx, [r12 + inputdev.block_size]
	imul edi, ebx
	shr ebx, 3
	add rdi, [r12 + inputdev.header_contents]
	mov rbp, rsi
	movzx ecx, word[zHeaderPartitionTableSize]
	cmp ecx, r14d
	cmova ecx, r14d
	xor r11d, r11d
	test ecx, ecx
	jz .skip_header_partition_copy
	imul ecx, ebx
	mov eax, ecx
	repz cmpsq
	lea edx, [ecx + 1]
	cmovnz ecx, edx
	sub eax, ecx
	xor edx, edx
	div ebx
	mov r11d, eax
	mov [r12 + inputdev.header_copy_sector_count], ax
	mov [r12 + inputdev.header_copy_location], r13
	add r13, rax
	cmp ax, [zHeaderPartitionTableSize]
	jnz .got_header_copy_length
.skip_header_partition_copy:
	movzx eax, word[r12 + inputdev.partition_table_size_1]
	mov rdi, [r12 + inputdev.partition_table_data_1]
	mov ecx, r14d
	sub ecx, r11d
	cmp eax, ecx
	cmovc ecx, eax
	test ecx, ecx
	jz .got_header_copy_length
	imul ecx, ebx
	mov eax, ecx
	repz cmpsq
	lea edx, [ecx + 1]
	cmovnz ecx, edx
	sub eax, ecx
	xor edx, edx
	div ebx
	add r11d, eax
	mov [r12 + inputdev.partition_table_copy_size], ax
	mov [r12 + inputdev.partition_table_copy_location], r13
	add r13, rax	
.got_header_copy_length:
	sub r14d, r11d
	jbe .release_secondary_GPT_table
	mov [r12 + inputdev.partition_table_size_2], r14w
	mov [r12 + inputdev.partition_table_location_2], r13
	imul r11d, [r12 + inputdev.block_size]
	add r11, [zCurrentBuffer]
	mov [r12 + inputdev.partition_table_data_2], r11
	jmp .loaded_tables

.release_secondary_GPT_table:
	mov rdi, [zCurrentBuffer]
	mov esi, [zCurrentBufferSize]
	mov eax, munmap
	syscall
.loaded_tables:
	mov edi, [zCurrentFD]
	mov eax, close
	syscall
	cmp rax, -EINTR
	jz .loaded_tables
	mov ecx, [zCurrentInputIndex]
	test ecx, ecx
	jnz .process_input_loop

	mov esi, [zInputCount]
	shl rsi, 4
	lea rsi, [rsi + 4 * rsi]
	call AllocateCurrentBuffer
	xor ecx, ecx
.prepare_sorting_outputs_loop:
	mov edx, [r12 + inputdev.block_size]
	mov edi, [r12 + inputdev.header_size]
	imul edi, edx
	bsf ebx, edi
	not rdi
	not bl
	mov [rax], rdi
	mov [rax + 7], bl
	; [rax + 8] = 0 is given by zero initialization
	mov [rax + 12], ecx
	add rax, 16
	movzx edi, word[r12 + inputdev.partition_table_size_1]
	test edi, edi
	jz .skip_sorting_table_1
	imul edi, edx
	bsf ebx, edi
	not rdi
	not bl
	mov [rax], rdi
	mov [rax + 7], bl
	mov byte[rax + 8], 1
	mov [rax + 12], ecx
	add rax, 16
.skip_sorting_table_1:
	movzx edi, word[r12 + inputdev.partition_table_size_2]
	test edi, edi
	jz .skip_sorting_table_2
	imul edi, edx
	bsf ebx, edi
	not rdi
	not bl
	mov [rax], rdi
	mov [rax + 7], bl
	mov byte[rax + 8], 2
	mov [rax + 12], ecx
	add rax, 16
.skip_sorting_table_2:
	mov edi, [r12 + inputdev.extra_sector_count]
	test edi, edi
	jz .skip_sorting_extra_sectors
	imul rdi, rdx
	bsf rbx, rdi
	not rdi
	not bl
	mov [rax], rdi
	mov [rax + 7], bl
	mov byte[rax + 8], 3
	mov [rax + 12], ecx
	add rax, 16
.skip_sorting_extra_sectors:
	mov rbp, [r12 + inputdev.filename]
	call StringLength
	mov edx, 0xffff
	cmp rbx, rdx
	cmova ebx, edx
	mov [r12 + inputdev.filename_length], bx
	add ebx, 3
	and ebx, -4
	bsf edx, ebx
	not rbx
	not dl
	mov [rax], rbx
	mov [rax + 7], dl
	mov byte[rax + 8], 4
	mov [rax + 12], ecx
	add rax, 16
	add r12, inputdev_size
	inc ecx
	cmp ecx, [zInputCount]
	jc .prepare_sorting_outputs_loop
	mov rbp, [zCurrentBuffer]
	sub rax, rbp
	shr rax, 4
	mov rbx, rax
	call SortPairs

	mov r12, [zInputDevices]
	mov r15, 0xff00000000000000
	mov rsi, rbp
	stc
	sbb ebp, ebp ; rbp = 0xffffffff
	xor ecx, ecx
.output_offset_calculation_loop:
	lodsq
	or rax, r15
	not rax
	shr rax, 2
	mov rdx, rax
	lodsq
	mov edi, eax
	assert inputdev_size == 128
	shr rax, 25
	add rax, r12
	mov [rax + 4 * rdi + inputdev.output_offsets], ecx
	add rcx, rdx
	cmp rcx, rbp
	jnc OutputTooLargeErrorExit
	dec rbx
	jnz .output_offset_calculation_loop
	mov [zCurrentOutputOffset], ecx
	mov rdi, [zCurrentBuffer]
	mov esi, [zCurrentBufferSize]
	mov eax, munmap
	syscall
	mov r14d, [zInputCount]
	xor r13d, r13d
.prepare_extra_block_tables_loop:
	mov ebx, [r12 + inputdev.extra_sector_count]
	add r13d, ebx
	jc OutputTooLargeErrorExit
	test ebx, ebx
	jz .next_extra_block_table
	mov rbp, [r12 + inputdev.extra_sector_table]
	cmp qword[rbp + 0xff8], 0
	jz .sort_extra_block_table
	mov esi, ebx
	shl rsi, 4
	call Allocate
	mov rdi, rax
	mov [r12 + inputdev.extra_sector_table], rax
.copy_extra_block_table_loop:
	mov rsi, rbp
	mov ecx, 0x1fe
	rep movsq
	mov r15, rdi
	mov rdi, rbp
	mov rbp, [rbp + 0xff8]
	mov esi, 0x1000
	mov eax, munmap
	syscall
	mov rdi, r15
	cmp qword[rbp + 0xff8], 0
	jz .copy_extra_block_table_loop
	sub r15, [r12 + inputdev.extra_sector_table]
	shr r15, 3
	mov ecx, [r12 + inputdev.extra_sector_count]
	shl ecx, 1
	sub ecx, r15d
	mov rsi, rbp
	rep movsq
	mov rdi, rbp
	mov esi, 0x1000
	mov eax, munmap
	syscall
	mov rbp, [r12 + inputdev.extra_sector_table]
.sort_extra_block_table:
	mov ebx, [r12 + inputdev.extra_sector_count]
	call SortPairs
.next_extra_block_table:
	add r12, inputdev_size
	dec r14d
	jnz .prepare_extra_block_tables_loop

	mov esi, [zInputCount]
	mov r15d, [zCurrentOutputOffset]
	lea rsi, [r13 + 8 * rsi]
	lea rsi, [rsi + 2 * rsi + 1]
	add rsi, r15
	shl rsi, 2
	call Allocate
	mov r12, [zInputDevices]
	mov r10d, [zInputCount]
.output_loop:
	mov [r12 + inputdev.block_list_offset], r15d
	mov ebx, [r12 + inputdev.block_size]
	shr ebx, 3
	mov rsi, [r12 + inputdev.header_contents]
	mov ecx, [r12 + inputdev.header_size]
	mov edi, [r12 + inputdev.header_output_offset]
	mov ebp, ecx
	shl ebp, 8
	imul ecx, ebx
	mov [rax + 4 * r15], ebp
	mov [rax + 4 * r15 + 4], edi
	; qword[rax + 4 * r15 + 8] is already zero by zero initialization
	add r15d, 4
	jc OutputTooLargeErrorExit
	lea rdi, [rax + 4 * rdi]
	rep movsq
	movzx ecx, word[r12 + inputdev.partition_table_size_1]
	test ecx, ecx
	jz .no_output_partition_table_1
	mov edi, [r12 + inputdev.partition_table_output_offset_1]
	mov rsi, [r12 + inputdev.partition_table_data_1]
	mov ebp, ecx
	shl ebp, 8
	imul ecx, ebx
	mov [rax + 4 * r15], ebp
	mov [rax + 4 * r15 + 4], edi
	mov rbp, [r12 + inputdev.partition_table_location_1]
	mov [rax + 4 * r15 + 8], rbp
	add r15d, 4
	jc OutputTooLargeErrorExit
	lea rdi, [rax + 4 * rdi]
	rep movsq
.no_output_partition_table_1:
	movzx ecx, word[r12 + inputdev.header_copy_sector_count]
	shl ecx, 8
	jz .no_header_copy_output
	movzx esi, word[r12 + inputdev.header_copy_sector_offset]
	imul esi, ebx
	shl esi, 1
	add esi, [r12 + inputdev.header_output_offset]
	mov rbp, [r12 + inputdev.header_copy_location]
	mov [rax + 4 * r15], ecx
	mov [rax + 4 * r15 + 4], esi
	mov [rax + 4 * r15 + 8], rbp
	add r15d, 4
	jc OutputTooLargeErrorExit
.no_header_copy_output:
	movzx ecx, word[r12 + inputdev.partition_table_copy_size]
	shl ecx, 8
	jz .no_partition_table_copy_output
	mov esi, [r12 + inputdev.partition_table_output_offset_1]
	mov rbp, [r12 + inputdev.partition_table_copy_location]
	mov [rax + 4 * r15], ecx
	mov [rax + 4 * r15 + 4], esi
	mov [rax + 4 * r15 + 8], rbp
	add r15d, 4
	jc OutputTooLargeErrorExit
.no_partition_table_copy_output:
	movzx ecx, word[r12 + inputdev.partition_table_size_2]
	test ecx, ecx
	jz .no_output_partition_table_2
	mov edi, [r12 + inputdev.partition_table_output_offset_2]
	mov rsi, [r12 + inputdev.partition_table_data_2]
	mov ebp, ecx
	shl ebp, 8
	imul ecx, ebx
	mov [rax + 4 * r15], ebp
	mov [rax + 4 * r15 + 4], edi
	mov rbp, [r12 + inputdev.partition_table_location_2]
	mov [rax + 4 * r15 + 8], rbp
	add r15d, 4
	jc OutputTooLargeErrorExit
	lea rdi, [rax + 4 * rdi]
	rep movsq
.no_output_partition_table_2:
	mov edi, [r12 + inputdev.filename_output_offset]
	mov rsi, [r12 + inputdev.filename]
	movzx ecx, word[r12 + inputdev.filename_length]
	lea rdi, [rax + 4 * rdi]
	rep movsb
	mov r11d, [r12 + inputdev.extra_sector_count]
	test r11d, r11d
	jz .no_output_extra_sectors
	mov r14, [r12 + inputdev.extra_sector_table]
	mov edi, [r12 + inputdev.extra_sector_output_offset]
	lea rdi, [rax + 4 * rdi]
.extra_sector_output_outer_loop:
	lea r8, [rax + 4 * r15]
	mov r9d, [r14 + 4]
	shl r9d, 8
	mov [r8], r9d
	shl r9, 24
	mov rcx, rdi
	sub rcx, rax
	shr rcx, 2
	mov [r8 + 4], rcx
	add r15d, 2
	jc OutputTooLargeErrorExit
.extra_sector_output_inner_loop:
	cmp byte[r8], 0xff
	jz .extra_sector_output_outer_loop
	mov rcx, [r14]
	mov rsi, rcx
	sub rcx, r9
	mov [rax + 4 * r15], ecx
	shr rcx, 32
	jnz .extra_sector_output_outer_loop
	inc byte[r8]
	mov r9, rsi
	inc r15d
	jz OutputTooLargeErrorExit
	mov rsi, [r14 + 8]
	mov ecx, ebx
	rep movsq
	add r14, 16
	dec r11d
	jnz .extra_sector_output_inner_loop
.no_output_extra_sectors:
	inc r15d ; dword[rax + 4 * r15] is already zero
	jz OutputTooLargeErrorExit
	add r12, inputdev_size
	dec r10d
	jnz .output_loop

	mov rbp, [zInputDevices]
	mov ecx, [zInputCount]
.file_table_loop:
	mov esi, [rbp + inputdev.filename_output_offset]
	mov dx, [rbp + inputdev.filename_length]
	mov ebx, [rbp + inputdev.block_size]
	shr ebx, 2
	mov edi, [rbp + inputdev.block_list_offset]
	mov [rax + 4 * r15], esi
	mov [rax + 4 * r15 + 4], dx
	mov [rax + 4 * r15 + 6], bx
	mov [rax + 4 * r15 + 8], edi
	add r15d, 3
	jc OutputTooLargeErrorExit
	add rbp, inputdev_size
	dec ecx
	jnz .file_table_loop
	mov ecx, [zInputCount]
	mov [rax + 4 * r15], ecx
	lea rbx, [4 * r15 + 4]
	mov rbp, rax

WriteOutputExit:
	; in: rbp = pointer to output, rbx = size, zDataFilename = output filename, or null for stdout
	mov r15, [zDataFilename]
	test r15, r15
	jz .standard_output
.try_open:
	mov rdi, r15
	mov esi, 0o666
	mov eax, creat
	syscall
	cmp rax, -EINTR
	jz .try_open
	mov [zCurrentFD], eax
	cmp rax, -0x1000
	jc .opened
	mov ebp, Messages.open_error
	mov ebx, Messages.open_error_end - Messages.open_error
	jmp FilenameErrorExit

.standard_output:
	mov edi, 1
	mov [zCurrentFD], edi
	mov esi, F_GETFL
	mov eax, fcntl
	syscall
	cmp rax, -EBADF
	jz .standard_output_not_open
	cmp rax, -0x1000
	jnc .output_error
	and al, O_ACCMODE
	assert O_RDONLY == 0
	jnz .opened
.standard_output_not_open:
	mov ebp, Messages.no_standard_output
	mov ebx, Messages.no_standard_output_end - Messages.no_standard_output
	jmp ErrorExit

.opened:
	call WriteData
	test rax, rax
	jnz .output_error
.sync:
	mov edi, [zCurrentFD]
	mov eax, fsync
	syscall
	xor edi, edi
	cmp rax, -EINTR
	jz .sync
	cmp rax, -EINVAL
	jz ExitProgram
	cmp rax, -0x1000
	jc ExitProgram
.output_error:
	mov ebp, Messages.output_error
	mov ebx, Messages.output_error_end - Messages.output_error
	jmp ErrorExit

AppendBlock:
	; in: r12: inputdev, rdi: block number; out: rsi: block
	push rdi
	mov ax, 0xf000
	or ax, [zInputBlockListPointer]
	cmp ax, 0xfff0
	jc .no_new_list
	mov esi, 0x1000
	call AllocateAligned
	mov rdi, [zInputBlockListPointer]
	mov [rdi + 8], rax
	mov [zInputBlockListPointer], rax
.no_new_list:
	cmp byte[zRemainingBufferBlocks], 0
	jnz .no_new_allocation
	mov esi, [r12 + inputdev.block_size]
	shl esi, 5
	call Allocate
	mov [zInputBlockBuffer], rax
	mov byte[zRemainingBufferBlocks], 32
.no_new_allocation:
	mov rbp, [zInputBlockBuffer]
	mov ebx, [r12 + inputdev.block_size]
	add [zInputBlockBuffer], rbx
	dec byte[zRemainingBufferBlocks]
	mov rdi, [zInputBlockListPointer]
	mov [rdi + 8], rbp
	pop r10
	mov [rdi], r10
	imul r10, rbx
	call ReadDataAtOffset
	mov rsi, [zInputBlockListPointer]
	add rsi, 16
	mov [zInputBlockListPointer], rsi
	mov rsi, [rsi - 8]
	inc dword[r12 + inputdev.extra_sector_count]
	jz OutputTooLargeErrorExit
	ret

DumpExtendedPartition:
	; in: r14: partition start block, esi: partition size, r12: pointer to inputdev struct
	push r13
	mov r13d, esi
	xor edi, edi
.loop:
	cmp edi, r13d
	jnc .done
	add rdi, r14
	call AppendBlock
	; Linux refuses to recurse into a tree, only following the first link it finds -- do the same
	; (see parse_extended in block/partitions/msdos.c in the kernel source)
	%assign index 0
	%rep 4
		mov edi, [rsi + 0x1c6 + index * 0x10]
		test edi, edi
		jz .skip%[index]
		mov al, [rsi + 0x1c2 + index * 0x10]
		call IsExtendedPartitionCode
		jnz .loop
.skip%[index]:
		%assign index index + 1
	%endrep
.done:
	pop r13
	ret
