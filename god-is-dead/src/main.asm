extern GetStdHandle
extern WriteConsoleA
extern ExitProcess
extern GetLastError
extern RaiseException

section .rodata
    char_table        db  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    cht_len           equ $-char_table
    STD_INPUT_HANDLE  equ -10
    STD_OUTPUT_HANDLE equ -11
    CRLF              db  0x0D, 0x0A

section .data
    ;stdout            dw   0
    ;bytes_written     dw   0

section .text
    global start

    %macro endl 0
        mov  rcx, STD_OUTPUT_HANDLE
        call GetStdHandle
        mov  rcx, rax
        mov  rdx,  CRLF
        mov  r8,   2
        mov  r9,   0
        call WriteConsoleA
    %endmacro
    
    %macro printi 1
        printi %1, 10
    %endmacro
    %macro printi 2
        mov rcx, %1
        mov rdx, %2
        call print_int
    %endmacro

    %macro prints 2
        mov rcx, %1
        mov rdx, %2
        call print_str
    %endmacro
    
    ok     db  "SUCCESS"
    ok_len equ $-ok

start:
    printi 5198721
    endl
    endl
    prints ok, ok_len
    endl
    xor  rcx, rcx
    ;jmp inf
call ExitProcess



print_str: ;string ptr rcx IN, len rdx IN
    push rcx
    mov  rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov  r14, rax ;get stdout handle to r14
    pop  rcx
    
    mov  r9,   0
    mov  r8,   rdx
    mov  rdx,  rcx
    mov  rcx,  r14
    call WriteConsoleA
ret



print_int: ;number rcx IN, numerical base rdx IN
    push r15 ;r11 through r15 should be preserved
    push r14
    
    push rcx
    mov  rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov  r14, rax ;get stdout handle to r14
    pop  rcx

    mov  r15, 2

    ;mov  r9,  2
    ;dec  rsp
    ;mov  byte [rsp], 0x0A ;LF
    ;dec  rsp
    ;mov  byte [rsp], 0x0D ;CR

    xor  r9, r9
    mov  r8, rdx

;iterate, on each div by base^(i+1) & store mod as char
    mov  rax, rcx

    print_int_loop:
        xor rdx,  rdx
        div qword r8

        mov  r10,   char_table
        add  rdx,   r10
        mov  r11b, [rdx]
        dec  rsp
        mov [rsp], r11b
        ;mov [rcx],  r11b

        inc r9
        ;dec rcx
    cmp rax, 0
    jne print_int_loop
    
    mov  r15,  r9
    
    mov  rdx,  rsp;rcx
    mov  rcx,  r14
    mov  r8,   r9
    mov  r9,   0
    call WriteConsoleA

    add  rsp,  r15

    pop  r14
    pop  r15
ret

err:
    call GetLastError

    mov rcx, rax ;err code
    mov rdx, 1   ;non-continuable
    mov r8,  0
    mov r9,  0
    call RaiseException

infl:
    nop
jmp infl