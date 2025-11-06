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
	lea ecx, [rsi + 2 * rsi - 2]
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

ListEffectiveBlocksMode:
	endbr64
	push ListEffectiveBlocksForFile
	jmp ListBlocks

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
	lea ebx, [rbx + 2 * rbx]
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
	call PrepareFixedBlockListColumnsForFile
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
	mov [zCurrentBlockCount], eax
	mov eax, 1
	call ExtendBlockListBuffer
	mov eax, [rbx + 4]
	mov rdx, [rbx + 8]
	mov [zCurrentBlockLocation], eax
	add rbx, 16
	call WriteBlockListEntry
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
	call ExtendBlockListBuffer
	mov r10d, [rbx]
	shr r10d, 8
	shl r10, 32
	mov eax, [rbx + 4]
	add rbx, 8
	mov dword[zCurrentBlockCount], 1
	mov [zCurrentBlockLocation], eax
.sequence_loop:
	mov edx, [rbx]
	add rbx, 4
	add rdx, r10
	mov r10, rdx
	call WriteBlockListEntry
	mov eax, [zCurrentBlockSize]
	add [zCurrentBlockLocation], eax
	dec byte[zTempValue]
	jnz .sequence_loop
	jmp .next_block

ListEffectiveBlocksForFile:
	; in: ebx: input offset
	endbr64
	call PrepareFixedBlockListColumnsForFile
	push r15
	mov edi, ebx
	xor r15d, r15d
	mov [zCurrentOutputOffset], r15d
	call LoadEffectiveBlockListForOffset
	mov [zInputBlockListPointer], rsi
	mov r15, rsi
	mov eax, edi
	mov [zTempValue], edi
	call ExtendBlockListBuffer
.block_loop:
	mov rdx, [r15 + 8]
	assert zCurrentBlockLocation - zCurrentBlockCount == 4
	mov [zCurrentBlockCount], rdx
	mov rdx, [r15]
	call WriteBlockListEntry
	add r15, 16
	dec dword[zTempValue]
	jnz .block_loop
	mov rbx, rdi
	mov rsi, r15
	mov r15, rbp
	mov rdi, [zInputBlockListPointer]
	sub rsi, rdi
	add rsi, 0xfff
	and rsi, -0x1000
	mov eax, munmap
	syscall
	mov rbp, [zCurrentBuffer]
	sub rbx, rbp
	call WriteDataOrFail
	mov rbp, r15
	pop r15
	ret

PrepareFixedBlockListColumnsForFile:
	; in: rbp: data file buffer, ebx: file table entry location
	mov eax, [rbp + 4 * rbx]
	lea rax, [rbp + 4 * rax]
	mov [zCurrentFilename], rax
	xor eax, eax
	cmp dword[zInputCount], 1
	cmovnz ax, [rbp + 4 * rbx + 4]
	mov [zFilenameLength], ax
	mov edi, zGenericDataBuffer + 1
	mov al, " "
	mov [rdi - 1], al
	mov [rdi + 6], al
	movzx eax, word[rbp + 4 * rbx + 6]
	dec ax
	inc eax
	mov [zCurrentBlockSize], eax
	shl eax, 2
	mov ecx, 6
	jmp PrintNumber

ExtendBlockListBuffer:
	; in: eax: number of entries
	movzx esi, word[zFilenameLength]
	cmp esi, 1
	sbb esi, -47
	imul esi, eax
	add esi, [zCurrentOutputOffset]
	call ResizeCurrentBuffer
	mov edi, [zCurrentOutputOffset]
	add rdi, [zCurrentBuffer]
	ret

WriteBlockListEntry:
	; in: rdx: block number; [zCurrentBlockCount] and [zCurrentBlockLocation] set; [zGenericDataBuffer] containing the block size with spaces around it;
	; ... [zCurrentFilename] and [zFilenameLength] set (to zero if no filename should be printed); in/out: rdi: output location
	; layout: cols 0-16: block number, 18-25: count, 27-32: block size, 34-44: offset, 46+: filename
	mov al, "*"
	mov ecx, 26
	rep stosb
	mov rcx, [zGenericDataBuffer]
	mov [rdi], rcx
	mov [rdi - 9], cl
	sub rdi, 26
	cmp dword[zInputCount], 1
	jnz .keep_space
	mov cl, `\n`
.keep_space:
	mov [rdi + 45], cl
	mov rcx, 100000000000000000
	cmp rdx, rcx
	jnc .block_number_overflow
	mov rax, rdx
	mov ecx, 17
	call PrintNumber
.block_number_overflow:
	add rdi, 18
	mov eax, [zCurrentBlockCount]
	cmp eax, 100000000
	jnc .block_count_overflow
	mov ecx, 8
	call PrintNumber
.block_count_overflow:
	add rdi, 16
	mov eax, [zCurrentBlockLocation]
	shl rax, 2
	mov ecx, 11
	call PrintNumber
	add rdi, 12
	cmp dword[zInputCount], 1
	jz .no_filename
	mov rsi, [zCurrentFilename]
	movzx ecx, word[zFilenameLength]
	rep movsb
	mov al, `\n`
	stosb
.no_filename:
	ret
