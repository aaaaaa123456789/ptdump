GetPartitionTableType:
	; in: rdi: pointer to partition data, esi: block size
	; out: rax: 0 = unknown, 1 = MBR, 2 = GPT; rdi, rsi unchanged
	lea r10, [rdi + rsi]
GetPartitionTableTypeFromBlocks:
	; in: rdi: pointer to block 0, r10: pointer to block 1, esi: block size
	xor eax, eax
	cmp word[rdi + 0x1fe], 0xaa55
	jnz .done
	inc eax
	cmp byte[rdi + 0x1c2], 0xee
	jnz .done
	cmp dword[rdi + 0x1c6], 1
	jnz .done
	pxor xmm0, xmm0
	movdqu xmm1, [rdi + 0x1ce]
	psubb xmm0, xmm1
	por xmm1, xmm0
	pxor xmm0, xmm0
	movdqu xmm2, [rdi + 0x1de]
	psubb xmm0, xmm2
	por xmm2, xmm0
	por xmm1, xmm2
	pxor xmm0, xmm0
	movdqu xmm1, [rdi + 0x1ee]
	psubb xmm0, xmm2
	por xmm2, xmm0
	por xmm1, xmm2
	pmovmskb edx, xmm1
	test edx, edx
	jnz .done
	mov rdx, "EFI PART"
	cmp [r10], rdx
	jnz .done
	mov edx, [r10 + 12]
	cmp edx, 92
	jc .done
	cmp edx, esi
	ja .done
	cmp qword[r10 + 24], 1
	jnz .done
	mov edx, [r10 + 84]
	cmp edx, 128
	jc .done
	test dl, 7
	jnz .done
	inc eax
.done:
	ret

IsExtendedPartitionCode:
	; in: al: code; out: al, nz flag: is extended partition
	; follow Linux: recognise 0x05, 0x0f and 0x85 as extended partition types
	cmp al, 15
	setz ah
	add al, al
	cmp al, 10
	setz al
	or al, ah
	ret

LoadAllPartitionTables:
	; in: rbp = data file contents, ebx = file table offset, r14d = file count; out: r15: pointers to partition tables
	push r14
	lea rsi, [8 * r14]
	mov r15, rsi
	call Allocate
	push rax
	add r15, rax
	mov eax, 0xff8
	and rax, r15
	cmovz r15, rax
.loop:
	lea edi, [r14 - 1]
	call LoadPartitionTablesForFile
	dec r14d
	mov rdi, [rsp]
	mov rdx, [zCurrentPartitionTable]
	mov [rdi + 8 * r14], rdx
	jnz .loop
	pop r15
	pop r14
ReleaseCurrentBuffer:
	mov rdi, [zCurrentBuffer]
	mov esi, [zCurrentBufferSize]
	mov eax, munmap
	syscall
	ret

ValidateGPTTableHeader:
	; in: rax: block number, r10: block data, rbp: data file contents (preserved); out: al: 0 = valid, 3 = invalid, 0xff: absent
	; [zCurrentPartitionTable] and [zCurrentBlockSize] must be set before calling this function
	mov rcx, "EFI PART"
	cmp rcx, [r10]
	jnz .absent
	cmp dword[r10 + 8], 0x10000
	jnz .absent
	mov ecx, [r10 + 12]
	cmp ecx, 92
	jnc .present
.absent:
	mov al, 0xff
	ret

.invalid:
	mov al, 3
	ret

.present:
	cmp ecx, [zCurrentBlockSize]
	ja .invalid
	cmp [r10 + 24], rax
	jnz .invalid
	cmp dword[r10 + 80], 0
	jz .invalid
	mov eax, [r10 + 84]
	test eax, 7
	jnz .invalid
	cmp eax, 127 ; comparing to 128 results in a bigger encoding
	jbe .invalid
	push rcx
	push r10
	mov esi, ecx
	call ResizeCurrentBuffer
	mov rdi, rax
	pop rsi
	mov r10, rsi
	pop rcx
	mov eax, ecx
	rep movsb
	mov rsi, [zCurrentBuffer]
	xor edx, edx
	xchg [rsi + 16], edx
	mov edi, -1
	mov ecx, eax
	call UpdateCRC
	not edi
	cmp edi, edx
	jnz .invalid
	mov r11, [zCurrentPartitionTable]
	mov rsi, [r11 + partitiondataGPT.block_table]
	mov edi, [r11 + partitiondataGPT.block_table_entries]
	mov rdx, [r10 + 72]
	call FindBlockTableEntry
	test rdx, rdx
	jz .absent
	mov rcx, rdx
	mov eax, [r10 + 80]
	mul dword[r10 + 84]
	cmp edx, 4
	jnc .absent
	div dword[zCurrentBlockSize]
	; round up instead of down
	add edx, -1
	sbb edx, edx
	sub eax, edx
	mov esi, [r10 + 72]
	sub esi, [rcx]
	lea eax, [rax + rsi]
	jz .first_entry_at_start
	mov edi, [zCurrentBlockSize]
	shr edi, 2
	imul esi, edi
.first_entry_at_start:
	add esi, [rcx + 12]
	lea rsi, [rbp + 4 * rsi]
	cmp eax, [rcx + 8]
	mov edi, -1
	jbe .single_block_table_entry
	mov eax, [zCurrentBlockSize]
	xor edx, edx
	div dword[r10 + 84]
	; while there's no rule against partition entries straddling block boundaries, supporting such an obscure case
	; is not worth the complexity here: by far and large, both block sizes and partition entry sizes are powers of two
	; (the latter being currently a UEFI requirement), so this scenario cannot happen at all under normal circumstances
	test edx, edx
	jnz .invalid
	mov rdx, rcx
	mov ecx, [r11 + partitiondataGPT.block_table_entries]
	shl ecx, 4
	add rcx, [r11 + partitiondataGPT.block_table]
	push rcx
	push rax
	mov eax, [r10 + 80]
	mov [rsp + 4], eax
	mov ecx, [rdx + 8]
	add ecx, [rdx]
	sub ecx, [r10 + 72]
	mov eax, [rsp]
	imul eax, ecx
	sub [rsp + 4], eax
	mov eax, [zCurrentBlockSize]
	imul rcx, rax
	call UpdateCRC
.next_block_table_entry_loop:
	add rdx, 16
	cmp rdx, [rsp + 8]
	ja .absent
	mov eax, [rdx - 8]
	add rax, [rdx - 16]
	cmp rax, [rdx]
	jnz .absent
	mov ecx, [rdx + 8]
	mov eax, [rsp]
	imul rcx, rax
	mov eax, [rsp + 4]
	cmp rcx, rax
	cmovnc rcx, rax
	mov eax, [r10 + 84]
	sub [rsp + 4], ecx
	imul rcx, rax
	mov esi, [rdx + 12]
	lea rsi, [rbp + 4 * rsi]
	call UpdateCRC
	cmp dword[rsp + 4], 0
	jnz .next_block_table_entry_loop
	add rsp, 16
	jmp .check

.single_block_table_entry:
	mov eax, [r10 + 80]
	mov ecx, [r10 + 84]
	imul rcx, rax
	call UpdateCRC
.check:
	not edi
	cmp edi, [r10 + 88]
	jnz .invalid
	xor al, al
	ret

CompareGPTTables:
	; in: rdx = [zCurrentPartitionTable] (preserved); rbp = data file contents; eax, ecx: table header locations; out: zero flag: tables match
	mov rsi, [rbp + 4 * rax + 40]
	cmp rsi, [rbp + 4 * rcx + 40]
	jnz .done
	mov rsi, [rbp + 4 * rax + 48]
	cmp rsi, [rbp + 4 * rcx + 48]
	jnz .done
	mov rsi, [rbp + 4 * rax + 84]
	cmp rsi, [rbp + 4 * rcx + 84]
	jnz .done
	mov edi, [rbp + 4 * rax + 80]
	cmp edi, [rbp + 4 * rcx + 80]
	jnz .done
	mov r9, rdx
	mov rdx, [rbp + 4 * rax + 72]
	mov r10, [rbp + 4 * rcx + 72]
	cmp rdx, r10
	jz .restore
	shr esi, 2
	imul esi, edi
	mov r11d, esi
	mov rsi, [r9 + partitiondataGPT.block_table]
	mov edi, [r9 + partitiondataGPT.block_table_entries]
	push rdx
	push r10
	call FindBlockTableEntry ; these searches are assumed not to fail, since the tables were validated before
	xchg r10, rdx
	call FindBlockTableEntry
	mov r9, rdx
	pop rax
	mov ecx, [zCurrentBlockSize]
	shr ecx, 2
	sub rax, [rdx]
	mov r8d, [rdx + 8]
	jz .second_at_start
	sub r8d, eax
	imul eax, ecx
.second_at_start:
	add eax, [rdx + 12]
	pop rdx
	push r15
	push rbx
	sub rdx, [r10]
	mov ebx, [r10 + 8]
	jz .first_at_start
	sub ebx, edx
	imul edx, ecx
.first_at_start:
	add edx, [r10 + 12]
.loop:
	test r8d, r8d
	jnz .no_second_reload
	add r9, 16
	mov r8d, [r9 + 8]
	mov eax, [r9 + 12]
.no_second_reload:
	test ebx, ebx
	jnz .no_first_reload
	add r10, 16
	mov ebx, [r10 + 8]
	mov edx, [r10 + 12]
.no_first_reload:
	mov ecx, r8d
	cmp ecx, ebx
	cmovnc ecx, ebx
	mov r15d, [zCurrentBlockSize]
	shr r15d, 2
	imul r15d, ecx
	sub r8d, ecx
	sub ebx, ecx
	cmp eax, edx
	jz .no_comparison
	lea rsi, [rbp + 4 * rdx]
	lea rdi, [rbp + 4 * rax]
	repz cmpsd
	jnz .pop
.no_comparison:
	add eax, r15d
	add edx, r15d
	sub r11d, r15d
	jnz .loop
.pop:
	pop rbx
	pop r15
.restore:
	mov rdx, [zCurrentPartitionTable]
.done:
	ret
