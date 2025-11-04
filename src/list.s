ListContentsZeroMode:
	endbr64
	mov byte[zListingDelimiter], 0
	jmp ListContentsMode.list

ListContentsMode:
	endbr64
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

ListBlocksMode:
	endbr64
	push ListBlocksForFile
	; fallthrough

ListBlocks:
	call RejectSizeArguments
	cmp dword[zInputCount],0
	jz .skip_duplicate_check
	call CheckDuplicateInputFilename
.skip_duplicate_check:
	call OpenValidateDataFile
	call CheckOpenStandardOutput
	mov r12d, [zInputCount]
	test r12d, r12d
	jnz .specific_filenames
	mov [zCurrentInputOffset], ebx
	push rbp
	mov ebp, TableHeaders
	mov ebx, TableHeaders.end - TableHeaders
	call WriteDataOrFail
	pop rbp
	pop r13
.all_files_loop:
	mov ebx, [zCurrentInputOffset]
	call r13
	add dword[zCurrentInputOffset], 3
	dec r14d
	jnz .all_files_loop
	xor edi, edi
	jmp ExitProgram

.specific_filenames:
	call LoadFilenameTable
	mov r15, [zInputFilenames]
.filename_loop:
	dec r12d
	mov rsi, [r15 + 8 * r12]
	call FindFilenameInTable
	mov [r15 + 8 * r12], eax
	test r12d, r12d
	jnz .filename_loop
	mov [zCurrentInputOffset], ebx
	push rbp
	cmp dword[zInputCount], 1
	mov ebp, TableHeaders
	mov eax, TableHeaders.one_file
	cmovz ebp, eax
	mov ebx, TableHeaders.end - TableHeaders
	mov eax, TableHeaders.one_file_end - TableHeaders.one_file
	cmovz ebx, eax
	call WriteDataOrFail
	pop rbp
	pop r13
	xor r12d, r12d
.specific_files_loop:
	mov ebx, [r15 + 8 * r12]
	lea ebx, [ebx + 2 * ebx]
	add ebx, [zCurrentInputOffset]
	call r13
	inc r12d
	cmp r12d, [zInputCount]
	jc .specific_files_loop
	xor edi, edi
	jmp ExitProgram

ListBlocksForFile:
	; in: ebx: input offset
	endbr64
	; cols 0-16: block number, 18-25: count, 27-32: block size, 34-44: offset, 46+: filename
	movzx eax, word[rbp + 4 * rbx + 6]
	dec ax
	inc eax
	shl eax, 2
	mov [zCurrentBlockSize], eax
	mov ecx, 6
	mov edi, zGenericDataBuffer + 1
	call PrintNumber
	mov al, " "
	mov [zGenericDataBuffer], al
	mov [zGenericDataBuffer + 7], al
	mov eax, [rbp + 4 * rbx]
	lea rax, [rbp + 4 * rax]
	mov [zCurrentFilename], rax
	xor eax, eax
	cmp dword[zInputCount], 1
	cmovnz ax, [rbp + 4 * rbx + 4]
	mov [zFilenameLength], ax
	mov ebx, [rbp + 4 * rbx + 8]
	lea rbx, [rbp + 4 * rbx]
.restart_output:
	mov dword[zCurrentOutputOffset], 0
.block_loop:
	mov eax, [rbx]
	test al, al
	jnz .sequence_block
	shr eax, 8
	jz WriteCurrentBuffer
	mov [zTempValue], eax
	movzx esi, word[zFilenameLength]
	cmp esi, 1
	sbb esi, -47
	add esi, [zCurrentOutputOffset]
	call ResizeCurrentBuffer
	mov edi, [zCurrentOutputOffset]
	add rdi, [zCurrentBuffer]
	mov rax, [rbx + 8]
	call .write_location_and_layout
	add rdi, 18
	mov eax, [zTempValue]
	mov ecx, 8
	call PrintNumber
	mov eax, [rbx + 4]
	shl rax, 2
	add rdi, 16
	mov ecx, 11
	call PrintNumber
	add rdi, 12
	add rbx, 16
	cmp dword[zInputCount], 1
	jz .next_block
	mov rsi, [zCurrentFilename]
	movzx ecx, word[zFilenameLength]
	rep movsb
	mov al, `\n`
	stosb
.next_block:
	sub rdi, [zCurrentBuffer]
	mov [zCurrentOutputOffset], edi
	cmp edi, MAXIMUM_BUFFERED_OUTPUT
	jc .block_loop
	push rbx
	call WriteCurrentBuffer
	pop rbx
	jmp .restart_output

.sequence_block:
	mov [zTempValue], al
	movzx eax, al
	movzx esi, word[zFilenameLength]
	cmp esi, 1
	sbb esi, -47
	imul esi, eax
	add esi, [zCurrentOutputOffset]
	call ResizeCurrentBuffer
	mov edi, [zCurrentOutputOffset]
	add rdi, [zCurrentBuffer]
	mov r10d, [rbx]
	shr r10d, 8
	shl r10, 32
	mov r9d, [rbx + 4]
	shl r9, 2
	add rbx, 8
.sequence_loop:
	mov eax, [rbx]
	add rbx, 4
	add rax, r10
	mov r10, rax
	call .write_location_and_layout
	mov rax, "       1"
	mov [rdi + 18], rax
	mov rax, r9
	add rdi, 34
	mov ecx, 11
	call PrintNumber
	add rdi, 12
	mov eax, [zCurrentBlockSize]
	add r9, rax
	cmp dword[zInputCount], 1
	jz .skip_filename
	mov rsi, [zCurrentFilename]
	movzx ecx, word[zFilenameLength]
	rep movsb
	mov al, `\n`
	stosb
.skip_filename:
	dec byte[zTempValue]
	jnz .sequence_loop
	jmp .next_block

.write_location_and_layout:
	mov rcx, [zGenericDataBuffer]
	mov [rdi + 26], rcx
	mov [rdi + 17], cl
	cmp dword[zInputCount], 1
	jnz .keep_space
	mov cl, `\n`
.keep_space:
	mov [rdi + 45], cl
	mov rcx, 100000000000000000
	cmp rax, rcx
	mov ecx, 17
	jc PrintNumber
	mov al, "*"
	rep stosb
	ret
