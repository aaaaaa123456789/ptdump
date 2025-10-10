LoadPartitionTablesForFile:
	; in: rbp = data file contents, ebx = file table offset, edi = file number; in/out: r15: common buffer or null; out: [zCurrentPartitionTable]
	; assumes [zCurrentBuffer] and [zCurrentBufferSize] are either zeroed or initialized
	assert partitiondata_size <= 64
	assert partitiondataMBR_size <= 64
	assert partitiondataGPT_size == 64
	test r15, r15
	jz .allocate_table
	mov ax, r15w
	or ax, 0xf000
	cmp ax, -64
	ja .allocate_table
	mov [zCurrentPartitionTable], r15
	add r15, 64
	mov eax, 0xff8
	and eax, r15d
	cmovz r15, rax
	jmp .got_table_location
.allocate_table:
	push rdi
	mov esi, 0x1000
	call AllocateAligned
	mov [zCurrentPartitionTable], rax
	lea r15, [rax + 64]
	pop rdi
.got_table_location:
	call LoadEffectiveBlockList
	mov rdx, [zCurrentPartitionTable]
	mov [rdx + partitiondata.block_table], rsi
	mov [rdx + partitiondata.block_table_entries], edi
	cmp dword[zCurrentBlockSize], 512
	jc .done
	cmp qword[rsi], 0
	jnz .done
	mov eax, [rsi + 12]
	lea rax, [rbp + 4 * rax]
	mov ecx, [zCurrentBlockSize]
	lea r10, [rax + rcx]
	cmp dword[rsi + 8], 2
	jnc .got_first_locations
	cmp edi, 2
	jc .only_zero
	cmp qword[rsi + 16], 1
	jnz .only_zero
	mov r10d, [rsi + 28]
	lea r10, [rbp + 4 * r10]
.got_first_locations:
	mov rdi, rax
	mov esi, ecx
	call GetPartitionTableTypeFromBlocks
	test al, al
	jz .done
	mov rdx, [zCurrentPartitionTable]
	mov [rdx + partitiondata.type], al
	cmp al, 1
	jz .loadMBR

	mov [rdx + partitiondataGPT.partition_table], rsp ; just using it as a placeholder
	mov eax, 1
	call ValidateGPTTableHeader
	cmp al, 4
	jnc .no_first_GPT_header
	mov rdi, r10
	sub rdi, rbp
	shr rdi, 2
	push rdi
	push 1
	mov [rsp + 12], al
.no_first_GPT_header:
	mov rdx, [r10 + 32]
	mov r10, rdx
	cmp rdx, 2
	jc .done_alternate_GPT_header
	mov rax, [zCurrentPartitionTable]
	mov rsi, [rax + partitiondataGPT.block_table]
	mov edi, [rax + partitiondataGPT.block_table_entries]
	call FindBlockTableEntry
	test rdx, rdx
	jz .done_alternate_GPT_header
	mov rax, r10
	sub r10d, [rdx]
	jz .alternate_GPT_header_at_start
	mov edi, [zCurrentBlockSize]
	shr edi, 2
	imul r10d, edi
.alternate_GPT_header_at_start:
	add r10d, [rdx + 12]
	push r10
	lea r10, [rbp + 4 * r10]
	push rax
	call ValidateGPTTableHeader
	mov [rsp + 12], al
	cmp al, 4
	mov r10, [rsp]
	jc .done_alternate_GPT_header
	add rsp, 16
.done_alternate_GPT_header:
	mov rdx, [zCurrentPartitionTable]
	mov rsi, [rdx + partitiondataGPT.block_table]
	mov edi, [rdx + partitiondataGPT.block_table_entries]
	shl rdi, 4
	mov rax, [rsi + rdi - 16]
	mov edx, [rsi + rdi - 8]
	dec edx
	mov edi, [rsi + rdi - 4]
	jz .last_block_at_start
	add rax, rdx
	mov esi, [zCurrentBlockSize]
	shr esi, 2
	imul esi, edx
	add edi, esi
.last_block_at_start:
	cmp rax, r10
	jz .done_last_GPT_header
	cmp rax, 2
	jc .done_last_GPT_header
	lea r10, [rbp + 4 * rdi]
	push rdi
	push rax
	call ValidateGPTTableHeader
	mov [rsp + 12], al
	cmp al, 4
	jc .done_last_GPT_header
	add rsp, 16
.done_last_GPT_header:
	mov rdx, [zCurrentPartitionTable]
	mov rax, [rdx + partitiondataGPT.partition_table]
	sub rax, rsp
	jz .invalid
	shr eax, 4
	mov [rdx + partitiondataGPT.table_header_count], al
	xor ecx, ecx
	xor edi, edi
.select_GPT_table_loop:
	cmp byte[rsp + rdi + 12], 3
	cmovc ecx, eax
	add edi, 16
	dec eax
	jnz .select_GPT_table_loop
	dec ecx
	mov [rdx + partitiondataGPT.selected_table_header], cl
	movzx esi, byte[rdx + partitiondataGPT.table_header_count]
	mov ax, 0x200 ; al = 0 for ORing; ah = 2 for after the loop
.load_tables_from_stack_loop:
	pop rcx
	mov [rdx + 8 * rsi + partitiondataGPT.table_header_blocks - 8], rcx
	pop rcx
	mov [rdx + 4 * rsi + partitiondataGPT.table_header_locations - 4], ecx
	shr rcx, 32
	and cl, 3
	or al, cl
	dec esi
	jnz .load_tables_from_stack_loop
	mov cl, byte[rdx + partitiondataGPT.selected_table_header]
	shl cl, 1
	jc .invalid
	shl ah, cl
	or al, ah
	mov [rdx + partitiondataGPT.table_header_flags], al

	cmp byte[rdx + partitiondataGPT.table_header_count], 2
	jc .load_selected_GPT_table
	test cl, cl
	jnz .skip_primary_GPT_table
	test byte[rdx + partitiondataGPT.table_header_flags], 8
	jnz .skip_primary_GPT_table
	mov eax, [rdx + partitiondataGPT.table_header_locations]
	mov ecx, [rdx + partitiondataGPT.table_header_locations + 4]
	call CompareGPTTables
	jnz .skip_primary_GPT_table
	or byte[rdx + partitiondataGPT.table_header_flags], 4
.skip_primary_GPT_table:
	cmp byte[rdx + partitiondataGPT.table_header_count], 3
	jc .load_selected_GPT_table
	test byte[rdx + partitiondataGPT.table_header_flags], 32 ; tests both selected and invalid
	jnz .load_selected_GPT_table
	movzx ecx, byte[rdx + partitiondataGPT.selected_table_header]
	mov eax, [rdx + 4 * rcx + partitiondataGPT.table_header_locations]
	mov ecx, [rdx + partitiondataGPT.table_header_locations + 8]
	call CompareGPTTables
	jnz .load_selected_GPT_table
	or byte[rdx + partitiondataGPT.table_header_flags], 16

.load_selected_GPT_table:
	movzx esi, byte[rdx + partitiondataGPT.selected_table_header]
	mov esi, [rdx + 4 * rsi + partitiondataGPT.table_header_locations]
	lea rsi, [rbp + 4 * rsi]
	push rsi
	mov esi, [rsi + 80]
	shl esi, 2
	call ResizeCurrentBuffer
	pop r10
	mov r11, [zCurrentPartitionTable]
	mov rsi, [r11 + partitiondataGPT.block_table]
	mov edi, [r11 + partitiondataGPT.block_table_entries]
	mov rdx, [r10 + 72]
	call FindBlockTableEntry
	mov r8d, [r10 + 84]
	shr r8d, 2
	mov r9d, [zCurrentBlockSize]
	shr r9d, 2
	mov rax, [r10 + 72]
	sub rax, [rdx]
	mov ecx, [rdx + 8]
	jz .selected_GPT_table_at_start
	sub ecx, eax
	imul eax, r9d
.selected_GPT_table_at_start:
	add eax, [rdx + 12]
	imul ecx, r9d
	mov rdi, [zCurrentBuffer]
	mov esi, [r10 + 80]
.load_GPT_partition_location_loop:
	test ecx, ecx
	jnz .skip_GPT_partition_location_reload
	add rdx, 16
	mov ecx, [rdx + 8]
	mov eax, [rdx + 12]
	imul ecx, r9d
.skip_GPT_partition_location_reload:
	stosd
	add eax, r8d
	sub ecx, r8d
	dec esi
	jnz .load_GPT_partition_location_loop
	xor ecx, ecx
	mov edx, [r10 + 80]
	mov r11, [zCurrentPartitionTable]
	mov [r11 + partitiondataGPT.partition_table], edx ; placeholder
	mov rsi, [zCurrentBuffer]
.count_GPT_partitions_loop:
	; consider a GPT partition as empty if starting sector = 0 or ending sector < starting sector
	lodsd
	mov rdi, [rbp + 4 * rax + 32]
	test rdi, rdi
	jz .count_next_GPT_partition
	cmp rdi, [rbp + 4 * rax + 40]
	ja .count_next_GPT_partition
	inc ecx
.count_next_GPT_partition:
	dec edx
	jnz .count_GPT_partitions_loop
	mov [r11 + partitiondataGPT.partition_count], ecx
	assert partitionGPT_size == 8
	shl ecx, 3
	cmp ecx, 0x1000
	jnc .allocate_GPT_partition_table
	mov ax, 0xf000
	or ax, r15w
	add ax, cx
	cmc
	ja .allocate_GPT_partition_table
	mov rax, r15
	xor r15d, r15d
	jmp .allocated_GPT_partition_table
.allocate_GPT_partition_table:
	push rcx
	mov esi, ecx
	call Allocate
	pop rcx
.allocated_GPT_partition_table:
	mov rdi, rax
	add rax, rcx
	add rax, r15
	test ax, 0xff8
	cmovnz r15, rax
	mov rdx, [zCurrentPartitionTable]
	mov ecx, [rdx + partitiondataGPT.partition_table]
	mov [rdx + partitiondataGPT.partition_table], rdi
	mov rsi, [zCurrentBuffer]
	mov edx, 1 ; purposely off by one
.load_GPT_partition_table_loop:
	mov eax, [rsi + 4 * rdx - 4]
	mov r8, [rbp + 4 * rax + 32]
	test r8, r8
	jz .skip_GPT_partition
	cmp r8, [rbp + 4 * rax + 40]
	ja .skip_GPT_partition
	assert partitionGPT_size == 8
	assert partitionGPT.number == 0
	assert partitionGPT.location == 4
	shl rax, 32
	or rax, rdx
	stosq
.skip_GPT_partition:
	inc edx
	cmp edx, ecx
	jbe .load_GPT_partition_table_loop
	ret

.only_zero:
	cmp word[rax + 0x1fe], 0xaa55
	jnz .done
	mov byte[rdx + partitiondata.type], 1
	mov rdi, rax
.loadMBR:
	xor dl, dl
	mov ecx, 0x30
.check_extended_partitions_loop:
	shl dl, 1
	cmp dword[rdi + rcx + 0x1ca], 0
	jz .skip_check_extended_partitions
	cmp dword[rdi + rcx + 0x1c6], 0
	jz .skip_check_extended_partitions
	mov al, [rdi + rcx + 0x1c2]
	call IsExtendedPartitionCode
	or dl, al
.skip_check_extended_partitions:
	sub ecx, 0x10
	jnc .check_extended_partitions_loop
	shl dl, 4
	mov rsi, [zCurrentPartitionTable]
	mov [rsi + partitiondataMBR.partition_count_small], dl
	jnz .load_MBR_with_extended_partitions

	test r15, r15
	jz .allocate_small_MBR_partition_buffer
	mov ax, 0xf000
	or ax, r15w
	cmp ax, -4 * partitionMBR_size
	jbe .got_small_MBR_partition_buffer
.allocate_small_MBR_partition_buffer:
	mov esi, 0x1000
	call AllocateAligned
	mov r15, rax
.got_small_MBR_partition_buffer:
	mov rdx, [zCurrentPartitionTable]
	mov [rdx + partitiondataMBR.partition_table], r15
	mov rsi, r15
	add r15, 4 * partitionMBR_size
	mov eax, 0xff8
	and rax, r15
	cmovz r15, rax
.load_MBR_base_partitions:
	mov rdx, [rdx + partitiondataMBR.block_table]
	mov edi, [rdx + 12]
	mov r9d, edi
	lea rdi, [rbp + 4 * rdi]
	xor ecx, ecx
	mov edx, 0x1be
.small_MBR_partition_loop:
	mov eax, [rdi + rdx + 8]
	test eax, eax
	jz .next_small_MBR_partition
	mov r8d, [rdi + rdx + 12]
	test r8d, r8d
	jz .next_small_MBR_partition
	mov [rsi + partitionMBR.start], eax
	mov [rsi + partitionMBR.length], r8d
	mov [rsi + partitionMBR.entry_flags], cl
	mov al, cl
	inc al
	mov [rsi + partitionMBR.number], al
	mov al, [rdi + rdx + 4]
	mov [rsi + partitionMBR.type], al
	mov al, 0x80
	and al, [rdi + rdx]
	or [rsi + partitionMBR.entry_flags], al
	mov [rsi + partitionMBR.table_location], r9d
	inc ch
	add rsi, partitionMBR_size
.next_small_MBR_partition:
	add edx, 0x10
	inc cl
	cmp cl, 4
	jnz .small_MBR_partition_loop
	mov rdx, [zCurrentPartitionTable]
	or [rdx + partitiondataMBR.partition_count_small], ch
	ret

.invalid:
	mov rdx, [zCurrentPartitionTable]
	mov byte[rdx + partitiondata.type], 0xff
.done:
	ret

.load_MBR_with_extended_partitions:
	xor esi, esi
	mov [zCurrentBufferOffset], esi
	xor cl, cl
.extended_partition_table_loop:
	mov [zPartitionEntryIndex], cl
	mov rdx, [zCurrentPartitionTable]
	mov rsi, [rdx + partitiondataMBR.block_table]
	mov esi, [rsi + 12]
	lea rsi, [rbp + 4 * rsi]
	mov dl, [rdx + partitiondataMBR.partition_count_small]
	shr dl, cl
	test dl, 0x10
	jz .check_next_MBR_entry
	movzx edx, cl
	shl edx, 4
	lea rsi, [rsi + rdx + 0x1c6]
	push rsi
	mov esi, [zCurrentBufferOffset]
	add esi, extendedtable_size
	call ResizeCurrentBuffer
	pop rsi
	mov edx, [zCurrentBufferOffset]
	add rax, rdx
	add edx, extendedtable_size
	mov [zCurrentBufferOffset], edx
	mov edx, [rsi + 4]
	mov [zExtendedPartitionSize], edx
	mov dl, [zPartitionEntryIndex]
	mov [rax + extendedtable.parent_entry], dl
	xor edx, edx
	mov [rax + extendedtable.parent], edx
	assert extendedtable.parent_high == extendedtable.block_high + 1
	mov [rax + extendedtable.block_high], dx
	mov edx, [rsi]
	mov [rax + extendedtable.block], edx
	mov [zExtendedPartitionStart], edx
	mov rsi, [zCurrentPartitionTable]
	mov edi, [rsi + partitiondataMBR.block_table_entries]
	mov rsi, [rsi + partitiondataMBR.block_table]
	push rax
	call FindBlockTableEntry
	pop rax
	test rdx, rdx
	jz .invalid
	mov edi, [rax + extendedtable.block]
.next_extended_partition_table_link:
	sub edi, [rdx]
	jz .extended_table_at_start
	mov esi, [zCurrentBlockSize]
	shr esi, 2
	imul edi, esi
.extended_table_at_start:
	add edi, [rdx + 12]
	mov [rax + extendedtable.location], edi
	lea rsi, [rbp + 4 * rdi]
	mov byte[rax + extendedtable.next], 0xff
	mov r11, rax
	mov edx, 0x1f6
.find_next_extended_table_loop:
	cmp dword[rsi + rdx + 4], 0
	jz .check_next_extended_table_entry
	mov edi, [rsi + rdx]
	cmp edi, [zExtendedPartitionSize]
	jnc .check_next_extended_table_entry
	mov al, [rsi + rdx - 4]
	call IsExtendedPartitionCode
	jz .check_next_extended_table_entry
	mov al, dl
	sub al, 0xc6
	shr al, 4
	mov [r11 + extendedtable.next], al
.check_next_extended_table_entry:
	sub edx, 0x10
	cmp dl, 0xc6
	jnc .find_next_extended_table_loop
	movzx eax, byte[r11 + extendedtable.next]
	cmp eax, 4
	jnc .check_next_MBR_entry
	shl eax, 4
	mov eax, [rsi + rax + 0x1c6]
	add eax, [zExtendedPartitionStart]
	setc dl
	mov ecx, [zCurrentBufferOffset]
	mov rdi, [zCurrentBuffer]
.check_extended_cycle_loop:
	cmp eax, [rdi + rcx - extendedtable_size + extendedtable.block]
	jnz .check_extended_cycle_next
	cmp dl, [rdi + rcx - extendedtable_size + extendedtable.block_high]
	jz .invalid
.check_extended_cycle_next:
	sub ecx, extendedtable_size
	jnz .check_extended_cycle_loop
	movzx edx, dl
	shl rdx, 32
	add rdx, rax
	sub r11, [zCurrentBuffer]
	mov r10, rdx
	mov rsi, [zCurrentPartitionTable]
	mov edi, [rsi + partitiondataMBR.block_table_entries]
	mov rsi, [rsi + partitiondataMBR.block_table]
	call FindBlockTableEntry
	test rdx, rdx
	jz .invalid
	push rdx
	push r10
	push r11
	mov esi, [zCurrentBufferOffset]
	add esi, extendedtable_size
	call ResizeCurrentBuffer
	pop r11
	add r11, rax
	mov edx, [zCurrentBufferOffset]
	add rax, rdx
	add edx, extendedtable_size
	mov [zCurrentBufferOffset], edx
	mov cl, [rsp + 4]
	pop r10
	pop rdx
	mov [rax + extendedtable.block], r10d
	mov [rax + extendedtable.block_high], cl
	mov ecx, [r11 + extendedtable.block]
	mov [rax + extendedtable.parent], ecx
	mov cl, [r11 + extendedtable.block_high]
	mov [rax + extendedtable.parent_high], cl
	mov cl, [r11 + extendedtable.next]
	mov [rax + extendedtable.parent_entry], cl
	mov edi, r10d
	jmp .next_extended_partition_table_link
.check_next_MBR_entry:
	mov cl, [zPartitionEntryIndex]
	inc cl
	cmp cl, 4
	jc .extended_partition_table_loop

	; reserve enough space for 3 child partitions for each extended table entry, plus one extra for the whole list
	; also reserve space for the 4 partitions that could exist in the MBR itself
	mov rdx, [zCurrentPartitionTable]
	movzx eax, byte[rdx + partitiondataMBR.partition_count_small]
	shr al, 4
	%rep 4
		; ah = 4 + number of extended partitions in the MBR
		shr al, 1
		adc ah, 1
	%endrep
	assert partitionMBR_size == 24
	shl ah, 4
	movzx ecx, ah
	assert extendedtable_size == 16
	mov eax, [zCurrentBufferOffset]
	lea ecx, [ecx + 2 * ecx]
	add ecx, eax
	lea esi, [eax + 4 * eax]
	shr ecx, 1
	add esi, ecx
	test r15, r15
	jz .allocate_MBR_partition_table
	cmp esi, 0x1000
	jnc .allocate_MBR_partition_table
	mov eax, 0xf000
	or ax, r15w
	add ax, si
	cmc
	xchg rax, r15 ; r15 = 0 if there's no slack, irrelevant otherwise (will be overwritten)
	jbe .got_MBR_partition_table_address
.allocate_MBR_partition_table:
	push rsi
	call Allocate
	pop rsi
.got_MBR_partition_table_address:
	add rsi, rax
	test si, 0xff8
	cmovnz r15, rsi
	mov rdi, rax
	mov rdx, [zCurrentPartitionTable]
	mov rsi, [zCurrentBuffer]
	mov ecx, [zCurrentBufferOffset]
	mov [rdx + partitiondataMBR.extended_tables], rax
	shr ecx, 4
	mov [rdx + partitiondataMBR.extended_count], ecx
	shl ecx, 1
	rep movsq
	mov [rdx + partitiondataMBR.partition_table], rdi
	mov rsi, rdi
	call .load_MBR_base_partitions ; exits with ch = loaded count, rsi = end of loaded partitions
	mov [rdx + partitiondataMBR.partition_count], ch
	mov edi, [rdx + partitiondataMBR.extended_count]
	mov [zRemainingInputCount], edi
	mov dword[zCurrentInputIndex], 5
	mov rdi, [rdx + partitiondataMBR.extended_tables]
.load_extended_partitions_loop:
	cmp dword[rdi + extendedtable.parent], 0
	jnz .skip_extended_partition_parameters
	cmp byte[rdi + extendedtable.parent_high], 0
	jnz .skip_extended_partition_parameters
	mov rax, [rdx + partitiondataMBR.block_table]
	mov eax, [rax + 12]
	lea rax, [rbp + 4 * rax + 0x1c6]
	movzx ecx, byte[rdi + extendedtable.parent_entry]
	shl ecx, 4
	add rax, rcx
	mov ecx, [rax]
	mov [zExtendedPartitionStart], ecx
	mov ecx, [rax + 4]
	mov [zExtendedPartitionSize], ecx
	mov r10d, ecx
.skip_extended_partition_parameters:
	mov eax, [rdi + extendedtable.location]
	lea r11, [rbp + 4 * rax + 0x1c6]
	xor cl, cl
.extended_partition_entry_loop:
	cmp cl, [rdi + extendedtable.next]
	jz .next_extended_partition_entry
	mov eax, [r11]
	test eax, eax
	jz .next_extended_partition_entry
	cmp eax, r10d
	jnc .next_extended_partition_entry
	mov r8d, [r11 + 4]
	test r8d, r8d
	jz .next_extended_partition_entry
	lea r9, [rax + r8]
	cmp r9, r10
	cmovnc r9, r10
	sub r9, rax
	mov [rsi + partitionMBR.length], r9d
	mov r9d, [rdi + extendedtable.block]
	mov [rsi + partitionMBR.table], r9d
	add eax, r9d
	mov [rsi + partitionMBR.start], eax
	setc al
	mov ah, [rdi + extendedtable.block_high]
	mov [rsi + partitionMBR.table_high], ah
	or al, ah
	mov [rsi + partitionMBR.start_high], al
	mov al, [r11 - 8]
	and al, 0x80
	or al, cl
	mov [rsi + partitionMBR.entry_flags], al
	mov al, [r11 - 4]
	mov [rsi + partitionMBR.type], al
	mov eax, [rdi + extendedtable.location]
	mov [rsi + partitionMBR.table_location], eax
	mov eax, [zCurrentInputIndex]
	mov [rsi + partitionMBR.number], eax
	inc eax
	mov [zCurrentInputIndex], eax
	add rsi, partitionMBR_size
	inc dword[rdx + partitiondataMBR.partition_count]
.next_extended_partition_entry:
	add r11, 0x10
	inc cl
	cmp cl, 4
	jc .extended_partition_entry_loop
	movzx ecx, byte[rdi + extendedtable.next]
	cmp ecx, 4
	jnc .next_extended_table
	shl ecx, 4
	mov r10d, [r11 + rcx - 0x3c] ; r11 is at sector + 0x206 after the loop
	mov eax, [zExtendedPartitionSize]
	sub eax, [r11 + rcx - 0x40]
	cmp r10d, eax
	cmovnc r10d, eax
.next_extended_table:
	add rdi, extendedtable_size
	dec dword[zRemainingInputCount]
	jnz .load_extended_partitions_loop
	ret
