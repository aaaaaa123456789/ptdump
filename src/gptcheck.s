GPTChecksumMode:
	endbr64
	call RejectSizeArguments
	cmp dword[zInputCount], 0
	jz .skip_duplicate_filename_check
	call CheckDuplicateInputFilename
.skip_duplicate_filename_check:
	call OpenValidateDataFile
	call CheckOpenStandardOutput
	mov r12d, [zInputCount]
	test r12d, r12d
	jnz .specific_filenames
	mov esi, r14d
	shl rsi, 4
	mov r15, rsi
	call Allocate
	mov r13, rax
	add rax, r15
	xor r15d, r15d
	test eax, 0xff8
	cmovnz r15, rax
	mov [zRemainingInputCount], r14d
	mov byte[zSingleFileOutputMode], 0
	mov r14, r13
.load_all_block_tables_loop:
	mov edi, r12d
	call LoadEffectiveBlockList
	mov [r14], rsi
	mov [r14 + 8], edi
	mov [r14 + 12], r12d
	add r14, 16
	inc r12d
	cmp r12d, [zRemainingInputCount]
	jc .load_all_block_tables_loop
	jmp .process_files

.specific_filenames:
	mov [zRemainingInputCount], r12d
	dec r12d
	setz [zSingleFileOutputMode]
	call LoadFilenameTable
	mov r15, [zInputFilenames]
.search_filename_loop:
	mov rsi, [r15 + 8 * r12]
	call FindFilenameInTable
	mov [r15 + 8 * r12], eax
	sub r12d, 1
	jnc .search_filename_loop
	mov rdi, r13
	lea rsi, [r14 + r14]
	lea rsi, [8 * rsi + 0xff0]
	and rsi, -0x1000
	mov eax, munmap
	syscall
	mov esi, [zRemainingInputCount]
	shl rsi, 4
	mov r15, rsi
	call Allocate
	mov r13, rax
	add rax, r15
	xor r15d, r15d
	test eax, 0xff8
	cmovnz r15, rax
	xor r12d, r12d
	mov r14, r13
.load_specific_block_tables_loop:
	mov rdi, [zInputFilenames]
	mov edi, [rdi + 8 * r12]
	mov [r14 + 12], edi
	call LoadEffectiveBlockList
	mov [r14], rsi
	mov [r14 + 8], edi
	add r14, 16
	inc r12d
	cmp r12d, [zRemainingInputCount]
	jc .load_specific_block_tables_loop

.process_files:
	; input: r13: pointer to file data (block table, table size, file index); [zRemainingInputCount]: file count
	mov r12, rbp
	mov r14d, ebx
	cmp byte[zSingleFileOutputMode], 0
	mov ebp, TableHeaders.checksum_headers
	mov eax, TableHeaders.checksum_headers_one_file
	cmovnz ebp, eax
	mov ebx, TableHeaders.checksum_headers_end - TableHeaders.checksum_headers
	mov eax, TableHeaders.checksum_headers_one_file_end - TableHeaders.checksum_headers_one_file
	cmovnz ebx, eax
	call WriteDataOrFail
	mov rbp, r12
	xor eax, eax
	mov [zCurrentBuffer], rax
	mov [zCurrentBufferSize], eax
.process_file_loop:
	mov esi, [r13 + 12]
	lea esi, [esi + 2 * esi]
	add esi, r14d
	mov ecx, [rbp + 4 * rsi]
	lea rcx, [rbp + 4 * rcx]
	mov [zCurrentFilename], rcx
	mov esi, [rbp + 4 * rsi + 4]
	movzx ecx, byte[zSingleFileOutputMode]
	dec cx
	and cx, si
	mov [zFilenameLength], cx
	shr esi, 16
	dec si
	inc esi
	cmp esi, 0x7f
	jbe .next_file
	mov [zCurrentBlockSize], esi
	shl esi, 2
	mov r15, [r13]
	cmp qword[r15], 0
	jnz .next_file
	mov edi, [r15 + 12]
	lea rdi, [rbp + 4 * rdi]
	lea r10, [rdi + rsi]
	cmp dword[r15 + 8], 1
	jnz .got_second_block
	cmp dword[r13 + 8], 1
	jz .next_file
	cmp qword[r15 + 16], 1
	jnz .next_file
	mov r10d, [r15 + 28]
	lea r10, [rbp + 4 * r10]
.got_second_block:
	mov r12, r10
	call GetPartitionTableTypeFromBlocks
	cmp al, 2
	jnz .next_file
	shl ecx, 1
	lea esi, [ecx + 2 * ecx + 282]
	mov ebx, esi
	add esi, 20
	call ResizeCurrentBuffer
	mov r10, r12
	add rbx, rax
	xor r11d, r11d
	mov [rbx + 16], r11d
	mov [zCurrentOutputOffset], r11d
	inc r11d
	call .calculate_table_checksums
	mov r11, [r10 + 32]
	cmp r11, 2
	jc .no_alternate_table
	mov rsi, r15
	mov edi, [r13 + 8]
	mov rdx, r11
	call FindBlockTableEntry
	test rdx, rdx
	jz .no_alternate_table
	mov eax, r11d
	sub eax, [rdx]
	imul eax, [zCurrentBlockSize]
	add eax, [rdx + 12]
	lea r10, [rbp + 4 * rax]
	call .check_calculate_table_checksums
.no_alternate_table:
	mov edx, [r13 + 8]
	shl rdx, 4
	add rdx, r15
	mov eax, [rdx - 8]
	dec eax
	add rax, [rdx - 16]
	cmp rax, 2
	jc .no_final_table
	cmp rax, r11
	jz .no_final_table
	mov r11, rax
	mov eax, [rdx - 8]
	dec eax
	imul eax, [zCurrentBlockSize]
	add eax, [rdx - 4]
	lea r10, [rbp + 4 * rax]
	call .check_calculate_table_checksums
.no_final_table:
	call WriteCurrentBuffer
.next_file:
	add r13, 16
	dec dword[zRemainingInputCount]
	jnz .process_file_loop
	xor edi, edi
	jmp ExitProgram

.check_calculate_table_checksums:
	mov rax, "EFI PART"
	cmp [r10], rax
	jnz .done
	cmp dword[r10 + 8], 0x10000
	jnz .done
	mov eax, [r10 + 12]
	cmp eax, 92
	jc .done
	mov ecx, [zCurrentBlockSize]
	shl ecx, 2
	cmp eax, ecx
	ja .done
.calculate_table_checksums:
	; in: r11: block number, r10: block pointer, r15: block table, [r13 + 8]: block table size, rbx: 20-byte buffer (last word set to zero)
	movdqu xmm0, [r10]
	movdqu [rbx], xmm0
	mov edi, -1
	mov rsi, rbx
	mov ecx, 20
	call UpdateCRC
	lea rsi, [r10 + 20]
	mov ecx, [r10 + 12]
	sub ecx, 20
	call UpdateCRC
	mov r9d, [r10 + 16]
	mov r8, " header "
	call .print_checksum
	mov rdx, [r10 + 72]
	mov r12, rdx
	mov rsi, r15
	mov edi, [r13 + 8]
	call FindBlockTableEntry
	test rdx, rdx
	jz .done
	mov r9d, [r13 + 8]
	shl r9, 4
	add r9, r15
	mov r8d, [r10 + 80]
	mov eax, [r10 + 84]
	imul r8, rax
	mov eax, r12d
	sub eax, [rdx]
	mov ecx, [rdx + 8]
	sub ecx, eax
	mov esi, [zCurrentBlockSize]
	imul eax, esi
	add r12, rcx
	shl esi, 2
	imul rcx, rsi
	add eax, [rdx + 12]
	mov edi, -1
.partition_checksum_loop:
	lea rsi, [rbp + 4 * rax]
	cmp rcx, r8
	cmovnc rcx, r8
	sub r8, rcx
	call UpdateCRC
	test r8, r8
	jz .got_partition_checksum
	add rdx, 16
	cmp rdx, r9
	jnc .done
	cmp r12, [rdx]
	jnz .done
	mov eax, [zCurrentBlockSize]
	shl eax, 2
	mov ecx, [rdx + 8]
	add r12, rcx
	imul rcx, rax
	mov eax, [rdx + 12]
	jmp .partition_checksum_loop
.got_partition_checksum:
	mov r9d, [r10 + 88]
	mov r8, " ptable "
.print_checksum:
	mov edx, edi
	not edx
	mov edi, [zCurrentOutputOffset]
	add rdi, [zCurrentBuffer]
	mov al, "*"
	mov ecx, 17
	rep stosb
	mov [rdi], r8
	add rdi, 8
	mov eax, edx
	call RenderLowercaseHexWord
	mov [rdi], rax
	mov byte[rdi + 8], " "
	add rdi, 9
	mov rax, "   OK   "
	cmp edx, r9d
	jz .checksumOK
	mov eax, r9d
	call RenderLowercaseHexWord
.checksumOK:
	stosq
	mov rax, 100000000000000000
	cmp r11, rax
	jnc .skip_block_number
	sub rdi, 42
	mov rax, r11
	mov ecx, 17
	call PrintNumber
	add rdi, 42
.skip_block_number:
	movzx ecx, word[zFilenameLength]
	test ecx, ecx
	jz .skip_filename
	mov byte[rdi], " "
	inc rdi
	mov rsi, [zCurrentFilename]
	rep movsb
.skip_filename:
	mov byte[rdi], `\n`
	sub rdi, [zCurrentBuffer]
	inc edi
	mov [zCurrentOutputOffset], edi
.done:
	ret
