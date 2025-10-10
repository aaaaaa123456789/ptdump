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
	mov ebp, zStringBuffer
	test r15, r15
	cmovz r15, rbp
	jnz .no_copy_stdin_filename
	mov esi, MiscStrings.stdin
	mov edi, zStringBuffer
	copybytes MiscStrings.stdin_end - MiscStrings.stdin
.no_copy_stdin_filename:
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

LoadEffectiveBlockList:
	; in: OpenValidateDataFile's outputs, edi = index; in/out: r15: common buffer or null; out: rsi = table (block number, count, location), edi = count
	; also sets [zCurrentBlockSize] to the logical file's block size
	push rbx
	push rbp
	lea edi, [edi + 2 * edi]
	add ebx, edi
	mov ax, [rbp + 4 * rbx + 6]
	dec ax
	movzx eax, ax
	inc eax
	mov [zCurrentBlockSize], eax
	mov esi, [rbp + 4 * rbx + 8]
	mov ebx, esi
	xor ecx, ecx
.counting_loop:
	mov dl, [rbp + 4 * rsi]
	test dl, dl
	setz dh
	add dl, dh
	add dh, dl
	movzx eax, dh
	movzx edx, dl
	lea esi, [esi + eax + 2]
	add ecx, edx
	cmp dword[rbp + 4 * rsi], 0
	jnz .counting_loop
	shl ecx, 5
	test r15, r15
	jz .allocate
	cmp ecx, 0x1000
	jnc .allocate
	mov ax, 0xf000
	or ax, r15w
	add ax, cx
	cmc
	ja .allocate
	mov rax, r15
	jmp .fix_common_buffer
.allocate:
	push rcx
	mov esi, ecx
	call Allocate
	pop rcx
	test cx, 0xff8
	jz .allocated
.fix_common_buffer:
	lea r15, [rax + rcx]
	mov ecx, 0xff8
	and rcx, r15
	cmovz r15, rcx
.allocated:
	mov rdi, rax

	mov edx, [rbp + 4 * rbx]
.write_loop:
	inc ebx
	test dl, dl
	jnz .sequence_block
	shr edx, 8
	mov [rdi + 8], edx
	mov [rdi + 12], ebx
	mov rdx, [rbp + 4 * rbx + 4]
	mov [rdi], rdx
	add ebx, 3
	add rdi, 16
	jmp .next_block
.sequence_block:
	mov r11d, edx
	shr r11d, 8
	shl r11, 32
	mov esi, ebx
	xor dh, dh
	inc ebx
.sequence_loop:
	mov ecx, [rbp + 4 * rbx]
	inc ebx
	add r11, rcx
	mov [rdi], r11
	mov dword[rdi + 8], 1
	mov [rdi + 11], dh
	inc dh
	mov [rdi + 12], esi
	add rdi, 16
	dec dl
	jnz .sequence_loop
.next_block:
	mov edx, [rbp + 4 * rbx]
	test edx, edx
	jnz .write_loop
	mov rbp, rax
	sub rdi, rax
	shr rdi, 4
	mov ebx, edi
	call SortPairs
	mov edi, [zCurrentBlockSize]
	mov ecx, ebx
	mov rsi, rbp
	mov r11, [rsp]
.fixup_loop:
	movzx eax, byte[rsi + 11]
	mov edx, [rsi + 12]
	test al, al
	jz .no_offset_fixup
	; slight optimization because zero will be a very common value
	imul eax, edi
	mov byte[rsi + 11], 0
.no_offset_fixup:
	add eax, [r11 + 4 * rdx]
	mov [rsi + 12], eax
	add rsi, 16
	dec ecx
	jnz .fixup_loop

	shl rbx, 4
	lea r9, [rbp + rbx - 16]
	mov r8, rbp
	cmp rbp, r9
	jz .done
	mov edx, [zCurrentBlockSize]
.deduplication_loop:
	mov eax, [rbp + 8]
	add rax, [rbp]
	mov r11, [rbp + 16]
	cmp rax, r11
	jbe .next_entry
	mov ebx, [rbp + 24]
	add rbx, r11
	sub rax, rbx
	jbe .no_insert
	mov rcx, rbx
	sub rcx, [rbp]
	imul ecx, edx
	add ecx, [rbp + 12]
	shl rcx, 32
	add rax, rcx
	lea r10, [rbp + 32]
	cmp r10, r9
	ja .found_insertion_point
.insertion_point_loop:
	cmp rbx, [r10]
	jbe .found_insertion_point
	add r10, 16
	cmp r10, r9
	jbe .insertion_point_loop
.found_insertion_point:
	lea rcx, [r9 + 16]
	sub rcx, r10
	jz .insert_at_end
	shr rcx, 3
	lea rdi, [r9 + 24]
	lea rsi, [r9 + 8]
	std
	rep movsq
	cld
.insert_at_end:
	mov [r10], rbx
	mov [r10 + 8], rax
	add r9, 16
.no_insert:
	sub r11, [rbp]
	mov [rbp + 8], r11d
	jnz .next_entry
	mov rcx, r9
	sub rcx, rbp
	shr rcx, 3
	lea rsi, [rbp + 16]
	mov rdi, rbp
	rep movsq
	sub rbp, 16
	sub r9, 16
.next_entry:
	add rbp, 16
	cmp rbp, r9
	jc .deduplication_loop

	sub r9, r8
	shr r9, 4
	mov ecx, r9d
	mov r9, r8
	mov rsi, r8
	mov rbp, [r8]
.merge_loop:
	add rsi, 16
	mov eax, [r9 + 8]
	lea rbx, [rbp + rax]
	mov rbp, [rsi]
	cmp rbx, rbp
	jnz .no_merge
	imul eax, edx
	add eax, [r9 + 12]
	cmp eax, [rsi + 12]
	jnz .no_merge
	mov eax, [rsi + 8]
	add [r9 + 8], eax
	jmp .merge_next
.no_merge:
	add r9, 16
	mov [r9], rbp
	mov rax, [rsi + 8]
	mov [r9 + 8], rax
.merge_next:
	dec ecx
	jnz .merge_loop
.done:
	shl edx, 2
	mov [zCurrentBlockSize], edx
	pop rbp
	pop rbx
	mov rsi, r8
	lea rdi, [r9 + 16]
	sub rdi, rsi
	shr rdi, 4
	ret

FindBlockTableEntry:
	; in: rsi: table, edi: count, rdx: block number; out: rdx: table entry or null; preserves rsi, rdi, r10, r11
	lea r9d, [edi - 1]
	xor r8d, r8d
	shl r9, 4
.loop:
	lea rcx, [r8 + r9]
	shr rcx, 1
	and rcx, -16
	cmp rdx, [rsi + rcx]
	jnc .not_below
	test rcx, rcx
	jz .not_found
	lea r9, [rcx - 16]
.next:
	cmp r8, r9
	jbe .loop
.not_found:
	xor edx, edx
	ret

.not_below:
	mov eax, [rsi + rcx + 8]
	add rax, [rsi + rcx]
	cmp rdx, rax
	lea r8, [rcx + 16]
	jnc .next
	lea rdx, [rsi + rcx]
	ret
