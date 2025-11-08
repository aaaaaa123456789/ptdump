LoadFilenameTable:
	; in: OpenValidateDataFile's outputs; out: r13: allocated filename table (key, offset, index for each filename)
	mov esi, r14d
	shl rsi, 4
	call Allocate
	mov r13, rax
	xor edx, edx
	lea r11, [rbp + 4 * rbx]
	mov r10, rax
.loop:
	mov esi, [r11]
	mov [r10 + 8], esi
	mov [r10 + 12], edx
	lea rsi, [rbp + 4 * rsi]
	movzx ecx, word[r11 + 4]
	call GetFilenameSortingKey
	mov [r10], rdi
	add r11, 12
	add r10, 16
	inc edx
	cmp edx, r14d
	jc .loop
	xchg ebx, r14d
	xchg rbp, r13
	call SortPairs
	mov edx, .callback
	call CallForMatchingPairs
	jc .duplicate
	xchg rbp, r13
	xchg ebx, r14d
	ret

.duplicate:
	mov r12, rax
	movzx r13d, r11w
	mov ebp, MiscStrings.stdin
	test r15, r15
	cmovnz rbp, r15
	mov r15, rbp
	call StringLength
	lea rsi, [r13 + rbx + 1 + \
	          (Messages.data_file_open_paren_end - Messages.data_file_open_paren) + \
	          (Messages.duplicate_filename_close_paren_end - Messages.duplicate_filename_close_paren)]
	call Allocate
	mov rdi, rax
	mov esi, Messages.data_file_open_paren
	copybytes Messages.data_file_open_paren_end - Messages.data_file_open_paren
	mov rsi, r15
	mov rcx, rbx
	rep movsb
	mov esi, Messages.duplicate_filename_close_paren
	copybytes Messages.duplicate_filename_close_paren_end - Messages.duplicate_filename_close_paren
	mov rsi, r12
	mov rcx, r13
	rep movsb
	mov byte[rdi], `\n`
	sub rdi, rax
	lea rbx, [rdi + 1]
	mov rbp, rax
	jmp ErrorExit

.callback:
	endbr64
	mov esi, esi
	mov edi, edi
	lea rsi, [r13 + 4 * rsi]
	lea rdi, [r13 + 4 * rdi]
	mov rax, rsi
	movzx ecx, r11w
	repz cmpsb
	setnz cl
	sub cl, 1
	ret

GetFilenameSortingKey:
	; in: rsi: filename, ecx: length (assumed nonzero); out: rdi: key (containing the length in the bottom 2 bytes)
	cmp ecx, 7
	push rcx
	jc .short
	mov ax, [rsi + rcx - 2]
	mov [rsp + 2], ax
	mov edi, -1
	call UpdateCRC
	mov [rsp + 4], edi
	pop rdi
	ret

.short:
	lea rdi, [rsp + 2]
	rep movsb
	pop rdi
	ret

CheckDuplicateInputFilename:
	mov edx, [zInputCount]
	mov rbp, [zInputFilenames]
	mov ebx, 8
CheckDuplicateFilename:
	; in: rbp: pointer to first filename entry, rdx: count, rbx: offset to next; preserves rbp, rdx (not rbx)
	cmp rdx, 2
	jc .done
	push rbp
	push rdx
	lea rsi, [rdx + rdx]
	lea rsi, [8 * rsi + 0xfff]
	and rsi, -0x1000
	push rsi
	call AllocateAligned
	mov r10, rbp
	mov r9, rbx
	mov r8, [rsp + 8]
	shl r8, 4
.fill_loop:
	mov rbp, [r10]
	add r10, r9
	mov [rax + r8 - 8], rbp
	push rax
	call StringLength
	mov ecx, ebx
	mov rsi, rbp
	call GetFilenameSortingKey
	pop rax
	sub r8, 16
	mov [rax + r8], rdi
	jnz .fill_loop
	mov rbp, rax
	mov rbx, [rsp + 8]
	call SortPairs
	mov edx, .callback
	call CallForMatchingPairs
	mov rdi, rbp
	mov ebp, Messages.duplicate_input_filename
	mov ebx, Messages.duplicate_input_filename_end - Messages.duplicate_input_filename
	jc Main.option_error_exit
	pop rsi
	mov eax, munmap
	syscall
	pop rdx
	pop rbp
.done:
	ret

.callback:
	endbr64
	mov rax, rsi
	movzx ecx, r11w
	repz cmpsb
	setnz cl
	sub cl, 1
	ret

FindFilenameInTable:
	; in: r13: filename table, r14d: filename table size, rsi: searched filename; out: eax: index; preserves r10
	mov r11, rsi
	xchg rbp, rsi
	mov rcx, rbx
	call StringLength
	xchg rcx, rbx
	mov rbp, rsi
	cmp rcx, 0x10000
	jnc .fail
	mov rsi, r11
	call GetFilenameSortingKey
	mov r8, -1
	mov r9d, r14d
.loop:
	lea rax, [r8 + r9]
	and rax, -2
	cmp rdi, [r13 + 8 * rax]
	jz .found
	adc rax, 0 ; preserve carry
	rcr rax, 1
	cmovc r9, rax
	cmovnc r8, rax
	lea rax, [r8 + 1]
	cmp rax, r9
	jc .loop
.fail:
	mov r15, r11
	mov ebp, Messages.filename_not_found_error
	mov ebx, Messages.filename_not_found_error_end - Messages.filename_not_found_error
	jmp FilenameErrorExit

.found:
	mov r8, rax
	mov r9, rax
	lea rcx, [r14 + r14]
.forwards_loop:
	add r9, 2
	cmp r9, rcx
	jnc .backwards_loop
	cmp rdi, [r13 + 8 * r9]
	jz .forwards_loop
.backwards_loop:
	sub r8, 2
	jc .got_endpoints
	cmp rdi, [r13 + 8 * r8]
	jz .backwards_loop
.got_endpoints:
	sub r9, r8
	shr r9, 1
	movzx edx, di
.check:
	dec r9
	jz .fail
	add r8, 2
	mov esi, [r13 + 8 * r8 + 8]
	lea rsi, [rbp + 4 * rsi]
	mov rdi, r11
	mov ecx, edx
	repz cmpsb
	jnz .check
	mov eax, [r13 + 8 * r8 + 12]
	ret
