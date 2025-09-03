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
