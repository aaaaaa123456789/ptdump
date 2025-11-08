CopyMode:
	endbr64
	call RejectSizeArguments
	mov esi, [zInputCount]
	test esi, esi
	jz NoInputsExit
	mov r13d, esi
	shr esi, 1
	mov [zInputCount], esi
	mov ebp, Messages.inputs_not_paired_error
	mov ebx, Messages.inputs_not_paired_error_end - Messages.inputs_not_paired_error
	jc BadInvocationExit
	assert outputdev_size == 32
	shl rsi, 5
	call Allocate
	mov rsi, [zInputFilenames]
	xor ecx, ecx
	mov [zGenericDataBuffer], rax
.load_filenames_loop:
	mov rdx, [rsi + 8 * rcx]
	mov [rax + outputdev.search_filename], rdx
	mov rdx, [rsi + 8 * rcx + 8]
	mov [rax + outputdev.filename], rdx
	mov [rsi + 4 * rcx], rdx
	add ecx, 2
	cmp ecx, r13d
	jc .load_filenames_loop
	call CheckDuplicateInputFilename
	call OpenValidateDataFile
	call LoadFilenameTable
	mov r12, [zGenericDataBuffer]
	xor ecx, ecx
	mov r10, r12
.search_filenames_loop:
	mov [zCurrentInputIndex], ecx
	mov rsi, [r10 + outputdev.search_filename]
	call FindFilenameInTable
	mov [r10 + outputdev.index], eax
	mov ecx, [zCurrentInputIndex]
	inc ecx
	cmp ecx, [zInputCount]
	jc .search_filenames_loop
	lea esi, [r14 + 0xff]
	mov r14d, ecx
	assert outputdev_size == 32
	shl rcx, 5
	lea r15, [r12 + rcx]
	jmp RestoreMode.finish_filenames

RestoreMode:
	endbr64
	call RejectSizeArguments
	cmp dword[zInputCount], 0
	jnz .specific_files
	call OpenValidateDataFile
	mov esi, r14d
	mov ecx, esi
	mov r15d, r14d
	assert outputdev_size == 32
	shl r15, 5
	add rsi, r15
	lea rdx, [rbp + 4 * rbx + 4]
.total_filename_length_loop:
	movzx eax, word[rdx]
	add rsi, rax
	add rdx, 12
	dec ecx
	jnz .total_filename_length_loop
	call Allocate
	mov r12, rax
	lea r10, [rbp + 4 * rbx]
	lea rdi, [rax + r15]
	xor edx, edx
.copy_file_info_loop:
	mov [rax + outputdev.index], edx
	mov [rax + outputdev.filename], rdi
	mov esi, [r10]
	movzx ecx, word[r10 + 4]
	lea rsi, [rbp + 4 * rsi]
	rep movsb
	mov byte[rdi], 0
	inc rdi
	add r10, 12
	add rax, outputdev_size
	inc edx
	cmp edx, r14d
	jc .copy_file_info_loop
	lea r15, [rdi + 7]
	and r15, -8
	jmp Restore

.specific_files:
	call CheckDuplicateInputFilename
	call OpenValidateDataFile
	call LoadFilenameTable
	mov esi, [zInputCount]
	assert outputdev_size == 32
	shl rsi, 5
	mov r15, rsi
	call Allocate
	mov r12, rax
	mov r10, rax
	add r15, rax
	xor ecx, ecx
.specific_files_loop:
	mov [zCurrentInputIndex], ecx
	mov rsi, [zInputFilenames]
	mov rsi, [rsi + 8 * rcx]
	mov [r10 + outputdev.filename], rsi
	call FindFilenameInTable
	mov [r10 + outputdev.index], eax
	mov ecx, [zCurrentInputIndex]
	inc ecx
	cmp ecx, [zInputCount]
	jc .specific_files_loop
	lea esi, [r14 + 0xff]
	mov r14d, ecx
.finish_filenames:
	shl rsi, 4
	and rsi, -0x1000
	mov rdi, r13
	mov eax, munmap
	syscall
	; fallthrough

Restore:
	; in: rbp, rbx: data file, r12: output device array (index and filename populated), r14d: output device array length, r15: common buffer or null
	xor eax, eax
	mov [zInputDevices], r12
	test r15w, 0xff8
	cmovz r15, rax
	mov r13d, r14d
.validation_loop:
	mov rdi, [r12 + outputdev.filename]
	mov esi, O_WRONLY | O_DSYNC
	mov eax, open
	syscall
	cmp rax, -EINTR
	jz .validation_loop
	cmp rax, -0x1000
	jnc .open_failed
	mov [r12 + outputdev.file_descriptor], eax
	mov edi, eax
	mov esi, zStatBuffer
	mov eax, fstat
	syscall
	cmp rax, -0x1000
	jnc .stat_failed
	mov rax, [zStatBuffer + st_size]
	assert (S_IFMT & ~0xff00) == 0
	mov cl, [zStatBuffer + st_mode + 1]
	and cl, S_IFMT >> 8
	mov [r12 + outputdev.type], cl
	cmp cl, S_IFREG >> 8
	jz .opened
	cmp cl, S_IFBLK >> 8
	jnz .bad_type
	mov edi, [r12 + outputdev.file_descriptor]
	mov esi, BLKSSZGET
	mov edx, zGenericDataBuffer
	mov eax, ioctl
	syscall
	cmp rax, -0x1000
	jc .block_size_failed
	mov eax, [zGenericDataBuffer]
	mov [r12 + outputdev.block_size], eax
	mov edi, [r12 + outputdev.file_descriptor]
	mov esi, BLKGETSIZE64
	mov edx, zGenericDataBuffer
	mov eax, ioctl
	syscall
	cmp rax, -0x1000
	jc .device_size_failed
	mov rax, [zGenericDataBuffer]
.opened:
	mov [r12 + outputdev.size], rax
	mov edi, [r12 + outputdev.index]
	lea eax, [rdi + 2 * rdi]
	add eax, ebx
	movzx eax, word[rbp + 4 * rax + 6]
	dec ax
	inc eax
	shl eax, 2
	cmp byte[r12 + outputdev.type], S_IFBLK >> 8
	jnz .skip_block_size_check
	cmp eax, [r12 + outputdev.block_size]
	jnz .block_size_mismatch
.skip_block_size_check:
	mov [r12 + outputdev.block_size], eax
	call LoadEffectiveBlockList
	mov rcx, [r12 + outputdev.size]
	mov [r12 + outputdev.block_table], rsi
	mov [r12 + outputdev.block_table_count], edi
	shl rdi, 4
	mov eax, [rsi + rdi - 8]
	add rax, [rsi + rdi - 16]
	mov edx, [r12 + outputdev.block_size]
	mul rdx
	test edx, edx
	jnz .too_small
	cmp rcx, rax
	jc .too_small
	add r12, outputdev_size
	dec r13d
	jnz .validation_loop

	mov [zRemainingInputCount], r14d
	mov [zInputCount], r14d
	mov r12, [zInputDevices]
.output_loop:
	mov r15, [r12 + outputdev.block_table]
	mov r13d, [r12 + outputdev.block_table_count]
	mov byte[r12 + outputdev.errors], 1
.output_block_loop:
	mov eax, [r15 + 12]
	lea r14, [rbp + 4 * rax]
	mov edx, [r12 + outputdev.block_size]
	mov r10, [r15]
	imul r10, rdx
	mov ebx, [r15 + 8]
	imul rbx, rdx
.try_write:
	push r10
	mov edi, [r12 + outputdev.file_descriptor]
	mov rsi, r14
	mov rdx, rbx
	mov eax, pwrite64
	syscall
	pop r10
	cmp rax, -EINTR
	jz .try_write
	cmp rax, -0x1000
	jnc .output_next
	test rax, rax
	jz .output_next
	add r10, rax
	add r14, rax
	sub rbx, rax
	ja .try_write
	add r15, 16
	dec r13d
	jnz .output_block_loop
	mov byte[r12 + outputdev.errors], 0
	cmp byte[r12 + outputdev.type], S_IFBLK >> 8
	jnz .output_next
	mov edi, [r12 + outputdev.file_descriptor]
	mov esi, BLKRRPART
	mov eax, ioctl
	syscall
.output_next:
	mov edi, [r12 + outputdev.file_descriptor]
	mov eax, close
	syscall
	add r12, outputdev_size
	dec dword[zRemainingInputCount]
	jnz .output_loop

	xor r13d, r13d
	mov r12, [zInputDevices]
	mov r14d, [zInputCount]
.check_error_loop:
	cmp byte[r12 + outputdev.errors], 0
	jz .check_error_next
	test r13d, r13d
	jnz .already_printed_error_banner
	mov ebp, Messages.restore_write_error
	mov ebx, Messages.restore_write_error_end - Messages.restore_write_error
	call WriteError
	inc r13d
.already_printed_error_banner:
	mov rbp, [r12 + outputdev.filename]
	call StringLength
	mov byte[rbp + rbx], `\n`
	inc rbx
	call WriteData ; [zCurrentFD] is already set to 2 by the WriteError call
.check_error_next:
	add r12, outputdev_size
	dec r14d
	jnz .check_error_loop
	mov edi, r13d
	jmp ExitProgram

.open_failed:
	mov ebp, Messages.open_error
	mov ebx, Messages.open_error_end - Messages.open_error
	mov r15, [r12 + outputdev.filename]
	jmp FilenameErrorExit
.stat_failed:
	mov ebp, Messages.stat_error
	mov ebx, Messages.stat_error_end - Messages.stat_error
	mov r15, [r12 + outputdev.filename]
	jmp FilenameErrorExit
.bad_type:
	mov ebp, Messages.bad_input_type_error
	mov ebx, Messages.bad_input_type_error_end - Messages.bad_input_type_error
	mov r15, [r12 + outputdev.filename]
	jmp FilenameErrorExit
.block_size_failed:
	mov ebp, Messages.get_block_size_error
	mov ebx, Messages.get_block_size_error_end - Messages.get_block_size_error
	mov r15, [r12 + outputdev.filename]
	jmp FilenameErrorExit
.device_size_failed:
	mov ebp, Messages.get_device_size_error
	mov ebx, Messages.get_device_size_error_end - Messages.get_device_size_error
	mov r15, [r12 + outputdev.filename]
	jmp FilenameErrorExit
.block_size_mismatch:
	mov ebp, Messages.block_size_mismatch
	mov ebx, Messages.block_size_mismatch_end - Messages.block_size_mismatch
	mov r15, [r12 + outputdev.filename]
	jmp FilenameErrorExit
.too_small:
	mov ebp, Messages.small_device_error
	mov ebx, Messages.small_device_error_end - Messages.small_device_error
	mov r15, [r12 + outputdev.filename]
	jmp FilenameErrorExit
