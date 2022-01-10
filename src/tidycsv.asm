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

	progress: db "|/-\"
	rst: db 0x0c

	delim: equ ','

section .bss
	input_file: resq 1
	output_file: resq 1
	is_quoted: resq 1
	is_escaped: resq 1

	output_buffer: resb 4096

	chunk_number: resq 1

section .text
_start:
	;setup data
	xor rax, rax
	mov [is_quoted], rax
	mov [is_escaped], rax

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

			mov dh, [rax, rcx]

			; cmp dh, delim
			; jz _next_lp
			cmp dh, 0x0d
			jz _next_lp

			_append_to_output:
			mov [output_buffer, rcx], dh

			add rcx, 1
			_next_lp:
			sub rbx, 1
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
