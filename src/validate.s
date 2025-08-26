OpenValidateDataFile:
	; same outputs as for OpenValidateInputDataFile, plus [zDataFilename] in r15
	mov r15, [zDataFilename]
	test r15, r15
	jnz OpenValidateInputDataFile
	xor edi, edi
	mov esi, F_GETFL
	mov eax, fcntl
	syscall
	cmp rax, -EBADF
	jz .no_standard_input
	mov ebp, Messages.read_error
	mov ebx, Messages.read_error_end - Messages.read_error
	cmp rax, -0x1000
	jnc ErrorExit
	and al, O_ACCMODE
	cmp al, O_WRONLY
.no_standard_input:
	mov ebp, Messages.no_standard_input
	mov ebx, Messages.no_standard_input_end - Messages.no_standard_input
	jz ErrorExit
	xor ebp, ebp
	xor ebx, ebx
	call ReadInputFile
	jmp OpenValidateInputDataFile.read

OpenValidateInputDataFile:
	; in: r15: filename; out: rbp: data buffer; ebx: file table offset; r14d: file count
	call MapInputFile
.read:
	test rbx, rbx
	jz .invalid
	test bl, 3
	jnz .invalid
	mov rax, 1 << 34
	cmp rbx, rax
	ja .invalid
	shr rbx, 2
	dec ebx
	mov r14d, [rbp + 4 * rbx]
	test r14d, r14d
	jz .invalid
	mov edi, ebx
	lea rax, [r14 + 2 * r14]
	sub rbx, rax
	jc .invalid
	lea rsi, [rbp + 4 * rbx]
	mov r10d, r14d
.file_loop:
	lodsd
	mov edx, eax
	cmp edx, edi
	ja .invalid
	lodsw
	movzx ecx, ax
	test ecx, ecx
	jz .invalid
	lea eax, [ecx + 3]
	shr eax, 2
	add eax, edx
	jc .invalid
	cmp eax, edi
	ja .invalid
	xchg rdi, rdx
	lea rdi, [rbp + 4 * rdi]
	xor al, al
	repnz scasb
	jz .invalid
	mov rdi, rdx
	lodsw
	movzx eax, ax
	mov ecx, 0x10000
	test eax, eax
	cmovnz ecx, eax
	lodsd
	cmp eax, edi
	ja .invalid
	mov edx, [rbp + 4 * rax]
	test edx, edx
	jz .invalid
.block_loop:
	test dl, dl
	jnz .sequence_block
	add eax, 4
	jc .invalid
	cmp eax, edi
	ja .invalid
	shr edx, 8
	mov r9, [rbp + 4 * rax - 8]
	dec edx
	add r9, rdx
	inc edx
	jc .invalid
	imul rdx, rcx
	mov r9d, [rbp + 4 * rax - 12]
	add rdx, r9
	cmp rdx, rdi
	jbe .next_block
.invalid:
	mov ebp, FilenameStrings.stdin
	test r15, r15
	cmovz r15, rbp
	mov ebp, Messages.data_file_not_valid
	mov ebx, Messages.data_file_not_valid_end - Messages.data_file_not_valid
	jmp FilenameErrorExit

.sequence_block:
	cmp eax, edi
	jnc .invalid
	mov r9d, [rbp + 4 * rax + 4]
	movzx edx, dl
	add eax, 2
	jc .invalid
	add eax, edx
	jc .invalid
	cmp eax, edi
	ja .invalid
	imul rdx, rcx
	add rdx, r9
	cmp rdx, rdi
	ja .invalid
.next_block:
	mov edx, [rbp + 4 * rax]
	test edx, edx
	jnz .block_loop
	dec r10d
	jnz .file_loop
	ret
