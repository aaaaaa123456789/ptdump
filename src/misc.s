Allocate:
	; in: rsi: size; out: rax: allocation
	add rsi, 0xfff
	and rsi, -0x1000
AllocateAligned:
	xor edi, edi
	mov edx, PROT_READ | PROT_WRITE
	mov r10d, MAP_ANONYMOUS | MAP_PRIVATE
	mov r8, -1
	xor r9d, r9d
	mov eax, mmap
DoAllocationCall:
	syscall
	cmp rax, -0x1000
	jc WriteData.done ; any return will do
	mov ebp, Messages.allocation_error
	mov ebx, Messages.allocation_error_end - Messages.allocation_error
	call WriteError
	mov edi, 2
ExitProgram:
	mov eax, exit_group
	syscall
	ud2

FilenameErrorExit:
	; in: rbp: error message; rbx: message size; r15: filename
	call WriteError
	mov rbp, r15
	call StringLength
	mov byte[rbp + rbx], `\n` ; preserving the string is not needed since the program is exiting
	inc rbx
ErrorExit:
	; in: rbp: error message; rbx: message size
	call WriteError
	mov edi, 1
	jmp ExitProgram

OutputTooLargeErrorExit:
	mov ebp, Messages.output_too_large_error
	mov ebx, Messages.output_too_large_error_end - Messages.output_too_large_error
	jmp ErrorExit

Abort:
	mov eax, getpid
	syscall
	mov edi, eax
	mov esi, SIGABRT
	mov eax, kill
	syscall
	ud2

AllocateCurrentBuffer:
	; in: esi: size (unaligned); out: rax and [zCurrentBuffer]: allocation, [zCurrentBufferSize]: true size
	add esi, 0xfff
	and esi, -0x1000
	mov [zCurrentBufferSize], esi
	call AllocateAligned
	mov [zCurrentBuffer], rax
	ret

ResizeCurrentBuffer:
	; in: esi: new size (unaligned), [zCurrentBuffer]: current buffer, [zCurrentBufferSize]: current size; same output as AllocateCurrentBuffer
	add esi, 0xfff
	and esi, -0x1000
	mov rax, [zCurrentBuffer]
	mov edx, [zCurrentBufferSize]
	cmp edx, esi
	jnc .done ; if the buffer is larger, leave it alone
	mov [zCurrentBufferSize], esi
	xchg edx, esi
	mov rdi, rax
	mov r10d, MREMAP_MAYMOVE
	mov eax, mremap
	call DoAllocationCall
	mov [zCurrentBuffer], rax
.done:
	ret

StringLength:
	; input: rbp: string; output: rbx: length
	lea rbx, [rbp - 1]
.loop:
	inc rbx
	cmp byte[rbx], 0
	jnz .loop
	sub rbx, rbp
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
