ExtractMode:
	endbr64
	call RejectSizeArguments
	mov ebp, Messages.data_file_and_inputs_needed
	mov ebx, Messages.data_file_and_inputs_needed_end - Messages.data_file_and_inputs_needed
	mov edx, [zInputCount]
	cmp edx, 2
	jc ErrorExit
	dec edx
	mov [zInputCount], edx
	mov rbp, [zInputFilenames]
	add rbp, 8
	mov [zInputFilenames], rbp
	call CheckDuplicateFilenameInArray
	mov r15, [rbp - 8]
	call PrepareExtraction
	mov r10, [zInputFilenames]
	times 2 sub r10, r12
.load_filenames_loop:
	mov rsi, [r10 + 2 * r12]
	call FindFilenameInTable
	mov [r12], eax
	add r12, 4
	dec dword[zRemainingInputCount]
	jnz .load_filenames_loop
	jmp Extract

ExtractRenameMode:
	endbr64
	call RejectSizeArguments
	mov ebp, Messages.data_file_and_inputs_needed
	mov ebx, Messages.data_file_and_inputs_needed_end - Messages.data_file_and_inputs_needed
	mov edx, [zInputCount]
	cmp edx, 2
	jc ErrorExit
	shr edx, 1
	mov [zInputCount], edx
	mov ebp, Messages.inputs_not_paired_error
	mov ebx, Messages.inputs_not_paired_error_end - Messages.inputs_not_paired_error
	jnc ErrorExit
	mov rbp, [zInputFilenames]
	mov ebx, 16
	add rbp, rbx
	call CheckDuplicateFilename
	mov r15, [rbp - 16]
	call PrepareExtraction
	lea r15, [r12 + r12]
	neg r15
	mov r10, [zInputFilenames]
	add r10, 8
	mov [zInputFilenames], r10
	add r10, r15
	add r15, r10
.load_filenames_loop:
	mov rsi, [r15 + 4 * r12]
	mov rdi, [r15 + 4 * r12 + 8]
	mov [r10 + 2 * r12], rdi
	call FindFilenameInTable
	mov [r12], eax
	add r12, 4
	dec dword[zRemainingInputCount]
	jnz .load_filenames_loop
	; fallthrough

Extract:
	mov rdi, r13
	lea rsi, [r14 + r14]
	lea rsi, [8 * rsi + 0xff0]
	and rsi, -0x1000
	mov eax, munmap
	syscall
	mov eax, [zInputCount]
	lea r15, [rbp + 4 * rbx]
	mov ebx, [zCurrentOutputOffset]
	mov rdi, [zCurrentBuffer]
.load_file_blocks_loop:
	dec eax
	mov [zRemainingInputCount], eax
	mov eax, [rdi + 4 * rax]
	lea eax, [eax + 2 * eax]
	movzx ecx, word[r15 + 4 * rax + 6]
	dec cx
	inc ecx
	mov [zCurrentBlockSize], ecx
	mov r13d, [r15 + 4 * rax + 8]
	mov [zCurrentInputOffset], r13d
.load_entries_loop:
	cmp ebx, [zCurrentBufferSize]
	jc .no_resize_buffer
	mov esi, ebx
	add esi, 16
	jc OutputTooLargeErrorExit
	call ResizeCurrentBuffer
	mov rdi, rax
.no_resize_buffer:
	mov [rdi + rbx + 8], r13
	mov eax, [rbp + 4 * r13 + 4]
	mov [rdi + rbx + 4], eax
	mov eax, [rbp + 4 * r13]
	test al, al
	jz .not_sequence_block
	movzx eax, al
	lea r13d, [r13d + eax - 2]
	shl eax, 8
.not_sequence_block:
	shr eax, 8
	imul eax, [zCurrentBlockSize]
	not eax
	mov [rdi + rbx], eax
	add r13d, 4
	add ebx, 16
	cmp dword[rbp + 4 * r13], 0
	jnz .load_entries_loop
	inc r13d
	sub r13d, [zCurrentInputOffset]
	mov eax, [zRemainingInputCount]
	mov ecx, [rdi + 4 * rax]
	lea ecx, [ecx + 2 * ecx]
	mov [r15 + 4 * rcx], r13d
	test eax, eax
	jnz .load_file_blocks_loop
	mov r12, rbp
	mov ebp, [zCurrentOutputOffset]
	sub ebx, ebp
	shr ebx, 4
	add rbp, rdi
	call SortPairs
	xor edi, edi
	xor esi, esi
	mov r14, rbp
	mov [zCurrentBufferOffset], ebx
.place_entries_loop:
	mov eax, [rbp + 4]
	cmp esi, eax
	cmovc esi, eax
	not dword[rbp]
	lea edx, [eax + edi]
	sub edx, esi
	add eax, [rbp]
	sub eax, esi
	jbe .range_contained
	mov [rbp + 12], eax
	add esi, eax
	add edi, eax
.range_contained:
	mov eax, [rbp + 8]
	mov [r12 + 4 * rax + 4], edx
	add rbp, 16
	dec ebx
	jnz .place_entries_loop
	mov rsi, [zCurrentBuffer]
	mov ecx, [zInputCount]
	lea rdx, [rsi + 4 * rcx]
	mov r13, rdx
	mov r10, [zInputFilenames]
	mov [zCurrentOutputOffset], edi
.make_file_table_loop:
	mov eax, [rsi]
	lea eax, [eax + 2 * eax]
	mov bx, [r15 + 4 * rax + 6]
	mov [rdx + 6], bx
	mov [rdx + 8], edi
	add edi, [r15 + 4 * rax]
	jc OutputTooLargeErrorExit
	mov rbp, [r10]
	call StringLength
	cmp rbx, 0x10000
	jnc OutputTooLargeErrorExit
	mov [rdx + 4], bx
	add rsi, 4
	add r10, 8
	add rdx, 12
	dec ecx
	jnz .make_file_table_loop
	mov rdx, r13
	mov ecx, [zInputCount]
.place_filenames_loop:
	mov [rdx], edi
	movzx eax, word[rdx + 4]
	add eax, 3
	shr eax, 2
	add edi, eax
	jc OutputTooLargeErrorExit
	add rdx, 12
	dec ecx
	jnz .place_filenames_loop
	mov esi, [zInputCount]
	lea esi, [esi + 2 * esi + 1]
	add esi, edi
	jc OutputTooLargeErrorExit
	sub esi, [zCurrentOutputOffset]
	shl rsi, 2
	call Allocate
	mov rdi, rax
	mov rdx, [zCurrentBuffer]
	mov ebp, [zInputCount]
.copy_block_lists_loop:
	mov ecx, [rdx]
	lea ecx, [ecx + 2 * ecx]
	mov esi, [r15 + 4 * rcx + 8]
	lea rsi, [r12 + 4 * rsi]
	mov ecx, [r15 + 4 * rcx]
	rep movsd
	add rdx, 4
	dec ebp
	jnz .copy_block_lists_loop
	mov rdx, r13
	mov rbx, [zInputFilenames]
	mov ebp, [zInputCount]
.copy_filenames_loop:
	mov rsi, [rbx]
	movzx ecx, word[rdx + 4]
	rep movsb
	add rdi, 3
	and rdi, -4
	add rbx, 8
	add rdx, 12
	dec ebp
	jnz .copy_filenames_loop
	mov rsi, r13
	mov ecx, [zInputCount]
	lea ecx, [ecx + 2 * ecx]
	rep movsd
	mov ecx, [zInputCount]
	mov [rdi], ecx
	add rdi, 4
	sub rdi, rax
	push rdi
	push rax

	call OpenOutput
	mov r13d, [zCurrentBufferOffset]
.output_blocks_loop:
	mov ebx, [r14 + 12]
	test ebx, ebx
	jz .output_next_block
	shl rbx, 2
	mov ebp, [r14 + 4]
	lea rbp, [r12 + 4 * rbp]
	call WriteDataOrFail
.output_next_block:
	add r14, 16
	dec r13d
	jnz .output_blocks_loop
	pop rbp
	pop rbx
	jmp WriteCurrentOutputExit

PrepareExtraction:
	; in: r15 = filename; out: r12 = [zCurrentBuffer], [zRemainingInputCount] = [zInputCount]
	call ReadFile
	call LoadValidateInputDataFile
	call LoadFilenameTable
	mov esi, [zInputCount]
	cmp esi, 0x8000000
	jnc OutputTooLargeErrorExit
	shl esi, 5
	call AllocateCurrentBuffer
	mov r12, rax
	mov esi, [zInputCount]
	mov [zRemainingInputCount], esi
	shl esi, 4
	mov [zCurrentOutputOffset], esi
	ret
