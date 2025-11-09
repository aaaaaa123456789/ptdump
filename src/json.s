JSONMode:
	endbr64
	cmp dword[zInputCount], 0
	mov ebp, Messages.inputs_not_valid_error
	mov ebx, Messages.inputs_not_valid_error_end - Messages.inputs_not_valid_error
	jnz BadInvocationExit
	call RejectSizeArguments
	call CheckOpenStandardOutput ; leaves [zCurrentFD] = 1
	call OpenValidateDataFile
	call LoadAllPartitionTables
	mov esi, JSON_OUTPUT_BUFFER_SIZE
	call AllocateAligned
	lea r13, [rax + JSON_OUTPUT_BUFFER_SIZE]
	mov byte[rax], "["
	xor r12d, r12d
	lea rdi, [rax + 1]
	mov byte[zFallbackPartitionTypes], 0
.file_loop:
	lea edx, [r12 + 2 * r12]
	add edx, ebx
	lea rdx, [rbp + 4 * rdx]
	movzx eax, word[rdx + 4]
	lea rax, [rdi + 4 * rax + 74]
	mov [zGenericDataBuffer], rdx
	mov r10, rdx
	call .conditional_flush
	mov rdx, r10
	mov esi, JSONText.brace_filename
	copybytes JSONText.brace_filename_end - JSONText.brace_filename
	mov r10, rdi

	mov al, '"'
	stosb
	mov esi, [rdx]
	lea rsi, [rbp + 4 * rsi]
	movzx ecx, word[rdx + 4]
.filename_UTF8_loop:
	lodsb
	test al, al
	js .multibyte_UTF8
	cmp al, 0x7f
	jz .escaped_single_UTF8
	cmp al, 0x20
	jnc .single_UTF8
.escaped_single_UTF8:
	mov dword[rdi], '\u00'
	add rdi, 4
	call RenderHexByte
	add rdi, 2
	jmp .next_UTF8_byte
.multibyte_UTF8:
	cmp al, 0xc2
	jc .invalid_UTF8
	cmp al, 0xf5
	jnc .invalid_UTF8
	cmp al, 0xe0
	setnc ah
	cmp al, 0xf0
	sbb ah, -3
	cmp ecx, 4
	jnc .UTF8_length_OK
	cmp cl, ah
	jc .invalid_UTF8
.UTF8_length_OK:
	dec ah
	push rcx
	mov cl, ah
	mov ch, 0x80
	shr ch, cl
	add al, ch
	shl cl, 1
	add cl, ah
	shl cl, 1
	movzx edx, al
	shl edx, cl
	mov ch, ah
.UTF8_continuation_loop:
	lodsb
	sub cl, 6
	sub al, 0x80
	cmp al, 0x40
	sbb ah, ah
	and ch, ah ; clears ch if al is out of range
	movzx eax, al
	shl eax, cl
	or edx, eax
	test cl, cl
	jnz .UTF8_continuation_loop
	mov cl, ch
	shl cl, 2
	add cl, ch
	mov eax, 2
	shl eax, cl
	cmp edx, eax
	cmc
	sbb cl, cl
	and ch, cl
	movzx eax, ch
	pop rcx
	jz .invalid_UTF8
	sub ecx, eax
	mov eax, edx
	shr eax, 11
	cmp eax, 0xd800 >> 11
	jz .invalid_UTF8
	cmp eax, 0x10000 >> 11 ; smaller encoding than comparing edx directly
	jc .no_UTF8_surrogates
	cmp ax, 0x110000 >> 11
	jnc .invalid_UTF8
	mov [zTempValue + 2], dx
	shr edx, 10
	add dx, 0xd7c0
	call .print_JSON_Unicode_escape
	mov dx, [zTempValue + 2]
	and dx, 0x3ff
	add dx, 0xdc00
.no_UTF8_surrogates:
	call .print_JSON_Unicode_escape
	jmp .next_UTF8_byte
.single_UTF8:
	stosb
	cmp al, '\'
	jz .repeat_UTF8
	cmp al, '"'
	jnz .next_UTF8_byte
	mov byte[rdi - 1], '\'
.repeat_UTF8:
	stosb
.next_UTF8_byte:
	dec ecx
	jnz .filename_UTF8_loop
	mov al, '"'
	stosb
	jmp .printed_filename

.invalid_UTF8:
	mov rdi, r10
	mov rdx, [zGenericDataBuffer]
	mov esi, [rdx]
	lea rsi, [rbp + 4 * rsi]
	movzx ecx, word[rdx + 4]
	call .print_byte_array
.printed_filename:
	mov esi, JSONText.partition_type
	copybytes JSONText.partition_type_end - JSONText.partition_type
	mov rdx, [r15 + 8 * r12]
	mov dl, [rdx + partitiondata.type]
	mov [zPartitionTableType], dl
	mov rax, countedstring("invalid")
	mov r10, countedstring("none")
	test dl, dl
	cmovz rax, r10
	dec dl
	cmp dl, 1
	mov edx, countedstring("MBR")
	cmovc rax, rdx
	mov edx, countedstring("GPT")
	call .print_counted_string_move_conditional
	mov esi, JSONText.block_size
	copybytes JSONText.block_size_end - JSONText.block_size
	mov r10, [zGenericDataBuffer]
	movzx eax, word[r10 + 6]
	dec ax
	inc eax
	mov [zCurrentBlockSize], eax
	shl eax, 2
	call .print_number
	mov esi, JSONText.blocks_bracket
	copybytes JSONText.blocks_bracket_end - JSONText.blocks_bracket

	mov r10d, [r10 + 8]
	lea r10, [rbp + 4 * r10]
	mov ecx, [r10]
.block_loop:
	test cl, cl
	jnz .sequence_block
	shr ecx, 8
	mov [zCurrentBlockCount], ecx
	mov ecx, [r10 + 4]
	mov [zCurrentBlockLocation], ecx
	mov rcx, [r10 + 8]
	mov [zCurrentBlockNumber], rcx
	call .print_block
	add r10, 16
	jmp .next_block
.sequence_block:
	mov [zRemainingEntries], cl
	shr ecx, 8
	shl rcx, 32
	mov [zCurrentBlockNumber], rcx
	inc ecx ; sets ecx = 1
	mov [zCurrentBlockCount], ecx
	mov ecx, [r10 + 4]
	mov [zCurrentBlockLocation], ecx
	add r10, 8
.sequence_loop:
	mov ecx, [r10]
	add [zCurrentBlockNumber], rcx
	call .print_block
	mov ecx, [zCurrentBlockSize]
	add [zCurrentBlockLocation], ecx
	add r10, 4
	dec byte[zRemainingEntries]
	jnz .sequence_loop
.next_block:
	mov ecx, [r10]
	test ecx, ecx
	jnz .block_loop
	mov byte[rdi - 1], "]"

	lea rax, [rdi + 21]
	call .conditional_flush
	mov esi, JSONText.effective_blocks
	copybytes JSONText.effective_blocks_end - JSONText.effective_blocks
	mov r10, [r15 + 8 * r12]
	mov ecx, [r10 + partitiondata.block_table_entries]
	mov [zRemainingEntries], ecx
	mov r10, [r10 + partitiondata.block_table]
.effective_block_loop:
	mov rcx, [r10]
	mov [zCurrentBlockNumber], rcx
	assert zCurrentBlockLocation - zCurrentBlockCount == 4
	mov rcx, [r10 + 8]
	mov [zCurrentBlockCount], rcx
	call .print_block
	add r10, 16
	dec dword[zRemainingEntries]
	jnz .effective_block_loop
	mov byte[rdi - 1], "]"

	lea rax, [rdi + 3]
	call .conditional_flush
	mov al, [zPartitionTableType]
	dec al
	jz .MBR
	dec al
	jnz .next_file

	lea rax, [rdi + 644]
	call .conditional_flush
	mov r10, [r15 + 8 * r12]
	movzx ecx, byte[r10 + partitiondataGPT.selected_table_header]
	mov ecx, [r10 + 4 * rcx + partitiondataGPT.table_header_locations]
	lea rdx, [rbp + 4 * rcx]
	mov esi, JSONText.diskID_quote
	copybytes JSONText.diskID_quote_end - JSONText.diskID_quote
	lea rsi, [rdx + 56]
	call LoadRenderGUID
	add rdi, 36
	mov esi, JSONText.first_block
	copybytes JSONText.first_block_end - JSONText.first_block
	mov rax, [rdx + 40]
	mov r9, rdx
	call .print_number
	mov esi, JSONText.last_block
	copybytes JSONText.last_block_end - JSONText.last_block
	mov rax, [r9 + 48]
	call .print_number
	mov esi, JSONText.partition_tables
	copybytes JSONText.partition_tables_end - JSONText.partition_tables
	xor r11d, r11d
	mov al, [r10 + partitiondataGPT.table_header_flags]
	mov [zPartitionTableType], al
.GPT_table_header_loop:
	mov esi, JSONText.brace_header
	copybytes JSONText.brace_header_end - JSONText.brace_header
	mov rax, [r10 + 8 * r11 + partitiondataGPT.table_header_blocks]
	call .print_number
	mov rax, ',"data":'
	stosq
	mov esi, [r10 + 4 * r11 + partitiondataGPT.table_header_locations]
	lea r9, [rbp + 4 * rsi]
	mov rax, [r9 + 72]
	call .print_number
	mov esi, JSONText.blocks_bracket
	copybytes JSONText.blocks_bracket_end - JSONText.blocks_bracket - 1
	mov eax, [r9 + 80]
	mov edx, [r9 + 84]
	imul rax, rdx
	xor edx, edx
	mov ecx, [zCurrentBlockSize]
	shl ecx, 2
	div rcx
	add edx, -1
	adc rax, 0
	call .print_number
	mov esi, JSONText.entries
	copybytes JSONText.entries_end - JSONText.entries
	mov eax, [r9 + 80]
	call .print_number
	mov esi, JSONText.entry_size
	copybytes JSONText.entry_size_end - JSONText.entry_size
	mov eax, [r9 + 84]
	call .print_number
	mov cl, [zPartitionTableType]
	shr byte[zPartitionTableType], 2
	and cl, 3
	mov rax, ',"valid"'
	stosq
	mov al, ":"
	stosb
	cmp cl, 3
	call .print_boolean
	mov rax, ',"matchi'
	stosq
	mov eax, 'ng":'
	stosd
	mov al, cl
	call .print_table_status
	mov ax, "},"
	stosw
	inc r11d
	cmp r11b, [r10 + partitiondataGPT.table_header_count]
	jc .GPT_table_header_loop
	dec rdi
	mov esi, JSONText.partitions_brackets
	copybytes JSONText.partitions_brackets_end - JSONText.partitions_brackets

	mov eax, [r10 + partitiondataGPT.partition_count]
	test eax, eax
	jz .next_file
	mov [zRemainingEntries], eax
	dec rdi
	mov r10, [r10 + partitiondataGPT.partition_table]
.GPT_partition_loop:
	lea rax, [rdi + 594 + MAXIMUM_PARTITION_TYPE_LENGTH]
	call .conditional_flush
	mov esi, JSONText.brace_number
	copybytes JSONText.brace_number_end - JSONText.brace_number
	mov eax, [r10 + partitionGPT.number]
	call .print_number
	mov eax, [r10 + partitionGPT.location]
	lea r9, [rbp + 4 * rax]
	mov esi, JSONText.start
	copybytes JSONText.start_end - JSONText.start
	mov rax, [r9 + 32]
	call .print_number
	mov esi, JSONText.length
	copybytes JSONText.length_end - JSONText.length
	mov rax, [r9 + 40]
	sub rax, [r9 + 32]
	inc rax
	call .print_number
	mov esi, JSONText.typeID_quote
	copybytes JSONText.typeID_quote_end - JSONText.typeID_quote
	mov rsi, r9
	call LoadGUID ; clobbers r9, but preserves rsi
	movdqa xmm7, xmm0
	call RenderGUID
	add rdi, 36
	push r11
	push rsi
	push rdi
	mov esi, JSONText.quote_type
	copybytes JSONText.quote_type_end - JSONText.quote_type
	call GetGPTPartitionTypeString ; preserves r10
	pop rcx
	pop rsi
	pop r11
	cmovz rdi, rcx
	mov rax, '","partI'
	stosq
	mov eax, 'D":"'
	stosd
	add rsi, 16
	call LoadRenderGUID
	mov byte[rdi + 36], '"'
	add rdi, 37
	; rsi/r9 is offset 16 bytes from here on!
	mov r9, rsi
	add rsi, 40
	lodsw
	test ax, ax
	jz .done_GPT_partition_label
	mov rdx, ',"label"'
	mov [rdi], rdx
	mov word[rdi + 8], ':"'
	add rdi, 10
	lea r8, [rdi - 1]
	mov byte[zUnicodeSurrogatePair], 0
	mov cl, 36
.GPT_partition_label_loop:
	cmp ax, 0x20
	jc .escaped_GPT_partition_label_character
	cmp ax, 0x7f
	jnc .escaped_GPT_partition_label_character
	stosb
	cmp al, '\'
	jz .repeat_GPT_partition_label_character
	cmp al, '"'
	jnz .next_GPT_partition_label_character
	mov byte[rdi - 1], '\'
.repeat_GPT_partition_label_character:
	stosb
	jmp .next_GPT_partition_label_character
.escaped_GPT_partition_label_character:
	call CheckUnpairedUTF16Surrogate
	jc .invalid_GPT_partition_label
	mov word[rdi], "\u"
	add rdi, 4
	mov [zTempValue], ah
	call RenderHexByte
	sub rdi, 2
	mov al, [zTempValue]
	call RenderHexByte
	add rdi, 4
.next_GPT_partition_label_character:
	dec cl
	jz .finish_GPT_partition_label
	lodsw
	test ax, ax
	jnz .GPT_partition_label_loop
.finish_GPT_partition_label:
	mov al, '"'
	stosb
	jmp .done_GPT_partition_label
.invalid_GPT_partition_label:
	mov rdi, r8
	lea rsi, [r9 + 40]
	mov byte[zTempByte], 36
	mov al, "["
	stosb
.GPT_partition_label_array_loop:
	lodsw
	test ax, ax
	jz .finish_GPT_partition_label_array
	movzx eax, ax
	push rsi
	call .print_number
	pop rsi
	mov al, ","
	stosb
	dec byte[zTempByte]
	jnz .GPT_partition_label_array_loop
.finish_GPT_partition_label_array:
	mov byte[rdi - 1], "]"
.done_GPT_partition_label:
	mov esi, JSONText.attributes
	copybytes JSONText.attributes_end - JSONText.attributes
	mov r8, rdi
	xor eax, eax
	add r9, 32
	mov edi, zStringBuffer
	mov esi, edi
.GPT_attribute_array_loop:
	bt [r9], eax ; the actual operation width doesn't matter here
	jnc .skip_GPT_attribute
	stosb
.skip_GPT_attribute:
	inc eax
	cmp eax, 64
	jc .GPT_attribute_array_loop
	sub edi, esi
	mov ecx, edi
	mov rdi, r8
	call .print_byte_array
	mov esi, JSONText.required
	copybytes JSONText.required_end - JSONText.required
	test byte[r9], 1
	call .print_boolean
	mov esi, JSONText.bootable
	copybytes JSONText.bootable_end - JSONText.bootable
	test byte[r9], 4
	call .print_boolean
	mov ax, "},"
	stosw
	add r10, partitionGPT_size
	dec dword[zRemainingEntries]
	jnz .GPT_partition_loop
	jmp .next_file_add_bracket

.MBR:
	lea rax, [rdi + 52]
	call .conditional_flush
	mov esi, JSONText.diskID_quote
	copybytes JSONText.diskID_quote_end - JSONText.diskID_quote - 1
	mov r10, [r15 + 8 * r12]
	mov rsi, [r10 + partitiondataMBR.block_table]
	mov esi, [rsi + 12]
	mov eax, [rbp + 4 * rsi + 0x1b8]
	call .print_number
	mov esi, JSONText.extended_tables
	copybytes JSONText.extended_tables_end - JSONText.extended_tables
	movzx edx, byte[r10 + partitiondataMBR.partition_count_small]
	cmp edx, 5
	jc .MBR_small_partitions
	mov ecx, [r10 + partitiondataMBR.extended_count]
	test ecx, ecx
	jz .no_MBR_extended_partitions
	mov [zRemainingEntries], ecx
	push rbx
	mov rbx, [r10 + partitiondataMBR.extended_tables]
.MBR_extended_partition_table_loop:
	lea rax, [rdi + 70]
	call .conditional_flush
	mov esi, JSONText.brace_block
	copybytes JSONText.brace_block_end - JSONText.brace_block
	mov edx, [rbx + extendedtable.block]
	movzx eax, byte[rbx + extendedtable.block_high]
	shl rax, 32
	or rax, rdx
	call .print_number
	mov esi, JSONText.parent
	copybytes JSONText.parent_end - JSONText.parent
	mov edx, [rbx + extendedtable.parent]
	movzx eax, byte[rbx + extendedtable.parent_high]
	shl rax, 32
	or rax, rdx
	call .print_number
	mov esi, JSONText.entry_one_brace
	copybytes JSONText.entry_one_brace_end - JSONText.entry_one_brace
	mov al, [rbx + extendedtable.parent_entry]
	add [rdi - 3], al
	add rbx, extendedtable_size
	dec dword[zRemainingEntries]
	jnz .MBR_extended_partition_table_loop
	pop rbx
	dec rdi
.no_MBR_extended_partitions:
	mov edx, [r10 + partitiondataMBR.partition_count]
.MBR_small_partitions:
	mov esi, JSONText.partitions_brackets
	copybytes JSONText.partitions_brackets_end - JSONText.partitions_brackets
	test edx, edx
	jz .next_file
	dec rdi
	mov [zRemainingEntries], edx

	mov r10, [r10 + partitiondataMBR.partition_table]
.MBR_partition_loop:
	lea rax, [rdi + 194 + MAXIMUM_PARTITION_TYPE_LENGTH]
	call .conditional_flush
	mov esi, JSONText.brace_number
	copybytes JSONText.brace_number_end - JSONText.brace_number
	mov eax, [r10 + partitionMBR.number]
	call .print_number
	mov esi, JSONText.start
	copybytes JSONText.start_end - JSONText.start
	mov edx, [r10 + partitionMBR.start]
	movzx eax, byte[r10 + partitionMBR.start_high]
	shl rax, 32
	or rax, rdx
	call .print_number
	mov esi, JSONText.length
	copybytes JSONText.length_end - JSONText.length
	mov eax, [r10 + partitionMBR.length]
	call .print_number
	mov esi, JSONText.typeID_quote
	copybytes JSONText.typeID_quote_end - JSONText.typeID_quote - 1
	mov al, [r10 + partitionMBR.type]
	mov r9b, al
	call .print_byte
	mov r11, rdi
	mov esi, JSONText.quote_type + 1
	copybytes JSONText.quote_type_end - JSONText.quote_type - 1
	movzx eax, r9b
	call GetMBRPartitionTypeString ; preserves r10, r11
	mov al, '"'
	stosb
	cmovz rdi, r11
	mov esi, JSONText.table
	copybytes JSONText.table_end - JSONText.table
	mov edx, [r10 + partitionMBR.table]
	movzx eax, byte[r10 + partitionMBR.table_high]
	shl rax, 32
	or rax, rdx
	call .print_number
	mov esi, JSONText.entry_bootable
	copybytes JSONText.bootable_end - JSONText.entry_bootable
	mov al, [r10 + partitionMBR.entry_flags]
	mov cl, al
	and al, 3
	add [rdi - 13], al
	test cl, 0x80
	call .print_boolean
	shl cl, 2
	movzx ecx, cl
	add ecx, [r10 + partitionMBR.table_location]
	lea r11, [rbp + 4 * rcx + 0x1bf]
	mov esi, JSONText.startCHS
	copybytes JSONText.startCHS_end - JSONText.startCHS
	call .print_CHS
	add r11, 4
	mov esi, JSONText.endCHS
	copybytes JSONText.endCHS_end - JSONText.endCHS
	call .print_CHS
	mov al, [r11 - 5]
	mov esi, JSONText.bracket_status
	copybytes JSONText.bracket_status_end - JSONText.bracket_status
	call .print_byte
	mov ax, "},"
	stosw
	add r10, partitionMBR_size
	dec dword[zRemainingEntries]
	jnz .MBR_partition_loop
.next_file_add_bracket:
	mov byte[rdi - 1], "]"

.next_file:
	mov ax, "},"
	stosw
	inc r12d
	cmp r12d, r14d
	jc .file_loop
	mov word[rdi - 1], `]\n`
	lea ebx, [rdi + 1]
	lea rbp, [r13 - JSON_OUTPUT_BUFFER_SIZE]
	sub ebx, ebp
	call WriteData
	xor edi, edi
	jmp ExitProgram

.print_JSON_Unicode_escape:
	mov ax, '\u'
	stosw
	mov [zTempValue], dl
	mov al, dh
	call RenderHexByte
	add rdi, 2
	mov al, [zTempValue]
	call RenderHexByte
	add rdi, 2
	ret

.print_block:
	lea rax, [rdi + 70]
	call .conditional_flush
	mov esi, JSONText.brace_number
	copybytes JSONText.brace_number_end - JSONText.brace_number
	mov rax, [zCurrentBlockNumber]
	call .print_number
	mov esi, JSONText.offset
	copybytes JSONText.offset_end - JSONText.offset
	mov eax, [zCurrentBlockLocation]
	shl rax, 2
	call .print_number
	mov esi, JSONText.count
	copybytes JSONText.count_end - JSONText.count
	mov eax, [zCurrentBlockCount]
	call .print_number
	mov ax, "},"
	stosw
	ret

.print_byte_array:
	mov ax, "[]"
	stosw
	test ecx, ecx
	jz .done_byte_array
	dec rdi
.byte_array_loop:
	lodsb
	call .print_byte
	mov al, ","
	stosb
	dec ecx
	jnz .byte_array_loop
	mov byte[rdi - 1], "]"
.done_byte_array:
	ret

.print_CHS:
	mov rcx, rdi
	mov ax, "10"
	stosw
	mov ax, [r11 + 1]
	mov dh, al
	shr al, 6
	xchg ah, al
	sub ax, 1000
	jnc .got_cylinder_hundreds
	add ax, 1000
	sub rdi, 2
	cmp ax, 100
	jc .got_cylinder_hundreds
	mov dl, 100
	div dl
	add al, "0"
	stosb
	mov al, ah
.got_cylinder_hundreds:
	cmp rcx, rdi
	mov dl, 10
	jnz .write_cylinder_tens
	cmp al, dl
	jc .skip_cylinder_tens
.write_cylinder_tens:
	xor ah, ah
	div dl
	add al, "0"
	stosb
	mov al, ah
.skip_cylinder_tens:
	add al, "0"
	mov ah, ","
	stosw
	mov al, [r11]
	call .print_byte
	mov al, ","
	stosb
	mov al, dh
	and al, 0x3f
	; fallthrough

.print_byte:
	cmp al, 10
	jc .single_digit
	mov dl, 100
	cmp al, dl
	jc .two_digits
	xor ah, ah
	div dl
	add al, "0"
	stosb
	mov al, ah
.two_digits:
	xor ah, ah
	mov dl, 10
	div dl
	add al, "0"
	stosb
	mov al, ah
.single_digit:
	add al, "0"
	stosb
	ret

.print_number:
	call NumberLength
	mov r8d, ecx
	call PrintNumber
	add rdi, r8
	ret

.print_table_status:
	; al = 0, 1, 2 for false, true, null; 3 (invalid table) counts as false
	cmp al, 3
	jz .print_boolean
	mov rdx, countedstring("null")
	cmp al, 2
	cmovz rax, rdx
	jz .print_counted_string
	test al, al
.print_boolean:
	; zero = false, not zero = true
	mov rax, countedstring("true")
	mov rdx, countedstring("false")
.print_counted_string_move_conditional:
	cmovz rax, rdx
.print_counted_string:
	movzx rdx, al
	shr rax, 8
	mov [rdi], rax
	add rdi, rdx
	ret

.conditional_flush:
	cmp rax, r13
	jbe .done
	push rbp
	push rbx
	push r10
	mov ebx, edi
	lea rbp, [r13 - JSON_OUTPUT_BUFFER_SIZE]
	sub ebx, ebp
	call WriteData
	lea rdi, [r13 - JSON_OUTPUT_BUFFER_SIZE]
	pop r10
	pop rbx
	pop rbp
.done:
	ret
