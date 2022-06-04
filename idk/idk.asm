extern GetStdHandle
extern WriteFile
extern ExitProcess
extern GetProcessHeap
extern HeapAlloc
extern HeapCreate

section .rodata
    char_table        db  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    STD_INPUT_HANDLE  equ -10
    STD_OUTPUT_HANDLE equ -11

section .data
    stdout            dw   0
    bytes_written     dw   0

section .text
    global start
    
    %macro print 2
    mov rdx, %1
    mov r8,  %2
    mov rcx, r14
    call print_ascii
    %endmacro
    %macro print 1
    print %1, 10
    %endmacro

start:
    call GetProcessHeap
    ;mov rcx, 0
    ;mov rdx, 1024
    ;mov r8, 1024*1024
    ;call HeapCreate
    mov r15, rax

; #region GET STDIN/OUT HANDLES ;
    mov  rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [rel stdout], rax
    
    mov  rcx, STD_INPUT_HANDLE
    call GetStdHandle
    ;mov  rcx, 1000
    ;mov  [stdin], rax
; #endregion ;

    mov rcx, r15
    mov rdx, 0
    mov r8,  0xFF ;should be more than enough for a 64-bit number
    call HeapAlloc
    mov r14, rax
    add r14, 0xFF ;r14 points to end of heap

    mov rcx, r14
    mov rdx, stdout;1689498
    mov r8,  16
    call print_ascii

    ;xor  rcx, rcx
    ;call ExitProcess
tst:
    nop
    jmp tst





print_ascii: ;buffer ptr rcx IN, number rdx IN, numerical base r8 IN, length rax OUT
    xor r9, r9

    push r15 ;r15 should be preserved
    mov  r15, 2

;iterate, on each div by base^(i+1) & store mod as char
    mov rax, rdx

    print_ascii_loop:
        xor rdx,  rdx
        div qword r8

        mov  r10,   char_table
        add  rdx,   r10
        mov  r11b, [rdx]
        mov [rcx],  r11b

        inc r9
        dec rcx
    cmp rax, r8
    jge print_ascii_loop

    dec r15
    jnz print_ascii_loop ;an extra iteration is needed at the end for... reasons?
    pop r15
    
    mov  rdx,  rcx
    inc  rdx
    mov  rcx, [rel stdout]
    mov  r8,   r9
    mov  r9,   bytes_written
    push qword 0
    call WriteFile

    ret