global _start
extern io.open
extern io.read
extern io.write

extern io.stdin
extern io.stdout
extern io.stderr

section .data
	help_msg: db "Usage: tidycsv {input_file} {output_file}", 0x0a
	help_msg_len: equ $ - help_msg

	delim: equ ','

section .bss
	input_file: resq 1
	output_file: resq 1
	is_quoted: resq 1
	is_escaped: resq 1
	found_cr: resq 1
	is_begin_item: resq 1

	output_buffer: resb 4096

	chunk_number: resq 1

section .text
_start:
	;setup data
	xor rax, rax
	mov [is_quoted], rax
	mov [is_escaped], rax
	mov [found_cr], rax
	mov rax, 1
	mov [is_begin_item], rax

	; check argc
	pop rax ;argc
	cmp rax, 2
	jg _open_files

	;If no input & output files specified in args, print error
	mov rdi, io.stderr
	mov rax, help_msg
	mov rbx, help_msg_len
	call io.write
	mov rdi, 1 ;Error code
	jmp _exit

	_open_files:
	pop rax ; argv[0]
	pop rax ; argv[1]
	mov rbx, 'r'
	call io.open
	mov [input_file], rax

	; if open file failed, return error code
	mov rdi, 2
	test rax, rax
	jl _exit

	pop rax ; argv[2]
	mov rbx, 'w'
	call io.open
	mov [output_file], rax

	mov rdi, [output_file]
	test rax, rax
	jl _exit

	_print_contents:
		mov rax, [input_file]
		call io.read

		; While there's more input, read another chunk
		cmp rbx, 0
		je _done_printing

		mov rcx, 0
		_lp:
			cmp rbx, 0
			jz _lp_end

			xor rdx, rdx
			mov dl, [rax] ;dh contains this character
			add rax, 1
			push rax

			; If we're at the beginning of an item, skip quotes
			mov rax, [is_begin_item]
			cmp rax, 0
			jz _not_begin_item
			xor rax, rax
			mov [is_begin_item], rax

			cmp dl, '"'
			jnz _not_begin_item ;Not in quotes
			mov rax, 1
			mov [is_quoted], rax
			jmp _next_lp
			_not_begin_item:

			;If we're in quotes, convert delim or \r to space,
			; and if this char is ", skip it.
			mov rax, [is_quoted]
			cmp rax, 1
			jnz _not_inside_quot ;Not in quotes
			cmp dl, '"'
			jnz _chk2
			xor rax, rax
			mov [is_quoted], rax
			jmp _next_lp
			_chk2:
			cmp dl, delim
			jnz _not_inside_quot
			cmp dl, 0x0d
			jnz _not_inside_quot
			mov dl, ' '
			_not_inside_quot:


			; if this character is LF and last char was CR
			mov rax, [found_cr]
			add rax, rdx
			cmp rax, 0x0b
			jnz _after_chk_crlf
			;then set prev char to this one, and skip
			sub rcx, 1
			_after_chk_crlf:

			; if this character is a delim or newline, we're at the beginning of an item
			cmp rax, 0x0b
			jz _after_chk_begin
			cmp dl, delim
			jz _after_chk_begin
			mov rax, 0
			_after_chk_begin:
			mov [is_begin_item], rax

			; if this character is CR,
			; make a note of that
			xor rax, rax
			cmp dl, 0x0d
			jnz _cif_ret ; if this char != '\r'
			mov rax, 1
			_cif_ret:
			mov [found_cr], rax

			mov rax, [is_quoted]
			cmp rax, 0
			jz _not_end_quot
			cmp dl, '"'
			jnz _not_end_quot ;Not in quotes
			xor rax, rax
			mov [is_quoted], rax
			jmp _next_lp
			_not_end_quot:

			_append_to_output:
			mov [output_buffer, rcx], dl

			add rcx, 1
			_next_lp:
			sub rbx, 1
			pop rax
			jmp _lp
		_lp_end:

		; output to file
		mov rax, output_buffer
		mov rbx, rcx
		; mov rdi, io.stdout
		mov rdi, [output_file]
		call io.write

		; TEMP: don't loop again
		jmp _print_contents
	_done_printing:

	xor rdi, rdi ; Exit success

_exit:
	mov rax, 60
	syscall
