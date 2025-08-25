SortPairs:
	; in: rbp: 16-byte aligned buffer with (64-bit key, 64-bit value) pairs; rbx: count
	; out: rbp, rbx preserved, buffer sorted (by key ascending), rax, rcx, rdx, rsi, rdi destroyed
	mov rdi, rbx
.recurse:
	lea rdx, [rdi + rdi - 2]
	xor ecx, ecx
	mov rsi, rdi
	and rsi, -2
	cmp rdi, 4
	jnc .quicksort_loop
	cmp edi, 2
	jc .done
	jz .check_two
	mov rax, [rbp]
	cmp rax, [rbp + 32]
	jc .skip_first_pair
	jnz .swap02
	mov rax, [rbp + 8]
	cmp rax, [rbp + 40]
	jbe .skip_first_pair
.swap02:
	movdqa xmm0, [rbp]
	movdqa xmm1, [rbp + 32]
	movdqa [rbp + 32], xmm0
	movdqa [rbp], xmm1
.skip_first_pair:
	mov rax, [rbp + 16]
	cmp rax, [rbp + 32]
	jc .check_two
	jnz .swap12
	mov rax, [rbp + 24]
	cmp rax, [rbp + 40]
	jbe .check_two
.swap12:
	movdqa xmm0, [rbp + 16]
	movdqa xmm1, [rbp + 32]
	movdqa [rbp + 32], xmm0
	movdqa [rbp + 16], xmm1
.check_two:
	mov rax, [rbp]
	cmp rax, [rbp + 16]
	jc .done
	jnz .swap01
	mov rax, [rbp + 8]
	cmp rax, [rbp + 24]
	jbe .done
.swap01:
	movdqa xmm0, [rbp]
	movdqa xmm1, [rbp + 16]
	movdqa [rbp + 16], xmm0
	movdqa [rbp], xmm1
.done:
	ret

.quicksort_loop:
	mov rax, [rbp + 8 * rcx]
	cmp rax, [rbp + 8 * rsi]
	jc .next_initial
	jnz .initial_swap
	mov rax, [rbp + 8 * rcx + 8]
	cmp rax, [rbp + 8 * rsi + 8]
	ja .initial_swap
.next_initial:
	add rcx, 2
	cmp rcx, rsi
	jc .quicksort_loop
	jmp .backwards_loop

.initial_swap:
	movdqa xmm0, [rbp + 8 * rcx]
	movdqa xmm1, [rbp + 8 * rsi]
	movdqa [rbp + 8 * rsi], xmm0
	movdqa [rbp + 8 * rcx], xmm1
.backwards_loop:
	mov rax, [rbp + 8 * rcx]
	cmp rax, [rbp + 8 * rdx]
	jc .next_backwards
	jnz .backwards_swap
	mov rax, [rbp + 8 * rcx + 8]
	cmp rax, [rbp + 8 * rdx + 8]
	ja .backwards_swap
.next_backwards:
	sub rdx, 2
	cmp rcx, rdx
	jc .backwards_loop
	jmp .exit_loops

.backwards_swap:
	movdqa xmm0, [rbp + 8 * rcx]
	movdqa xmm1, [rbp + 8 * rdx]
	movdqa [rbp + 8 * rdx], xmm0
	movdqa [rbp + 8 * rcx], xmm1
	add rcx, 2
	cmp rcx, rdx
	jz .exit_loops
.forwards_loop:
	mov rax, [rbp + 8 * rcx]
	cmp rax, [rbp + 8 * rdx]
	jc .next_forwards
	jnz .forwards_swap
	mov rax, [rbp + 8 * rcx + 8]
	cmp rax, [rbp + 8 * rdx + 8]
	ja .forwards_swap
.next_forwards:
	add rcx, 2
	cmp rcx, rdx
	jc .forwards_loop
	jmp .exit_loops

.forwards_swap:
	movdqa xmm0, [rbp + 8 * rcx]
	movdqa xmm1, [rbp + 8 * rdx]
	movdqa [rbp + 8 * rdx], xmm0
	movdqa [rbp + 8 * rcx], xmm1
	sub rdx, 2
	cmp rcx, rdx
	jc .backwards_loop
.exit_loops:
	push rbp
	lea rbp, [rbp + 8 * rcx + 16]
	shr rcx, 1
	push rcx
	sub rdi, rcx
	dec rdi
	cmp rdi, 2
	jc .skip_recursion
	call .recurse
.skip_recursion:
	pop rdi
	pop rbp
	cmp rdi, 2
	jnc .recurse
	ret
