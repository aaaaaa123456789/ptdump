ListContentsZeroMode:
	mov byte[zListingDelimiter], 0
	jmp ListContentsMode.list

ListContentsMode:
	mov byte[zListingDelimiter], `\n`
.list:
	cmp dword[zInputCount], 0
	mov ebp, Messages.inputs_not_valid_error
	mov ebx, Messages.inputs_not_valid_error_end - Messages.inputs_not_valid_error
	jnz BadInvocationExit
	call RejectSizeArguments
	call OpenValidateDataFile
	mov esi, r14d
	lea ecx, [esi + 2 * esi - 2]
	lea rdx, [rbp + 4 * rbx]
.sum_loop:
	movzx eax, word[rdx + 4 * rcx]
	add rsi, rax
	sub ecx, 3
	jnc .sum_loop
	call Allocate
	mov rdi, rax
	mov rdx, rax
	mov al, [zListingDelimiter]
.copy_loop:
	mov esi, [rbp + 4 * rbx]
	movzx ecx, word[rbp + 4 * rbx + 4]
	lea rsi, [rbp + 4 * rsi]
	rep movsb
	stosb
	add ebx, 3
	dec r14d
	jnz .copy_loop
	mov rbp, rdx
	sub rdi, rdx
	mov rbx, rdi
	jmp WriteStandardOutputExit
