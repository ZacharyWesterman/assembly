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

section .bss
	input_file: resq 1
	output_file: resq 1

section .text
_start:
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

		; output to file
		mov rdi, [output_file]
		call io.write


		jmp _print_contents
	_done_printing:

	xor rdi, rdi ; Exit success

_exit:
	mov rax, 60
	syscall
