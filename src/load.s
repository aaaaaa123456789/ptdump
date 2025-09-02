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
	mov esi, FilenameStrings.stdin
	mov edi, zStringBuffer
	copybytes FilenameStrings.stdin_end - FilenameStrings.stdin
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
	mov ebp, FilenameStrings.stdin
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
	; in: rsi: filename, ecx: length (assumed nonzero); out: rdi: key (bits 0-15: length, 32-63: CRC)
	mov eax, ecx
	shl eax, 8
	stc
	sbb edi, edi
.loop:
	lodsb
	crc32 edi, al
	dec ecx
	jnz .loop
	shl rdi, 32
	shr eax, 8
	or rdi, rax
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

CallForMatchingPairs:
	; in: rbp: sorted key/value table, rbx: table length (non-zero), rdx: callback
	; calls the callback for each pair of entries with the same key, with rsi = #1 value, rdi = #2 value, r11 = key
	; exits immediately if the callback returns carry and returns the callback's registers; returns no carry otherwise
	; the callback must preserve all registers other than rax, rcx, rsi and rdi
	sub rbx, 1 ; will also clear carry
	jz .done
	xor r8d, r8d
.find_pairs_loop:
	lea rsi, [r8 + r8]
	lea rsi, [rbp + 8 * rsi]
	lea r9, [r8 - 1]
	mov r11, [rsi]
.check_next_key:
	inc r9
	cmp r9, rbx
	jnc .got_range
	add rsi, 16
	cmp r11, [rsi]
	jz .check_next_key
.got_range:
	cmp r8, r9
	jz .next_key
.outer_loop:
	mov r10, r8
.inner_loop:
	inc r10
	lea rsi, [r8 + r8]
	lea rdi, [r10 + r10]
	mov rsi, [rbp + 8 * rsi + 8]
	mov rdi, [rbp + 8 * rdi + 8]
	call rdx
	jc .done
	cmp r10, r9
	jc .inner_loop
	inc r8
	cmp r8, r9
	jc .outer_loop
.next_key:
	inc r8
	cmp r8, rbx
	jc .find_pairs_loop
.done:
	inc rbx ; doesn't affect carry
	ret

FindFilenameInTable:
	; in: r13: filename table, r14d: filename table size, rsi: searched filename; out: eax: index
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
