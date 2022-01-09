global io.print
global io.error
global io.input
global io.open
global io.read
global io.write

global io.stdin
global io.stdout
global io.stderr

section .data
	io.stdout: equ 0
	io.stdin: equ 1
	io.stderr: equ 2

	SYS_OPEN: equ 2
	O_RDONLY: equ 0
	O_WRONLY: equ 1

section .bss
	input_buffer: resb 4096
	input_bufsiz: equ 4096

section .text

;Input
; rax: string data
; rbx: string size
;
;Output: none
io.print:
	mov rdi, io.stdout
	jmp io.write

;Input
; rax: string data
; rbx: string size
;
;Output: none
io.error:
	mov rdi, io.stderr
	jmp io.write

io.write:
	push rdx

	mov rsi, rax
	mov rdx, rbx
	mov rax, 1 ;__NR_write
	syscall

	pop rdx
	ret

; Input
; rax: file descriptor
;
;Output
; rax: string data
; rbx: string size
io.read:
	push rdx

	mov rdi, rax
	mov rsi, input_buffer
	mov rdx, input_bufsiz
	xor rax, rax ;__NR_read is 0
	syscall

	pop rdx

	mov rbx, rax
	mov rax, input_buffer
	ret

; Input
; rax: file name (string) [null-terminated]
; rbx: open mode [either 'r' or 'w']
;
;Output
; rax: file descriptor [negative if failed]
io.open:
	mov rsi, O_RDONLY
	cmp rbx, 'r'
	je _begin_open
	mov rsi, O_WRONLY
	cmp rbx, 'w'
	je _begin_open
	;If mode isn't 'r' or 'w', return error (-1)
	mov rax, -1
	ret

	_begin_open:
	push rdx

	mov rdi, rax
	mov rax, SYS_OPEN
	mov rdx, 0644o
	syscall

	pop rdx
	ret
