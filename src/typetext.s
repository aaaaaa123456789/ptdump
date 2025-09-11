ShowPartitionTypesMode:
	endbr64
	mov esi, 0x7000
	call AllocateAligned
	mov rbp, rax
	mov rdi, rax
	mov esi, Headers.MBR_types
	copybytes Headers.MBR_types_end - Headers.MBR_types
	xor ebx, ebx
.loopMBR:
	movzx esi, word[ebx + ebx + PartitionTypesMBR]
	test esi, esi
	jz .nextMBR
	mov al, bl
	call RenderHexByte
	mov byte[rdi + 2], `\t`
	add rdi, 3
	call GetPartitionTypeString
	mov byte[rdi], `\n`
	inc rdi
.nextMBR:
	inc bl
	jnz .loopMBR
	mov esi, Headers.GPT_types
	copybytes Headers.GPT_types_end - Headers.GPT_types
	mov rbx, -2 * GPT_PARTITION_TYPES
.loopGPT:
	lea rsi, [8 * rbx + PartitionTypesGPT.GUIDs + 16 * GPT_PARTITION_TYPES]
	call LoadGUID
	call RenderGUID
	mov byte[rdi + 36], `\t`
	add rdi, 37
	movzx esi, word[rbx + PartitionTypesGPT.labels + 2 * GPT_PARTITION_TYPES]
	call GetPartitionTypeString
	mov byte[rdi], `\n`
	inc rdi
	add rbx, 2
	jnz .loopGPT
	sub edi, ebp
	mov ebx, edi
	jmp WriteStandardOutputExit

GetPartitionTypeString:
	; in: esi: offset into PartitionTypeLabels, rdi: output address; out: rdi: end of string
	add esi, PartitionTypeLabels
	lodsb
	cmp al, MULTIPLE_LABEL_CODE + 2
	jc .copy
	sub al, MULTIPLE_LABEL_CODE
	mov edx, esi
.copy_loop:
	movzx esi, word[rdx]
	add edx, 2
	add esi, PartitionTypeLabels + 1
	movzx ecx, byte[rsi - 1]
	rep movsb
	mov byte[rdi], " "
	inc rdi
	dec al
	jnz .copy_loop
	dec rdi
	ret

.copy:
	movzx ecx, al
	rep movsb
	ret

RenderGUID:
	; in: xmm0: GUID to render, rdi: output address; clobbers rax, xmm0-xmm5
	mov eax, 0x300f0a07
	movd xmm5, eax
	punpcklbw xmm5, xmm5
	punpcklwd xmm5, xmm5
	movdqa xmm1, xmm0
	psrld xmm1, 4
	pshufd xmm2, xmm5, 0xaa
	pand xmm0, xmm2
	pand xmm1, xmm2
	pshufd xmm2, xmm5, 0x55
	movdqa xmm3, xmm2
	pcmpgtb xmm2, xmm0
	pcmpgtb xmm3, xmm1
	pshufd xmm4, xmm5, 0
	pandn xmm2, xmm4
	pandn xmm3, xmm4
	pshufd xmm4, xmm5, 0xff
	paddb xmm2, xmm0
	paddb xmm3, xmm1
	paddb xmm2, xmm4
	paddb xmm3, xmm4
	movdqa xmm1, xmm3
	punpcklbw xmm1, xmm2
	punpckhbw xmm3, xmm2
	movdqu [rdi], xmm1
	movdqu [rdi + 20], xmm3
	mov eax, [rdi + 20]
	mov [rdi + 19], eax
	mov eax, [rdi + 12]
	mov [rdi + 14], eax
	mov eax, [rdi + 8]
	mov [rdi + 9], eax
	mov al, "-"
	mov [rdi + 8], al
	mov [rdi + 13], al
	mov [rdi + 18], al
	mov [rdi + 23], al
	ret

RenderHexByte:
	; in: al: byte, rdi: output address
	mov ah, al
	shr al, 4
	and ah, 15
	cmp al, 10
	cmc
	sbb dl, dl
	cmp ah, 10
	cmc
	sbb dh, dh
	and dx, 0x707
	add ax, 0x3030
	add ax, dx
	mov [rdi], ax
	ret

LoadGUID:
	; in: rsi: pointer to GUID; out: xmm0: loaded GUID (00112233-4455-6677-8899-aabbccddeeff); clobbers xmm1, r9
	mov r9, [rsi]
	bswap r9
	movq xmm0, r9
	movq xmm1, [rsi + 8]
	pslldq xmm1, 8
	pshuflw xmm0, xmm0, 0x1e
	por xmm0, xmm1
	ret
