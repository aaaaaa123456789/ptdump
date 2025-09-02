	align 4, db 0
ExecutionModeFunctions:
	dd DumpMappedMode
	dd DumpSectorsMode
	dd ListContentsMode
	dd ListContentsZeroMode
	dd ListBlocksMode
	dd 0 ; ...
	dd 0 ; ...
	dd 0 ; ...
	dd 0 ; ...
	dd 0 ; ...
	dd 0 ; ...
	dd VersionMode
	dd HelpMode
	assert ($ - ExecutionModeFunctions) / 4 == EXECUTION_MODE_OPTIONS
	dd DefaultDumpMode

OptionTables:
	align 4, db 0
.long:
	dd ProgramInformation.map
	dd ProgramInformation.dump_sectors
	dd ProgramInformation.list_contents
	dd ProgramInformation.list_contents_0
	dd ProgramInformation.list_blocks
	dd ProgramInformation.partitions
	dd ProgramInformation.sfdisk
	dd ProgramInformation.restore
	dd ProgramInformation.copy
	dd ProgramInformation.merge
	dd ProgramInformation.extract
	dd ProgramInformation.version
	dd ProgramInformation.help
	assert ($ - .long) / 4 == EXECUTION_MODE_OPTIONS
	dd ProgramInformation.data_file
	dd ProgramInformation.file_block_size
	dd ProgramInformation.max_header_size
	assert ($ - .long) / 4 == TOTAL_OPTION_FLAGS
.short:
	db "mDl0tpkrcexvhdbs"
	assert ($ - .short) == TOTAL_OPTION_FLAGS
.lengths:
	db 3, 12, 13, 15, 11, 10, 6, 7, 4, 5, 7, 7, 4, 9, 15, 15
	assert ($ - .lengths) == TOTAL_OPTION_FLAGS

	global _start:function
_start:
	mov edi, 2
	mov esi, F_GETFL
	mov eax, fcntl
	syscall
	cmp rax, -EBADF
	jnz Main
	; no stderr available; try to open /dev/null as stderr and make sure it's the null device
	mov edi, FilenameStrings.dev_null
	assert O_RDONLY == 0
	xor esi, esi
	mov eax, open
	syscall
	cmp rax, -0x1000
	jnc Abort
	mov ebx, eax
	mov edi, eax
	mov esi, zStatBuffer
	mov eax, fstat
	syscall
	cmp rax, -0x1000
	jnc Abort
	assert (S_IFMT & ~0xff00) == 0
	mov al, [zStatBuffer + st_mode + 1]
	and al, S_IFMT >> 8
	cmp al, S_IFCHR >> 8
	jnz Abort
	; device numbers are 32 bits; bits 8-19 are the major number and 0-7, 20-31 are the minor (legacy is fun)
	; the null device is a character device with major = 1, minor = 3
	cmp qword[zStatBuffer + st_rdev], 0x103
	jnz Abort
	cmp ebx, 2
	jz Main
.repeat_dup:
	mov esi, 2
	mov edi, ebx
	mov eax, dup2
	syscall
	cmp rax, -EINTR
	jz .repeat_dup
	cmp rax, -0x1000
	jnc Abort
	mov edi, ebx
	mov eax, close
	syscall
	; fallthrough

Main:
	pop rdx
	pop r15
	mov [zInputFilenames], rsp
	dec rdx
	jz NoInputsExit
	mov rsi, rsp
	mov rdi, rsp
	push 0
	assert zNoMoreOptions == zExecutionMode + 1
	mov word[zExecutionMode], EXECUTION_MODE_OPTIONS ; used as default
	lodsq
.argument_loop:
	mov ebp, Messages.empty_argument_error
	mov ebx, Messages.empty_argument_error_end - Messages.empty_argument_error
	cmp byte[rax], 0
	jz BadInvocationExit
	cmp byte[zNoMoreOptions], 0
	jnz .input
	cmp byte[rax], "-"
	jnz .input
	lea r14, [rax + 2]
	mov bl, [rax + 1]
	test bl, bl
	jz .not_escaped
	cmp bl, "-"
	jz .long_option
	cmp bl, "?"
	jz HelpMode ; deliberately undocumented, -? aliasing -h
	xor edx, edx
.short_option_test_loop:
	cmp bl, [rdx + OptionTables.short]
	jz .got_option
	inc edx
	cmp edx, TOTAL_OPTION_FLAGS
	jc .short_option_test_loop
	jmp .invalid_option_error

.long_option:
	mov rbp, r14
	call StringLength
	cmp rbx, 0x7f ; filter out huge lengths -- any "very high" value (like 0xff) is OK, but 0x7f encodes as a single byte
	jnc .invalid_option_error
	test bl, bl
	setz [zNoMoreOptions]
	jz .next_argument
	xor edx, edx
	mov r10, rdi
	mov r11, rsi
.long_option_test_loop:
	cmp bl, [rdx + OptionTables.lengths]
	jnz .next_long_option
	mov edi, [4 * rdx + OptionTables.long]
	mov ecx, ebx
	mov rsi, r14
	repz cmpsb
	jnz .next_long_option
	mov rsi, r11
	mov rdi, r10
	add r14, rbx
.got_option:
	cmp dl, EXECUTION_MODE_OPTIONS
	; -d/--data-file is right after the execution modes; -b/--file-block-size and -s/--max-header-size come right after
	jnc .argument_option
	cmp byte[r14], 0
	mov ebp, Messages.argument_given_to_option_error
	mov ebx, Messages.argument_given_to_option_error_end - Messages.argument_given_to_option_error
	jnz .option_error_exit
	cmp byte[zExecutionMode], EXECUTION_MODE_OPTIONS
	mov ebp, Messages.multiple_execution_modes_error
	mov ebx, Messages.multiple_execution_modes_error_end - Messages.multiple_execution_modes_error
	jnz BadInvocationExit
	mov [zExecutionMode], dl
	jmp .next_argument

.argument_option:
	cmp byte[r14], 0
	jnz .got_argument
	mov r14, [rsi]
	add rsi, 8
.got_argument:
	cmp dl, EXECUTION_MODE_OPTIONS
	jnz .size_option
	xchg r14, [zDataFilename]
	test r14, r14
	jz .next_argument
	mov ebp, Messages.multiple_data_files_error
	mov ebx, Messages.multiple_data_files_error_end - Messages.multiple_data_files_error
	jmp BadInvocationExit

.size_option:
	mov al, [r14]
	cmp al, "0"
	jc .invalid_size
	cmp al, "9"
	ja .invalid_size
	xor ecx, ecx
	xor eax, eax
	lea rbp, [r14 - 1]
	mov r8, 1844674407370955162 ; 2^64 / 10, rounded up
.size_loop:
	cmp rax, r8
	jnc .invalid_size
	lea rax, [rax + 4 * rax]
	add rax, rax
	add rax, rcx
	jc .invalid_size
	inc rbp
	movzx ecx, byte[rbp]
	sub ecx, "0"
	cmp ecx, 10
	jc .size_loop
	add ecx, "0"
	jz .got_shift
	sub ecx, "k" - 10
	cmp ecx, 10
	jz .got_shift
	add ecx, "k" - 10 - "M"
	cmp ecx, 20
	jnz .invalid_size
.got_shift:
	xor ebx, ebx
	shld rbx, rax, cl
	jnz .invalid_size
	shl rax, cl
	cmp dl, EXECUTION_MODE_OPTIONS + 1
	ja .header_size
	mov ebp, Messages.invalid_block_size_error
	mov ebx, Messages.invalid_block_size_error_end - Messages.invalid_block_size_error
	cmp rax, 0x40000
	ja .size_argument_error
	cmp eax, 512
	jc .size_argument_error
	test eax, 7
	jnz .size_argument_error
	xchg eax, [zDefaultFileBlockSize]
	test eax, eax
	jz .next_argument
	mov ebp, Messages.multiple_file_block_sizes_error
	mov ebx, Messages.multiple_file_block_sizes_error_end - Messages.multiple_file_block_sizes_error
	jmp BadInvocationExit

.header_size:
	mov ecx, HEADER_SIZE_LIMIT
	cmp rax, rcx
	cmovnc rax, rcx
	push rax
	mov rcx, rdi
	sub rcx, [zInputFilenames]
	shr rcx, 3
	mov [rsp + 4], ecx
	jmp .next_argument

.invalid_size:
	mov ebp, Messages.invalid_size_error
	mov ebx, Messages.invalid_size_error_end - Messages.invalid_size_error
.size_argument_error:
	call WriteError
	mov rbp, r14
	call StringLength
	mov rbp, r14
	jmp BadInvocationExit

.next_long_option:
	inc edx
	cmp edx, TOTAL_OPTION_FLAGS
	jc .long_option_test_loop
.invalid_option_error:
	mov ebp, Messages.unknown_option_error
	mov ebx, Messages.unknown_option_error_end - Messages.unknown_option_error
.option_error_exit:
	push rax
.option_error_exit_pushed:
	call WriteError
	mov rbp, [rsp]
	call StringLength
	pop rbp
	mov byte[rbp + rbx], `\n`
	inc rbx
	jmp BadInvocationExit

.input:
	cmp byte[rax], "."
	jnz .not_escaped
	cmp byte[rax + 1], "/"
	jnz .not_escaped
	add rax, 2
	cmp byte[rax], 0
	jz .argument_loop ; jump right into the error
.not_escaped:
	stosq
.next_argument:
	lodsq
	test rax, rax
	jnz .argument_loop

	mov rax, [zInputFilenames]
	mov r12, rax
	sub rdi, rax
	shr rdi, 3
	mov [zInputCount], edi
	mov r13d, edi
	shr rdi, 32
	jnz Abort
	sub rax, rsp
	shr rax, 3
	mov [zSizeSpecCount], eax
	shr rax, 32
	jnz Abort
	test r13d, r13d
	jz .go
	mov r14, rsp
	and rsp, -16
	xor edx, edx
.load_filename_list_loop:
	mov rsi, [r12 + 8 * rdx]
	push rsi
	mov rbp, rsi
	call StringLength
	cmp rbx, 0x10000
	mov ecx, ebx
	mov ebp, Messages.filename_too_long_error
	mov ebx, Messages.filename_too_long_error_end - Messages.filename_too_long_error
	jnc .option_error_exit_pushed
	call GetFilenameSortingKey
	push rdi
	inc edx
	cmp edx, r13d
	jc .load_filename_list_loop
	mov rbp, rsp
	mov ebx, r13d
	call SortPairs
	dec r13d
	jz .restore_stack
	shl r13, 4
	mov ebp, Messages.duplicate_input_filename
	mov ebx, Messages.duplicate_input_filename_end - Messages.duplicate_input_filename
.check_filename_loop:
	mov rcx, [rsp + r13]
	cmp rcx, [rsp + r13 - 16]
	jnz .next_filename
	movzx ecx, cx
	mov rsi, [rsp + r13 + 8]
	mov rax, rsi
	mov rdi, [rsp + r13 - 8]
	repz cmpsb
	jz .option_error_exit
.next_filename:
	sub r13, 16
	jnz .check_filename_loop
.restore_stack:
	mov rsp, r14
.go:
	movzx eax, byte[zExecutionMode]
	mov eax, [4 * rax + ExecutionModeFunctions]
	jmp rax

NoInputsExit:
	mov edi, zStringBuffer
	mov esi, ProgramInformation
	copybytes ProgramInformation.usage - ProgramInformation
	mov esi, Messages.no_inputs_1
	copybytes Messages.no_inputs_1_end - Messages.no_inputs_1
	mov rbp, r15
	call StringLength
	; 432 = size of zStringBuffer
	mov ecx, 432 - (ProgramInformation.usage - ProgramInformation) \
	             - (Messages.no_inputs_1_end - Messages.no_inputs_1) \
	             - (Messages.no_inputs_2_end - Messages.no_inputs_2)
	cmp rbx, rcx
	cmovc ecx, ebx
	mov rsi, r15
	rep movsb
	mov esi, Messages.no_inputs_2
	copybytes Messages.no_inputs_2_end - Messages.no_inputs_2
	mov ebp, zStringBuffer
	sub edi, ebp
	mov ebx, edi
BadInvocationExit:
	call WriteError
	mov edi, 3
	jmp ExitProgram

VersionMode:
	mov ebp, ProgramInformation
	mov ebx, ProgramInformation.usage - ProgramInformation
	jmp BadInvocationExit

HelpMode:
	mov edi, zStringBuffer
	mov esi, ProgramInformation
	copybytes ProgramInformation.usage - ProgramInformation
	mov rbp, r15
	call StringLength
	mov ecx, 431 - (ProgramInformation.usage - ProgramInformation)
	cmp rbx, rcx
	cmovc ecx, ebx
	mov rsi, r15
	rep movsb
	mov ebp, zStringBuffer
	sub edi, ebp
	mov ebx, edi
	call WriteError
	mov ebp, ProgramInformation.usage
	mov ebx, ProgramInformation.end - ProgramInformation.usage
	jmp BadInvocationExit
