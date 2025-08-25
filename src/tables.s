GetPartitionTableType:
	; in: rdi: pointer to partition data, esi: block size
	; out: rax: 0 = unknown, 1 = MBR, 2 = GPT; rdi, rsi unchanged
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
	cmp [rdi + rsi], rdx
	jnz .done
	mov edx, [rdi + rsi + 12]
	cmp edx, 92
	jc .done
	cmp edx, esi
	ja .done
	cmp qword[rdi + rsi + 24], 1
	jnz .done
	mov edx, [rdi + rsi + 84]
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
