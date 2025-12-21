SFDiskMode:
	; The purpose of this mode is to emulate the output of sfdisk -d. That utility performs no validation whatsoever
	; on the filenames it is given: if a filename contains special characters like newlines, those will be printed as
	; part of the device name, breaking the output. (Of course, the tool simply assumes that filenames will be sane.)
	; This mode will therefore operate in the same way and blindly print filenames, even if the output becomes invalid.
	endbr64
	call RejectSizeArguments
	call CheckOpenStandardOutput ; leaves [zCurrentFD] = 1
	call OpenValidateDataFile
	mov r12d, [zInputCount]
	test r12d, r12d
	jnz .specific_filenames
	call LoadAllPartitionTables
	mov [zCurrentBuffer], r12
	mov [zCurrentBufferSize], r12d
	mov r12d, r14d
.all_files_loop:
	call .handle_one_file
	add r15, 8
	add ebx, 3
	dec r12d
	jnz .all_files_loop
	jmp ExitProgram

.specific_filenames:
	call LoadPartitionTablesForFilenames
	mov r14, [zInputFilenames]
	xor eax, eax
	mov [zCurrentBuffer], rax
	mov [zCurrentBufferSize], eax
.specific_files_loop:
	mov ebx, [r14 + 4]
	add r14, 8
	call .handle_one_file
	add r15, 8
	add ebx, 3
	dec r12d
	jnz .specific_files_loop
	jmp ExitProgram

.handle_one_file:
	; in: r15: pointer to partition data, rbp: data file, ebx: file table entry location, r12d: remaining files to print
	mov r13, [r15]
	mov al, [r13 + partitiondata.type]
	movzx esi, word[rbp + 4 * rbx + 4]
	mov dword[zCurrentOutputOffset], 0
	cmp al, 1
	jz .print_MBR_partition_table
	cmp al, 2
	jz .print_GPT_partition_table
	; invalid or unknown partition table: just print the device name and sector size
	add esi, 45
	call ResizeCurrentBuffer
	mov rdi, rax
	call .print_device_header
.write_file_output_no_partitions:
	dec dword[zCurrentOutputOffset]
.write_file_output:
	push rbp
	push rbx
	mov rbp, [zCurrentBuffer]
	mov ebx, [zCurrentOutputOffset]
	lea eax, [ebx + 2]
	mov word[rbp + rbx], `\n\n`
	cmp r12d, 2
	cmovnc ebx, eax
	call WriteData
	pop rbx
	pop rbp
	ret

.print_MBR_partition_table:
	add esi, 77
	call ResizeCurrentBuffer
	mov rdi, rax
	mov esi, SFDiskText.label_dos
	copybytes SFDiskText.label_dos_end - SFDiskText.label_dos
	mov rdx, [r13 + partitiondataMBR.block_table]
	mov edx, [rdx + 12]
	mov eax, [rbp + 4 * rdx + 0x1b8]
	call RenderLowercaseHexWord
	stosq
	mov byte[rdi], `\n`
	inc rdi
	call .print_device_header
	movzx eax, byte[r13 + partitiondataMBR.partition_count_small]
	cmp eax, 5
	jc .loaded_MBR_partition_count
	mov eax, [r13 + partitiondataMBR.partition_count]
.loaded_MBR_partition_count:
	test eax, eax
	jz .write_file_output_no_partitions
	mov r13, [r13 + partitiondataMBR.partition_table]
	mov [zRemainingEntries], eax
	mov edi, [zCurrentOutputOffset]
.MBR_partition_loop:
	movzx esi, word[rbp + 4 * rbx + 4]
	add esi, 71
	add esi, edi
	jc .write_file_output ; failsafe
	call ResizeCurrentBuffer
	movzx eax, byte[r13 + partitionMBR.start_high]
	shl rax, 32
	mov r10d, [r13 + partitionMBR.start]
	add r10, rax
	mov r11d, [r13 + partitionMBR.length]
	mov eax, [r13 + partitionMBR.number]
	call .print_partition_header
	mov al, [r13 + partitionMBR.type]
	mov ah, al
	shr ah, 4
	jz .skip_MBR_partition_type_first_digit
	cmp ah, 10
	sbb cl, cl
	and cl, "0" - ("a" - 10)
	add ah, "a" - 10
	add cl, ah
	mov [rdi], cl
	and al, 15
	inc rdi
.skip_MBR_partition_type_first_digit:
	cmp al, 10
	sbb cl, cl
	and cl, "0" - ("a" - 10)
	add al, "a" - 10
	add al, cl
	stosb
	mov rax, rdi
	mov esi, SFDiskText.bootable
	copybytes SFDiskText.bootable_end - SFDiskText.bootable
	test byte[r13 + partitionMBR.entry_flags], 0x80
	cmovz rdi, rax
	mov byte[rdi], `\n`
	inc rdi
	sub rdi, [zCurrentBuffer]
	mov [zCurrentOutputOffset], edi
	add r13, partitionMBR_size
	dec dword[zRemainingEntries]
	jnz .MBR_partition_loop
	jmp .write_file_output

.print_GPT_partition_table:
	add esi, 166
	call ResizeCurrentBuffer
	mov rdi, rax
	mov esi, SFDiskText.label_gpt
	copybytes SFDiskText.label_gpt_end - SFDiskText.label_gpt
	movzx eax, byte[r13 + partitiondataGPT.selected_table_header]
	mov eax, [r13 + 4 * rax + partitiondataGPT.table_header_locations]
	lea r10, [rbp + 4 * rax]
	lea rsi, [r10 + 56]
	call LoadRenderGUID
	mov byte[rdi + 36], `\n`
	add rdi, 37
	call .print_device_header
	dec edi
	add rdi, [zCurrentBuffer]
	mov esi, SFDiskText.first_lba
	copybytes SFDiskText.first_lba_end - SFDiskText.first_lba
	mov rax, [r10 + 40]
	call WriteNumberToBuffer
	mov esi, SFDiskText.last_lba
	copybytes SFDiskText.last_lba_end - SFDiskText.last_lba
	mov rax, [r10 + 48]
	call WriteNumberToBuffer
	mov word[rdi], `\n\n`
	sub rdi, [zCurrentBuffer]
	add edi, 2
	mov [zCurrentOutputOffset], edi
	mov eax, [r13 + partitiondataGPT.partition_count]
	test eax, eax
	jz .write_file_output_no_partitions
	mov [zRemainingEntries], eax
	mov r13, [r13 + partitiondataGPT.partition_table]
.GPT_partition_loop:
	movzx esi, word[rbp + 4 * rbx + 4]
	add esi, 713
	add esi, edi
	jc .write_file_output ; failsafe
	call ResizeCurrentBuffer
	mov eax, [r13 + partitionGPT.number]
	mov esi, [r13 + partitionGPT.location]
	mov r10, [rbp + 4 * rsi + 32]
	mov r11, [rbp + 4 * rsi + 40]
	sub r11, r10
	inc r11
	call .print_partition_header
	mov esi, [r13 + partitionGPT.location]
	lea rsi, [rbp + 4 * rsi]
	mov r10, rsi
	call LoadRenderGUID
	mov rax, ", uuid="
	mov [rdi + 36], rax
	add rdi, 43
	add rsi, 16
	call LoadRenderGUID
	add rdi, 36
	add rsi, 40
	cmp word[rsi], 0
	jz .skip_GPT_partition_name
	mov rax, ', name="'
	stosq
	mov cl, 36
	mov byte[zUnicodeSurrogatePair], 0
.GPT_partition_name_loop:
	lodsw
	movzx eax, ax
	test eax, eax
	jz .finish_GPT_partition_name
	cmp eax, 0x20
	jc .GPT_partition_name_single_character_escape
	cmp eax, '"'
	jz .GPT_partition_name_single_character_escape
	cmp eax, "\"
	jz .GPT_partition_name_single_character_escape
	cmp eax, 0x7f
	jz .GPT_partition_name_single_character_escape
	jc .GPT_partition_name_unescaped_character
	call CheckUnpairedUTF16Surrogate ; actually to find paired ones
	xor ch, ch
	xchg ch, [zUnicodeSurrogatePair] ; always 0 or 1
	test ch, ch
	jz .GPT_partition_name_no_surrogate_pair
	shl eax, 10
	movzx edx, word[rsi]
	add rsi, 2
	dec cl
	add eax, edx
	sub eax, 0x35fdc00
.GPT_partition_name_no_surrogate_pair:
	cmp eax, 0x800
	sbb ch, -2
	mov r8d, eax
	mov r9b, cl
	mov cl, ch
	mov dl, 0x80
	shr dl, cl
	shl cl, 2
	add cl, ch
	add cl, ch
	neg dl
.GPT_partition_name_multichar_loop:
	shr eax, cl
	and al, 0x3f
	add al, dl
	call .print_character_escape
	mov dl, 0x80
	mov eax, r8d
	sub cl, 6
	dec ch
	jnz .GPT_partition_name_multichar_loop
	mov cl, r9b
	and al, 0x3f
	add al, dl
.GPT_partition_name_single_character_escape:
	call .print_character_escape
	jmp .GPT_partition_name_next_character
.GPT_partition_name_unescaped_character:
	stosb
.GPT_partition_name_next_character:
	dec cl
	jnz .GPT_partition_name_loop
.finish_GPT_partition_name:
	mov byte[rdi], '"'
	inc rdi
.skip_GPT_partition_name:
	mov r10, [r10 + 48]
	test r10, r10
	jz .no_GPT_partition_attributes
	mov esi, SFDiskText.attrs
	copybytes SFDiskText.attrs_end - SFDiskText.attrs
	test r10b, 1
	jz .GPT_partition_skip_required_attribute
	mov esi, SFDiskText.required_partition
	copybytes SFDiskText.required_partition_end - SFDiskText.required_partition
.GPT_partition_skip_required_attribute:
	test r10b, 2
	jz .GPT_partition_skip_no_block_IO_attribute
	mov esi, SFDiskText.no_block_IO
	copybytes SFDiskText.no_block_IO_end - SFDiskText.no_block_IO
.GPT_partition_skip_no_block_IO_attribute:
	test r10b, 4
	jz .GPT_partition_skip_legacy_bootable_attribute
	mov esi, SFDiskText.legacy_bootable
	copybytes SFDiskText.legacy_bootable_end - SFDiskText.legacy_bootable
.GPT_partition_skip_legacy_bootable_attribute:
	shr r10, 48
	mov ecx, r10d
	test ecx, ecx
	jz .done_GPT_partition_attributes
	mov rax, "GUID:"
	mov [rdi], rax
	add rdi, 5
	mov dl, 10
.GPT_partition_type_specific_attribute_loop:
	bsf eax, ecx
	btr ecx, eax
	add eax, 48
	div dl
	add eax, "00,"
	mov [rdi], eax
	add rdi, 3
	test ecx, ecx
	jnz .GPT_partition_type_specific_attribute_loop
.done_GPT_partition_attributes:
	mov byte[rdi - 1], '"'
.no_GPT_partition_attributes:
	mov byte[rdi], `\n`
	sub rdi, [zCurrentBuffer]
	inc edi
	mov [zCurrentOutputOffset], edi
	add r13, partitionGPT_size
	dec dword[zRemainingEntries]
	jnz .GPT_partition_loop
	jmp .write_file_output

.print_device_header:
	mov rax, "device: "
	stosq
	movzx ecx, word[rbp + 4 * rbx + 4]
	mov esi, [rbp + 4 * rbx]
	lea rsi, [rbp + 4 * rsi]
	rep movsb
	mov esi, SFDiskText.sector_size_header
	copybytes SFDiskText.sector_size_header_end - SFDiskText.sector_size_header
	movzx eax, word[rbp + 4 * rbx + 6]
	dec ax
	inc eax
	shl eax, 2
	call WriteNumberToBuffer
	mov word[rdi], `\n\n`
	sub rdi, [zCurrentBuffer]
	add edi, 2
	mov [zCurrentOutputOffset], edi
	ret

.print_partition_header:
	mov edi, [zCurrentOutputOffset]
	add rdi, [zCurrentBuffer]
	movzx ecx, word[rbp + 4 * rbx + 4]
	mov esi, [rbp + 4 * rbx]
	lea rsi, [rbp + 4 * rsi]
	rep movsb
	mov cl, [rdi - 1]
	sub cl, "0"
	cmp cl, 10
	mov byte[rdi], "p"
	adc rdi, 0
	call WriteNumberToBuffer
	mov esi, SFDiskText.colon_start_equals
	copybytes SFDiskText.colon_start_equals_end - SFDiskText.colon_start_equals
	mov rax, r10
	call NumberLength
	mov esi, 12
	cmp ecx, esi
	cmovc ecx, esi
	lea r10, [rdi + rcx + 7]
	call PrintNumber
	mov rax, ", size="
	mov [r10 - 7], rax
	mov rdi, r10
	mov rax, r11
	call NumberLength
	mov esi, 12
	cmp ecx, esi
	cmovc ecx, esi
	lea r10, [rdi + rcx + 7]
	call PrintNumber
	mov rax, ", type="
	mov [r10 - 7], rax
	mov rdi, r10
	ret

.print_character_escape:
	mov ah, al
	shr al, 4
	and ah, 15
	cmp al, 10
	cmc
	sbb dl, dl
	cmp ah, 10
	cmc
	sbb dh, dh
	add ax, 0x3030
	and dx, 0x2727
	add ax, dx
	shl eax, 16
	mov ax, "\x"
	stosd
	ret
