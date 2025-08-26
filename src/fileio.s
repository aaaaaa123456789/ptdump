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
