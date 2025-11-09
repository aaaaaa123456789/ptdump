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
	mov rax, [zCurrentBuffer]
	test rax, rax
	jz AllocateCurrentBuffer
	add esi, 0xfff
	and esi, -0x1000
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
	jc ResizeCurrentBuffer.done ; any return will do
AllocationErrorExit:
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

RejectSizeArguments:
	cmp dword[zSizeSpecCount], 2
	mov ebp, Messages.sizes_not_valid_error
	mov ebx, Messages.sizes_not_valid_error_end - Messages.sizes_not_valid_error
	jnc BadInvocationExit
	cmp dword[zDefaultFileBlockSize], 0
	jnz BadInvocationExit
	ret

Abort:
	mov eax, getpid
	syscall
	mov edi, eax
	mov esi, SIGABRT
	mov eax, kill
	syscall
	ud2

UpdateCRC:
	; in: rsi: buffer, ecx: length; in/out: edi: partial result; only clobbers rax
	mov eax, edi
	mov al, byte[rsi]
	inc rsi
	xor eax, edi
	shr edi, 8
	xor edi, [4 * rax + CRCTable]
	dec ecx
	jnz UpdateCRC
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

NumberLength:
	; input: rax: number (preserved); output: ecx: number of digits; preserves all other registers
	bsr rcx, rax
	cmovz ecx, eax
	movzx ecx, byte[ecx + DigitLengths.lengths]
	shr ecx, 1
	jnc .done
	cmp [8 * ecx + DigitLengths.thresholds - 8], rax
	adc ecx, 0
.done:
	ret

PrintNumber:
	; input: rax: number, rdi: buffer, ecx: length; preserves rdi
	mov esi, 10
.loop:
	xor edx, edx
	div rsi
	add dl, "0"
	mov [rdi + rcx - 1], dl
	test rax, rax
	jz .pad
	dec ecx
	jnz .loop
	ret

.pad:
	dec ecx
	jz .done
	mov al, " "
	mov esi, ecx
	rep stosb
	sub rdi, rsi
.done:
	ret

WriteNumberToBuffer:
	; input: rax: number, rdi: buffer; advances rdi by the printed length; clobbers rcx, rdx, rsi, r8
	call NumberLength
	mov r8d, ecx
	call PrintNumber
	add rdi, r8
	ret

CheckUnpairedUTF16Surrogate:
	; in: cl: remaining characters, ax: current codepoint, rsi: pointer to next codepoint; out: carry flag set: unpaired surrogate
	; in/out: [zUnicodeSurrogatePair]: 1 if the next character is a low surrogate, 0 otherwise; clobbers only ch
	mov ch, ah
	sub ch, 0xd8
	shr ch, 2
	; ch = 0: high surrogate, 1: low surrogate, else: not a surrogate
	cmp ch, 1
	ja .done
	jz .low
	cmp cl, 2
	jc .done
	mov ch, [rsi + 1]
	add ch, 0x20
	cmp ch, 0xfc
	setnc [zUnicodeSurrogatePair]
.done:
	ret

.low:
	xor ch, ch
	xchg ch, [zUnicodeSurrogatePair]
	cmp ch, 1
	ret
