PartitionsMode:
	endbr64
	call RejectSizeArguments
	cmp dword[zInputCount], 0
	jz .skip_duplicate_check
	call CheckDuplicateInputFilename
.skip_duplicate_check:
	call OpenValidateDataFile
	mov r12d, [zInputCount]
	mov byte[zFallbackPartitionTypes], 1
	test r12d, r12d
	jnz .specific_filenames
	call LoadAllPartitionTables
	xor esi, esi
	lea rdi, [rbp + 4 * rbx]
	lea edx, [r14 + 2 * r14 - 2]
.sum_all_filename_lengths_loop:
	movzx eax, word[rdi + 4 * rdx]
	add rsi, rax
	sub edx, 3
	jnc .sum_all_filename_lengths_loop
	call .prepare_sizes
	mov r13, r12
.all_files_loop:
	call .write_file_data
	add r15, 8
	add ebx, 3
	dec r14d
	jnz .all_files_loop
.write_final_output:
	sub r12, r13
	mov rbp, r13
	lea rbx, [r12 - 1]
	jmp WriteStandardOutputExit

.specific_filenames:
	call LoadPartitionTablesForFilenames
	xor esi, esi
	mov rdi, [zInputFilenames]
	mov ecx, r12d
.sum_specific_filename_lengths_loop:
	mov eax, [rdi + 8 * rcx - 4]
	movzx eax, word[rbp + 4 * rax + 4]
	add rsi, rax
	dec ecx
	jnz .sum_specific_filename_lengths_loop
	mov r14d, r12d
	call .prepare_sizes
	push r12
	mov r13, [zInputFilenames]
.specific_files_loop:
	mov ebx, [r13 + 4]
	call .write_file_data
	add r15, 8
	add r13, 8
	dec r14d
	jnz .all_files_loop
	pop r13
	jmp .write_final_output

.prepare_sizes:
	; in: rsi: total size of filenames; r15: partition tables; r14d: file count; out: r12: buffer; [zColumnWidths] set
	push rsi
	xor eax, eax
	mov r8d, 10000 ; ensure a minimum width of 5
	mov r9d, r8d ; likewise
	xor r10d, r10d
	xor r11d, r11d
	mov [zTempValue], eax
.size_calculation_file_loop:
	mov rdx, [r15 + 8 * r10]
	cmp byte[rdx + partitiondata.type], 2
	jz .add_sizes_for_GPT
	cmp byte[rdx + partitiondata.type], 1
	jnz .size_calculation_next_file
	movzx ecx, byte[rdx + partitiondataMBR.partition_count_small]
	test ecx, ecx
	jz .size_calculation_next_file
	inc dword[zTempValue]
	cmp ecx, 5
	jc .got_MBR_partition_count
	mov ecx, [rdx + partitiondataMBR.partition_count]
.got_MBR_partition_count:
	add r11, rcx
	mov rdi, [rdx + partitiondataMBR.partition_table]
.check_largest_MBR_values:
	movzx edx, byte[rdi + partitionMBR.start_high]
	mov esi, [rdi + partitionMBR.start]
	shl rdx, 32
	or rdx, rsi
	cmp rdx, r8
	cmovnc r8, rdx
	mov esi, [rdi + partitionMBR.length]
	lea rdx, [rdx + rsi - 1]
	cmp rdx, r9
	cmovnc r9, rdx
	cmp eax, [rdi + partitionMBR.number]
	cmovc eax, [rdi + partitionMBR.number]
	add rdi, partitionMBR_size
	dec ecx
	jnz .check_largest_MBR_values
	jmp .size_calculation_next_file
.add_sizes_for_GPT:
	mov ecx, [rdx + partitiondataGPT.partition_count]
	test ecx, ecx
	jz .size_calculation_next_file
	add r11, rcx
	inc dword[zTempValue]
	mov rdi, [rdx + partitiondataGPT.partition_table]
.check_largest_GPT_values:
	cmp eax, [rdi + partitionGPT.number]
	cmovc eax, [rdi + partitionGPT.number]
	mov edx, [rdi + partitionGPT.location]
	cmp r8, [rbp + 4 * rdx + 32]
	cmovc r8, [rbp + 4 * rdx + 32]
	cmp r9, [rbp + 4 * rdx + 40]
	cmovc r9, [rbp + 4 * rdx + 40]
	add rdi, partitionGPT_size
	dec ecx
	jnz .check_largest_GPT_values
.size_calculation_next_file:
	inc r10d
	cmp r10d, r14d
	jc .size_calculation_file_loop
	pop rsi
	call NumberLength
	mov edx, [zTempValue]
	assert zTempValue == zColumnWidths
	mov [zColumnWidths], cl
	mov edi, ecx
	mov rax, r8
	call NumberLength
	mov [zColumnWidths + 1], cl
	add edi, ecx
	mov rax, r9
	call NumberLength
	mov [zColumnWidths + 2], cl
	add edi, ecx
	imul rax, r14, (Headers.partition_list_end - Headers.partition_list) + 35
	add rsi, rax
	add edi, 19
	imul rdx, rdi
	add rsi, rdx
	add edi, MAXIMUM_PARTITION_TYPE_LENGTH - 4
	imul rdi, r11
	add rsi, rdi
	call Allocate
	mov r12, rax
	ret

.write_file_data:
	; in: r15: file partition data, ebx: file table location, r12: output buffer
	mov eax, [rbp + 4 * rbx]
	movzx ecx, word[rbp + 4 * rbx + 4]
	mov rdi, r12
	lea r12, [r12 + rcx + 2]
	lea rsi, [rbp + 4 * rax]
	rep movsb
	mov word[r12 - 2], ": "
	mov rax, countedstring("invalid")
	mov rdx, [r15]
	mov dl, [rdx + partitiondata.type]
	mov ecx, countedstring("no")
	test dl, dl
	cmovz rax, rcx
	mov ecx, countedstring("MBR")
	cmp dl, 1
	cmovz rax, rcx
	mov ecx, countedstring("GPT")
	cmp dl, 2
	cmovz rax, rcx
	movzx ecx, al
	shr rax, 8
	mov [r12], rax
	lea rdi, [r12 + rcx]
	mov esi, Headers.partition_list
	copybytes Headers.partition_list_end - Headers.partition_list
	movzx eax, word[rbp + 4 * rbx + 6]
	mov ecx, 0x10000
	test eax, eax
	cmovz eax, ecx
	shl eax, 2
	mov [zCurrentBlockSize], eax
	call NumberLength
	lea r12, [rdi + rcx + 6]
	call PrintNumber
	mov rax, " bytes"
	mov [r12 - 6], rax
	mov eax, [zCurrentBlockSize]
	cmp eax, 0x400
	jc .no_kilobyte_equivalent
	mov word[r12], " ("
	add r12, 2
	xor edx, edx
	call GetSizeString ; will always be kilobytes!
	mov ecx, 9
	cmp al, " "
	jnz .done_skipping_spaces
.skipping_spaces_loop:
	shr eax, 8
	dec ecx
	cmp al, " "
	jz .skipping_spaces_loop
.done_skipping_spaces:
	mov [r12], eax
	add r12, rcx
	mov dword[r12 - 5], " kiB"
	mov byte[r12 - 1], ")"
.no_kilobyte_equivalent:
	mov byte[r12], `\n`
	inc r12
	mov rdx, [r15]
	mov al, [rdx + partitiondata.type]
	test al, al
	jz .file_data_done
	cmp al, 2
	ja .file_data_done
	jz .write_GPT_partitions

	movzx eax, byte[rdx + partitiondataMBR.partition_count_small]
	test al, al
	jz .file_data_done
	cmp al, 5
	jc .MBR_partitions_exist
	mov eax, [rdx + partitiondataMBR.partition_count]
	test eax, eax
	jz .file_data_done
.MBR_partitions_exist:
	mov [zRemainingInputCount], eax
	call .print_partition_headers
	push r15
	mov r15, [r15]
	mov r15, [r15 + partitiondataMBR.partition_table]
	mov rdi, r12
.MBR_partition_loop:
	movzx ecx, byte[zColumnWidths]
	mov r8d, ecx
	mov eax, [r15 + partitionMBR.number]
	call PrintNumber
	lea rdi, [rdi + r8 + 5]
	mov byte[rdi - 5], " "
	mov eax, "  no"
	mov ecx, " yes"
	test byte[r15 + partitionMBR.entry_flags], 0x80
	cmovnz eax, ecx
	mov [rdi - 4], eax
	movzx ecx, byte[zColumnWidths + 1]
	inc ecx
	mov r8d, ecx
	mov eax, [r15 + partitionMBR.start]
	movzx edx, byte[r15 + partitionMBR.start_high]
	shl rdx, 32
	or rax, rdx
	mov r9, rax
	call PrintNumber
	add rdi, r8
	mov eax, [r15 + partitionMBR.length]
	xchg rax, r9
	add rax, r9
	dec rax
	movzx ecx, byte[zColumnWidths + 2]
	inc ecx
	mov r8d, ecx
	call PrintNumber
	lea r12, [rdi + r8 + 1]
	mov byte[r12 - 1], " "
	mov eax, [zCurrentBlockSize]
	imul rax, r9
	xor edx, edx
	call GetSizeString
	mov [r12], rax
	lea rdi, [r12 + 6]
	mov byte[rdi - 1], " "
	movzx eax, byte[r15 + partitionMBR.type]
	call GetMBRPartitionTypeString
	mov byte[rdi], `\n`
	inc rdi
	add r15, partitionMBR_size
	dec dword[zRemainingInputCount]
	jnz .MBR_partition_loop
.pop_and_done:
	mov r12, rdi
	pop r15
.file_data_done:
	mov byte[r12], `\n`
	inc r12
	ret

.write_GPT_partitions:
	mov eax, [rdx + partitiondataGPT.partition_count]
	test eax, eax
	jz .file_data_done
	mov [zRemainingInputCount], eax
	call .print_partition_headers
	push r15
	mov r15, [r15]
	mov r15, [r15 + partitiondataGPT.partition_table]
	mov rdi, r12
.GPT_partition_loop:
	movzx ecx, byte[zColumnWidths]
	mov r8d, ecx
	mov eax, [r15 + partitionGPT.number]
	call PrintNumber
	lea rdi, [rdi + r8 + 5]
	mov byte[rdi - 5], " "
	mov eax, [r15 + partitionGPT.location]
	lea r10, [rbp + 4 * rax]
	mov eax, "  no"
	mov ecx, " yes"
	test byte[r10 + 48], 4
	cmovnz eax, ecx
	mov [rdi - 4], eax
	movzx ecx, byte[zColumnWidths + 1]
	inc ecx
	mov r8d, ecx
	mov r9, [r10 + 32]
	mov rax, r9
	neg r9
	call PrintNumber
	add rdi, r8
	movzx ecx, byte[zColumnWidths + 2]
	inc ecx
	mov r8d, ecx
	mov rax, [r10 + 40]
	add r9, rax
	inc r9
	call PrintNumber
	lea r12, [rdi + r8 + 1]
	mov byte[r12 - 1], " "
	mov eax, [zCurrentBlockSize]
	mul r9
	call GetSizeString
	mov [r12], rax
	lea rdi, [r12 + 6]
	mov byte[rdi - 1], " "
	mov rsi, r10
	call LoadGUID
	movdqa xmm7, xmm0
	call GetGPTPartitionTypeString
	mov byte[rdi], `\n`
	inc rdi
	add r15, partitionGPT_size
	dec dword[zRemainingInputCount]
	jnz .GPT_partition_loop
	jmp .pop_and_done

.print_partition_headers:
	movzx ecx, byte[zColumnWidths]
	mov al, " "
	mov rdi, r12
	rep stosb
	mov word[rdi - 1], "# "
	mov dword[rdi + 1], "boot"
	add rdi, 5
	movzx ecx, byte[zColumnWidths + 1]
	sub ecx, 4
	rep stosb
	mov dword[rdi], "star"
	mov byte[rdi + 4], "t"
	add rdi, 5
	movzx ecx, byte[zColumnWidths + 2]
	sub ecx, 3
	rep stosb
	mov rcx, " end  si"
	mov [rdi], rcx
	mov rcx, `ze type\n`
	mov [rdi + 8], rcx
	lea r12, [rdi + 16]
	ret

LoadPartitionTablesForFilenames:
	; in: [zInputFilenames]: filenames, r12: filename count, plus OpenValidateDataFile's outputs; out: r15: partition tables
	; overwrites [zInputFilenames] with (index, file table location) pairs
	push r12
	call LoadFilenameTable
	mov r15, [zInputFilenames]
.filename_loop:
	mov rsi, [r15 + 8 * r12 - 8]
	call FindFilenameInTable
	mov [r15 + 8 * r12 - 8], eax
	lea eax, [rax + 2 * rax]
	add eax, ebx
	mov [r15 + 8 * r12 - 4], eax
	dec r12d
	jnz .filename_loop
	mov rdi, r13
	lea rsi, [8 * r14 + 0x7f8]
	add rsi, rsi
	and rsi, -0x1000
	mov eax, munmap
	syscall
	mov r12d, [rsp]
	lea rsi, [8 * r12]
	call Allocate
	lea r13, [rax + 8 * r12]
	xor edi, edi
	mov [zCurrentBufferSize], edi
	test r13w, 0xff8
	cmovz r13, rdi
	xchg r13, r15
	push rax
.load_loop:
	mov edi, [r13 + 8 * r12 - 8]
	call LoadPartitionTablesForFile
	dec r12d
	mov rax, [rsp]
	mov rdi, [zCurrentPartitionTable]
	mov [rax + 8 * r12], rdi
	jnz .load_loop
	pop r15
	pop r12
	jmp ReleaseCurrentBuffer

GetSizeString:
	; in: rdx:rax: size (rdx < 0x4000000); out: rax: string (5 characters, padded with spaces)
	; this function will return nonsense for rdx:rax < 100 (e.g., "2.00B"), but it is never called for those values
	test edx, edx
	jz .no_overflow
	shrd rax, rdx, 30
	mov edx, 3
.no_overflow:
	bsr rcx, rax
	imul ecx, 26 ; divide by 10 by multiplying by 26
	movzx ecx, ch
	add edx, ecx
	lea ecx, [rcx + 4 * rcx]
	shl ecx, 1
	mov edi, 100
	shl rdi, cl
	cmp rax, rdi
	jnc .ok
	lea rax, [rax + 4 * rax]
	shl rax, 1
	inc ch
	cmp rax, rdi
	jnc .ok
	lea rax, [rax + 4 * rax]
	shl rax, 1
	inc ch
.ok:
	shr rax, cl
	mov dl, [edx + MiscStrings.size_suffixes]
	shl rdx, 40
	push rdx
	mov [rsp], ch
	lea rdi, [rsp + 1]
	mov ecx, 4
	call PrintNumber
	mov al, [rsp]
	test al, al
	jz .done
	lea rsi, [rsp + 2]
	movsb
	cmp al, 2
	jz .shifted
	movsb
.shifted:
	mov byte[rdi], "."
.done:
	pop rax
	shr rax, 8
	ret
