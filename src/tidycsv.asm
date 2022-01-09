global _start
extern io.open
extern io.read
extern io.write

extern io.stdin
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
	mov rdi, io.stdin
	mov rax, help_msg
	mov rbx, help_msg_len
	call io.write
	mov rax, 1 ;Error code
	jmp _exit_error

	_open_files:
	pop rax ; argv[0]
	pop rax ; argv[1]
	mov rbx, 'r'
	call io.open
	mov [input_file], rax

	; if open file failed, return error code
	test rax, rax
	jl _exit_error

	pop rax ; argv[2]
	mov rbx, 'w'
	call io.open
	mov [output_file], rax

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

_exit_success:
	;Exit
	xor rdi, rdi ;set exit code to 0 (no error)
	jmp _exit

_exit_error:
	mov rdi, rax

_exit:
	mov rax, 60
	syscall
