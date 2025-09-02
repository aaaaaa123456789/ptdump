DumpSectorsMode:
	endbr64
	mov esi, [zInputCount]
	test esi, esi
	jz NoInputsExit
	shr esi, 1
	mov ebp, Messages.inputs_not_paired_error
	mov ebx, Messages.inputs_not_paired_error_end - Messages.inputs_not_paired_error
	jc BadInvocationExit
	mov [zInputCount], esi
	mov [zRemainingInputCount], esi
	assert inputsect_size == 48
	lea rsi, [rsi + 2 * rsi]
	shl rsi, 4
	call Allocate
	assert zInputFilenames == zInputDevices
	mov rsi, [zInputFilenames]
	mov [zInputDevices], rax
	mov r12, rax
	mov byte[zRemainingBufferBlocks], 0
.parse_input_loop:
	lodsq
	mov [r12 + inputsect.input_filename], rax
	mov [r12 + inputsect.output_filename], rax
	lodsq
	push rsi
	mov rsi, rax
	mov r14, rax
	xor ecx, ecx
.count_ranges_loop_outer:
	inc ecx
	jz .invalid_range
.count_ranges_loop_inner:
	lodsb
	test al, al
	jz .got_range_count
	cmp al, ","
	jz .count_ranges_loop_outer
	cmp al, ":"
	jnz .count_ranges_loop_inner
	cmp byte[rsi], 0
	jz .got_range_count
	mov [r12 + inputsect.output_filename], rsi
.got_range_count:
	cmp ecx, 0x2000000
	jnc .invalid_range
	mov [r12 + inputsect.range_count], ecx
	cmp ecx, 0x7f
	jbe .use_common_buffer
	shl ecx, 5
	mov esi, ecx
	call Allocate
	jmp .got_range_buffer

.invalid_range:
	; placed here because it's a convenient (and unreachable) location near the code that will jump to this snippet
	mov ebp, Messages.invalid_sector_list
	mov ebx, Messages.invalid_sector_list_end - Messages.invalid_sector_list
	mov rax, r14
	jmp Main.option_error_exit

.use_common_buffer:
	movzx eax, byte[zRemainingBufferBlocks]
	sub eax, ecx
	jnc .common_buffer_OK
	mov esi, 0x1000
	call AllocateAligned
	mov r13, rax
	mov eax, 0x80
	sub eax, [r12 + inputsect.range_count]
.common_buffer_OK:
	mov [zRemainingBufferBlocks], al
	shl eax, 5
	add rax, r13
.got_range_buffer:
	mov [r12 + inputsect.range_list], rax

	mov rdi, rax
	mov rsi, r14
.parse_range_loop:
	lodsb
	movzx eax, al
	sub eax, "0"
	cmp eax, 10
	jnc .invalid_range
	xor edx, edx
	mov r8, 1844674407370955162 ; 2^64 / 10, rounded up
.starting_digit_loop:
	cmp rdx, r8
	jnc .invalid_range
	lea rdx, [rdx + 4 * rdx]
	add rdx, rdx
	add rdx, rax
	jc .invalid_range
	lodsb
	movzx eax, al
	sub eax, "0"
	cmp eax, 10
	jc .starting_digit_loop
	mov [rdi], rdx
	xor ecx, ecx
	cmp eax, "-" - "0"
	jnz .no_ending_value
	lodsb
	movzx eax, al
	sub eax, "0"
	cmp eax, 10
	jnc .invalid_range
.ending_digit_loop:
	cmp rcx, r8
	jnc .invalid_range
	lea rcx, [rcx + 4 * rcx]
	add rcx, rcx
	add rcx, rax
	jc .invalid_range
	lodsb
	movzx eax, al
	sub eax, "0"
	cmp eax, 10
	jc .ending_digit_loop
	sub rcx, rdx
	cmp rcx, 0x1fffffe
	jnc .invalid_range
.no_ending_value:
	inc ecx
	mov ebx, 0xffffff
	cmp ecx, ebx
	jbe .no_split_range
	add rdi, 16
	mov [rdi - 8], ebx
	add rdx, rbx
	sub ecx, ebx
	mov [rdi], rdx
	inc dword[r12 + inputsect.range_count]
.no_split_range:
	mov [rdi + 8], ecx
	add rdi, 16
	cmp eax, "," - "0"
	jz .parse_range_loop
	cmp eax, -"0"
	jz .got_ranges
	cmp eax, ":" - "0"
	jnz .invalid_range

.got_ranges:
	mov ebx, [r12 + inputsect.range_count]
	cmp ebx, 1
	jz .validated_ranges
	mov rbp, [r12 + inputsect.range_list]
	call SortPairs
	shl ebx, 4
	add rbx, rbp
	lea rdi, [rbx - 16]
.merge_range_loop:
	mov rax, [rdi - 16]
	mov ecx, [rdi - 8]
	add rcx, rax
	mov rdx, [rdi]
	cmp rcx, rdx
	jc .next_range
	mov esi, [rdi + 8]
	add rdx, rsi
	cmp rdx, rcx
	cmovc edx, ecx
	sub edx, eax
	mov ecx, 0xffffff
	sub edx, ecx
	mov [rdi - 8], edx
	mov [rdi + 8], ecx
	lea rax, [rax + rdx]
	mov [rdi], rax
	ja .next_range
	add [rdi - 8], ecx
	sub rbx, 16
	dec dword[r12 + inputsect.range_count]
	mov ecx, ebx
	sub ecx, edi
	jz .next_range
	shr ecx, 3
	lea rsi, [rdi + 16]
	mov rax, rsi
	rep movsq
	mov rdi, rax
.next_range:
	sub rdi, 16
	cmp rdi, rbp
	jnz .merge_range_loop

.validated_ranges:
	mov ecx, [r12 + inputsect.range_count]
	xor edx, edx
.sum_ranges_loop:
	add edx, [rdi + 8]
	jc .invalid_range
	add rdi, 16
	dec ecx
	jnz .sum_ranges_loop
	cmp edx, 0x2000000
	jnc .invalid_range
	mov [r12 + inputsect.total_sectors], edx
	mov rbp, [r12 + inputsect.output_filename]
	call StringLength
	mov [r12 + inputsect.filename_length], bx
	cmp rbx, 0x10000
	mov rax, rbp
	mov ebp, Messages.filename_too_long_error
	mov ebx, Messages.filename_too_long_error_end - Messages.filename_too_long_error
	jnc Main.option_error_exit

	pop rsi
	add r12, inputsect_size
	dec dword[zRemainingInputCount]
	jnz .parse_input_loop
	mov rbp, [zInputDevices]
	add rbp, inputsect.output_filename
	mov edx, [zInputCount]
	mov ebx, inputsect_size
	call FindDuplicateFilename
	test rbx, rbx
	jz .open_files
	mov rax, rbx
	mov ebp, Messages.duplicate_input_filename
	mov ebx, Messages.duplicate_input_filename_end - Messages.duplicate_input_filename
	jmp Main.option_error_exit

.open_files:
	xor r13d, r13d
	xor r14d, r14d
	mov r12d, edx
	sub rbp, inputsect.output_filename
	cmp dword[zDefaultFileBlockSize], 0
	jnz .open_files_loop
	mov dword[zDefaultFileBlockSize], 512
.open_files_loop:
	mov r15, [rbp + inputsect.input_filename]
	call OpenInputDevice
	mov [rbp + inputsect.block_size], ebx
	mov esi, [zCurrentFD]
	mov [rbp + inputsect.file_descriptor], esi
	mov ecx, [rbp + inputsect.range_count]
	add r14d, ecx
	shl ecx, 4
	mov rsi, [rbp + inputsect.range_list]
	mov edi, [rsi + rcx - 8]
	add rdi, [rsi + rcx - 16]
	cmp rdi, rax
	jbe .sector_range_fits
	mov ebp, Messages.range_beyond_the_end_error
	mov ebx, Messages.range_beyond_the_end_error_end - Messages.range_beyond_the_end_error
	jmp FilenameErrorExit
.sector_range_fits:
	mov eax, [rbp + inputsect.total_sectors]
	imul rax, rbx
	add r13, rax
	jc OutputTooLargeErrorExit
	movzx eax, word[rbp + inputsect.filename_length]
	add eax, 19 ; +12 for the file table entry, +4 for the block list terminator
	and eax, -4
	add r13, rax
	mov rax, r13
	shr rax, 34
	jnz OutputTooLargeErrorExit
	add rbp, inputsect_size
	dec r12d
	jnz .open_files_loop

	mov esi, [zInputCount]
	lea eax, [r14d + 3]
	and eax, -4
	add esi, eax
	lea rsi, [rax + 4 * rsi]
	shl rsi, 2
	call Allocate
	lea rbp, [rax + 4 * r14 + 12]
	and rbp, -16
	mov rax, rbp
	mov r12, [zInputDevices]
	xor ecx, ecx
	xor r11d, r11d
.load_output_sorting_buffer_file_loop:
	movzx edi, word[r12 + inputsect.filename_length]
	add edi, 3
	and edi, -4
	bsf edx, edi
	shl edi, 8
	not rdi
	not dl
	mov [rax], rdi
	mov [rax + 7], dl
	mov dword[rax + 8], "file"
	mov [rax + 12], ecx
	add rax, 16
	xor ebx, ebx
	mov rsi, [r12 + inputsect.range_list]
	mov r10d, [r12 + inputsect.block_size]
	xor r9d, r9d
.load_output_sorting_buffer_range_loop:
	mov edi, [rsi + 8]
	cmp edi, 1
	jnz .append_run_block
	test r9b, r9b
	jz .add_to_sequence
	cmp r9b, 0xff
	jz .append_sequence
	mov rdi, [rsi]
	sub rdi, r8
	shr rdi, 32
	jz .add_to_sequence
.append_sequence:
	mov edi, r9d
	imul r9d, r10d
	bsf edx, r9d
	shl r9, 8
	or r9, rdi
	not dl
	not r9
	mov [rax], r9
	mov [rax + 7], dl
	mov [rax + 8], r11d
	mov [rax + 12], ecx
	add rax, 16
	xor r9d, r9d
.add_to_sequence:
	dec r11
	mov [rbp + 4 * r11], ebx
	mov r8, [rsi]
	inc r9d
	jmp .sort_next_range

.append_run_block:
	imul rdi, r10
	bsf rdx, rdi
	shl rdi, 8
	not rdi
	not dl
	mov [rax], rdi
	mov [rax + 7], dl
	mov [rax + 8], ebx
	mov [rax + 12], ecx
	add rax, 16
.sort_next_range:
	add rsi, 16
	inc ebx
	cmp ebx, [r12 + inputsect.range_count]
	jc .load_output_sorting_buffer_range_loop
	test r9b, r9b
	jz .skip_appending_final_sequence
	imul r10d, r9d
	bsf edx, r10d
	shl r10, 8
	or r10, r9
	not dl
	not r10
	mov [rax], r10
	mov [rax + 7], dl
	mov [rax + 8], r11d
	mov [rax + 12], ecx
	add rax, 16
.skip_appending_final_sequence:
	add r12, inputsect_size
	inc ecx
	cmp ecx, [zInputCount]
	jc .load_output_sorting_buffer_file_loop
	sub eax, ebp
	shl r11d, 2
	mov ebx, eax
	sub eax, r11d
	shr ebx, 4
	lea r13, [r13 + rax + 4] ; final allocation size
	call SortPairs

	xor r11d, r11d
	mov rsi, rbp
	mov r12, [zInputDevices]
.calculate_offsets_loop:
	mov r10d, [rsi + 12]
	assert inputsect_size == 48
	lea r10, [r10 + 2 * r10]
	shl r10, 4
	add r10, r12
	mov rcx, [rsi]
	not rcx
	mov rdx, rcx
	shr rdx, 10
	movsx rdi, dword[rsi + 8]
	cmp edi, "file"
	jz .file_offset
	test edi, edi
	jns .run_offset
	movzx ecx, cl
	lea rdi, [rdi + rcx - 1]
	lea r9, [rbp + 4 * rdi]
	mov eax, [r10 + inputsect.block_size]
	shr eax, 2
	mov r8, [r10 + inputsect.range_list]
	mov edx, [r9]
	mov [r9], ecx
.calculate_sequence_offset_loop:
	shl rdx, 4
	mov [r8 + rdx + 12], r11d
	add r11d, eax
	mov [r8 + rdx + 8], edi
	dec ecx
	jz .next_offset_updated
	sub r9, 4
	mov edx, [r9]
	jmp .calculate_sequence_offset_loop

.run_offset:
	shl rdi, 4
	add rdi, [r10 + inputsect.range_list]
	mov [rdi + 12], r11d
	jmp .next_offset_entry
.file_offset:
	mov [r10 + inputsect.filename_offset], r11d
.next_offset_entry:
	add r11d, edx
.next_offset_updated:
	add rsi, 16
	dec ebx
	jnz .calculate_offsets_loop
	mov [zCurrentOutputOffset], r11d

	mov r14, rbp
	mov rsi, r13
	call Allocate
	mov r13, rax
	mov ecx, [zInputCount]
	mov [zRemainingInputCount], ecx
.read_file_loop:
	mov r15, [r12 + inputsect.input_filename]
	mov edi, [r12 + inputsect.file_descriptor]
	mov [zCurrentFD], edi
	mov rsi, [r12 + inputsect.output_filename]
	movzx ecx, word[r12 + inputsect.filename_length]
	mov edi, [r12 + inputsect.filename_offset]
	lea rdi, [r13 + 4 * rdi]
	rep movsb
	xor ecx, ecx
.read_range_loop:
	mov [zCurrentInputIndex], ecx
	shl rcx, 4
	add rcx, [r12 + inputsect.range_list]
	mov r10, [rcx]
	mov eax, 1
	mov ebx, [rcx + 8]
	test ebx, ebx
	cmovs ebx, eax
	mov eax, [r12 + inputsect.block_size]
	imul r10, rax
	imul rbx, rax
	mov ebp, [rcx + 12]
	lea rbp, [r13 + 4 * rbp]
	call ReadDataAtOffset
	mov ecx, [zCurrentInputIndex]
	inc ecx
	cmp ecx, [r12 + inputsect.range_count]
	jc .read_range_loop
	mov edi, [r12 + inputsect.file_descriptor]
	mov eax, close
	syscall
	add r12, inputsect_size
	dec dword[zRemainingInputCount]
	jnz .read_file_loop

	mov edx, [zCurrentOutputOffset]
	mov rbp, [zInputDevices]
	mov ebx, [zInputCount]
.generate_block_list_file_loop:
	mov rsi, [rbp + inputsect.range_list]
	mov r11, rsi
	mov ecx, [rbp + inputsect.range_count]
	mov [rbp + inputsect.block_list_offset], edx
	xor edi, edi
.generate_block_list_range_loop:
	mov eax, [rsi + 8]
	test eax, eax
	jns .generate_run_block_entry
	cmp eax, edi
	jz .generate_next_range
	movsx rdi, eax
	add edx, 2
	jc OutputTooLargeErrorExit
	mov eax, [rsi + 12]
	mov [r13 + 4 * rdx - 4], eax
	mov eax, [rsi + 4]
	mov r9d, eax
	shl eax, 8
	lea r10, [r14 + 4 * rdi]
	mov al, [r10]
	mov [r13 + 4 * rdx - 8], eax
	shl r9, 32
	mov r8, [rsi]
.generate_next_sequence_entry:
	sub r8, r9
	add r9, r8
	mov [r13 + 4 * rdx], r8d
	inc edx
	jz OutputTooLargeErrorExit
	dec al
	jz .generate_next_range
	sub r10, 4
	mov r8d, [r10]
	shl r8, 4
	mov r8, [r11 + r8]
	jmp .generate_next_sequence_entry
.generate_run_block_entry:
	shl eax, 8
	mov [r13 + 4 * rdx], eax
	mov eax, [rsi + 12]
	mov [r13 + 4 * rdx + 4], eax
	mov rax, [rsi]
	mov [r13 + 4 * rdx + 8], rax
	add edx, 4
	jc OutputTooLargeErrorExit
.generate_next_range:
	add rsi, 16
	dec ecx
	jnz .generate_block_list_range_loop
	inc edx ; dword[r13 + 4 * rdx] is already zero
	jz OutputTooLargeErrorExit
	add rbp, inputsect_size
	dec ebx
	jnz .generate_block_list_file_loop

	mov rbp, r13
	mov ecx, [zInputCount]
	lea rdi, [rbp + 4 * rdx]
	lea eax, [ecx + 2 * ecx]
	add edx, eax
	jc OutputTooLargeErrorExit
	mov [rbp + 4 * rdx], ecx
	mov rsi, [zInputDevices]
.file_table_loop:
	mov eax, [rsi + inputsect.filename_offset]
	stosd
	mov ax, [rsi + inputsect.filename_length]
	stosw
	mov eax, [rsi + inputsect.block_size]
	shr eax, 2
	stosw
	mov eax, [rsi + inputsect.block_list_offset]
	stosd
	add rsi, inputsect_size
	dec ecx
	jnz .file_table_loop
	lea rbx, [4 * rdx + 4]
	jmp WriteOutputExit
