extern GetStdHandle
extern WriteConsoleA
extern ExitProcess

section .text
    global start
start:
    mov  rcx, -11
    call GetStdHandle
    
    push byte '8'
    
    mov  rcx, rax
    mov  rdx, rsp
    mov  r8,  1
    mov  r9,  0
    call WriteConsoleA
call ExitProcess