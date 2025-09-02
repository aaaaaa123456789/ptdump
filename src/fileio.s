MapInputFile:
	; in: r15: filename; out: rbp: mapping, rbx: file size; modifies zStatBuffer, r12, r13
	mov rdi, r15
	assert O_RDONLY == 0
	xor esi, esi
	mov eax, open
	syscall
	cmp rax, -EINTR
	jz MapInputFile
	cmp rax, -0x1000
.open_failed:
	mov ebp, Messages.open_error
	mov ebx, Messages.open_error_end - Messages.open_error
	jnc FilenameErrorExit
	mov ebp, eax
	mov edi, eax
	mov esi, zStatBuffer
	mov eax, fstat
	syscall
	cmp rax, -0x1000
	jnc .open_failed
	mov rbx, [zStatBuffer + st_size]
	test rbx, rbx
	jz ReadInputFile
	assert (S_IFMT & ~0xff00) == 0
	mov al, [zStatBuffer + st_mode + 1]
	and al, S_IFMT >> 8
	cmp al, S_IFIFO >> 8
	jz ReadInputFile
	cmp al, S_IFSOCK >> 8
	jz ReadInputFile
	xor edi, edi
	mov rsi, rbx
	mov edx, PROT_READ
	mov r10d, MAP_PRIVATE
	mov r8d, ebp
	xor r9d, r9d
	mov eax, mmap
	syscall
	cmp rax, -EAGAIN
	jz ReadInputFile
	cmp rax, -ENODEV
	jz ReadInputFile
	cmp rax, -0x1000
	jnc .open_failed
	mov edi, ebp
	mov rbp, rax
	mov eax, close
	syscall
	ret

ReadInputFile:
	; in: rbp: FD, rbx: known minimum size; out: rbp: buffer, rbx: true size; modifies r12, r13
	lea rsi, [rbx + 0x1fff]
	and rsi, -0x1000
	mov r13, rsi
	call AllocateAligned
	xor ebx, ebx
.remap_loop:
	mov r12, rax
.loop:
	mov rdx, r13
	sub rdx, rbx
	lea rsi, [r12 + rbx]
	mov edi, ebp
	assert read == 0
	xor eax, eax
	syscall
	cmp rax, -EINTR
	jz .loop
	cmp rax, -0x1000
	jnc ReadData.fail
	test eax, eax
	jz .done
	add rbx, rax
	lea rdx, [rbx + 0x1fff]
	and rdx, -0x1000
	cmp rdx, r13
	jbe .loop
	mov rsi, r13
	mov r13, rdx
	mov rdi, r12
	mov r10d, MREMAP_MAYMOVE
	mov eax, mremap
	syscall
	cmp rax, -0x1000
	jc .remap_loop
	jmp AllocationErrorExit

.done:
	mov edi, ebp
	mov rbp, r12
	mov eax, close
	syscall
	ret

ReadDataAtOffset:
	; in: r10: offset; other inputs as for ReadData
	push r10
	mov edi, [zCurrentFD]
	mov rsi, rbp
	mov rdx, rbx
	mov eax, pread64
	syscall
	pop r10
	cmp rax, -EINTR
	jz ReadDataAtOffset
	cmp rax, -0x1000
	jnc ReadData.fail
	test rax, rax
	jz ReadData.badEOF
	add rbp, rax
	add r10, rax
	sub rbx, rax
	ja ReadDataAtOffset
	ret

ReadData:
	; in: rbp: address, rbx: size, r15: filename or null (for errors)
	mov edi, [zCurrentFD]
	mov rsi, rbp
	mov rdx, rbx
	assert read == 0
	xor eax, eax
	syscall
	cmp rax, -EINTR
	jz ReadData
	cmp rax, -0x1000
	jnc .fail
	test rax, rax
	jz .badEOF
	add rbp, rax
	sub rbx, rax
	ja ReadData
	ret

.fail:
	test r15, r15
	mov eax, Messages.read_error
	mov ebp, Messages.read_error_file
	cmovz ebp, eax
	mov eax, Messages.read_error_end - Messages.read_error
	mov ebx, Messages.read_error_file_end - Messages.read_error_file
	cmovz ebx, eax
	jmp FilenameErrorExit

.badEOF:
	test r15, r15
	mov eax, Messages.unexpected_EOF
	mov ebp, Messages.unexpected_EOF_file
	cmovz ebp, eax
	mov eax, Messages.unexpected_EOF_end - Messages.unexpected_EOF
	mov ebx, Messages.unexpected_EOF_file_end - Messages.unexpected_EOF_file
	cmovz ebx, eax
	jmp FilenameErrorExit

CheckOpenStandardOutput:
	mov edi, 1
	mov [zCurrentFD], edi
	mov esi, F_GETFL
	mov eax, fcntl
	syscall
	cmp rax, -EBADF
	jz .not_open
	cmp rax, -0x1000
	jnc .error
	and al, O_ACCMODE
	assert O_RDONLY == 0
	jz .not_open
	ret

.not_open:
	mov ebp, Messages.no_standard_output
	mov ebx, Messages.no_standard_output_end - Messages.no_standard_output
	jmp ErrorExit

.error:
	mov ebp, Messages.output_error
	mov ebx, Messages.output_error_end - Messages.output_error
	jmp ErrorExit

WriteError:
	mov dword[zCurrentFD], 2
WriteData:
	; in: rbp: data, rbx: size
	mov edi, [zCurrentFD]
	mov rsi, rbp
	mov rdx, rbx
	mov eax, write
	syscall
	cmp rax, -EINTR
	jz WriteData
	cmp rax, -0x1000
	jnc .done
	add rbp, rax
	sub rbx, rax
	ja WriteData
	cmovz rax, rbx
.done:
	ret

OpenInputDevice:
	; in: r15: input filename; out: [zCurrentFD]: FD, ebx: logical block size, rax: block count; preserves r15
	mov rdi, r15
	assert O_RDONLY == 0
	xor esi, esi
	mov eax, open
	syscall
	cmp rax, -EINTR
	jz OpenInputDevice
	cmp rax, -0x1000
	jnc .open_error
	mov [zCurrentFD], eax
	mov edi, eax
	mov esi, zStatBuffer
	mov eax, fstat
	syscall
	cmp rax, -0x1000
	jnc .stat_error
	assert (S_IFMT & ~0xff00) == 0
	mov al, [zStatBuffer + st_mode + 1]
	and al, S_IFMT >> 8
	cmp al, S_IFREG >> 8
	jz .regular_file_input
	cmp al, S_IFBLK >> 8
	jnz .bad_input_type
	mov edi, [zCurrentFD]
	mov esi, BLKSSZGET
	mov edx, zGenericDataBuffer
	mov eax, ioctl
	syscall
	cmp rax, -0x1000
	jnc .block_size_error
	mov ebx, [zGenericDataBuffer]
	cmp ebx, MAXIMUM_BLOCK_SIZE
	ja .bad_block_size
	cmp ebx, 512
	jc .bad_block_size
	test bl, 7
	jnz .bad_block_size
	mov edi, [zCurrentFD]
	mov esi, BLKGETSIZE64
	mov edx, zGenericDataBuffer
	mov eax, ioctl
	syscall
	cmp rax, -0x1000
	mov rax, [zGenericDataBuffer]
	jc .got_input_size
	mov ebp, Messages.get_device_size_error
	mov ebx, Messages.get_device_size_error_end - Messages.get_device_size_error
	jmp FilenameErrorExit

.regular_file_input:
	; zStatBuffer still contains the result of fstat
	mov rax, [zStatBuffer + st_size]
	mov ebx, [zDefaultFileBlockSize]
.got_input_size:
	xor edx, edx
	div rbx
	test edx, edx
	jnz .bad_device_size
	cmp rax, 2
	jc .bad_device_size
	ret

.open_error:
	mov ebp, Messages.open_error
	mov ebx, Messages.open_error_end - Messages.open_error
	jmp FilenameErrorExit
.stat_error:
	mov ebp, Messages.stat_error
	mov ebx, Messages.stat_error_end - Messages.stat_error
	jmp FilenameErrorExit
.bad_input_type:
	mov ebp, Messages.bad_input_type_error
	mov ebx, Messages.bad_input_type_error_end - Messages.bad_input_type_error
	jmp FilenameErrorExit
.block_size_error:
	mov ebp, Messages.get_block_size_error
	mov ebx, Messages.get_block_size_error_end - Messages.get_block_size_error
	jmp FilenameErrorExit
.bad_block_size:
	mov ebp, Messages.bad_block_size
	mov ebx, Messages.bad_block_size_end - Messages.bad_block_size
	jmp FilenameErrorExit
.bad_device_size:
	mov ebp, Messages.bad_device_size
	mov ebx, Messages.bad_device_size_end - Messages.bad_device_size
	jmp FilenameErrorExit
