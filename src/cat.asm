global _start
extern io.print
extern io.open
extern io.read

extern io.stdin

section .bss
	file_pointer: resq 1

section .text
_start:
	pop rax ;argc
	cmp rax, 1
	jg _open_file
	;If no file specified in argv[1], read from stdin
	mov rax, io.stdin
	mov [file_pointer], rax
	jmp _print_contents

	_open_file:
	pop rax ; argv[0]
	pop rax ; argv[1]
	mov rbx, 'r'
	call io.open
	mov [file_pointer], rax

	; if open file failed, return error code
	test rax, rax
	jl _exit_error

	_print_contents:
	; Read file contents and print them
	mov rax, [file_pointer]
	call io.read

	; While there's more input, read another chunk
	test rbx, rbx
	jle _done_printing
	call io.print
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
