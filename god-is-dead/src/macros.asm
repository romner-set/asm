
%macro endl 0
    endl 1
%endmacro
%macro endl 1
    ;push_all
    mov rcx, %1
    call endlf
    ;pop_all
%endmacro

%macro printi 1
    printi %1,  0, 10, 1
%endmacro
%macro printi 2
    printi %1, %2, 10, 1
%endmacro
%macro printi 3
    printi %1, %2, %3, 1
%endmacro
%macro printi 4
    ;push_all
    mov  rcx, %1
    mov  rdx, %3
    mov  r8,  %4
    call print_int
    endl %2
    ;pop_all
%endmacro

%macro prints 1
    prints %1, 0, -1
%endmacro
%macro prints 2
    prints %1, %2, -1
%endmacro
%macro prints 3
    ;push_all
    mov  rcx, %1
    mov  rdx, %3
    call print_str
    endl %2
    ;pop_all
%endmacro

%macro printb 2
    printb %1, %2, 0
%endmacro
%macro printb 3
    ;push_all
    mov rcx, %1
    mov rdx, %2
    call print_bytes
    endl %3
    ;pop_all
%endmacro

%macro check_err 0
    cmp rax,  0
    je  err
%endmacro

%macro push_all 0
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rdx
    push rcx
    push rbx
    push rax
%endmacro

%macro pop_all 0
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15
%endmacro

%macro heap_alloc 1
    mov r8,   %1
    mov rdx,  0
    mov rcx, [HEAP_HANDLE]
    call HeapAlloc
    check_err
%endmacro

%macro parse_str 2
    mov rcx, %1
    mov rdx, %2
    call parse_string
%endmacro
%macro parse_str 1
    parse_str %1, -1
%endmacro

%macro copy_str 2
    copy_str %1, %2, -1
%endmacro
%macro copy_str 3
    mov rcx, %1
    mov rdx, %2
    mov r8,  %3
    call copy_strf
%endmacro

%macro clear_str 1
    clear_str %1, -1
%endmacro
%macro clear_str 2
    mov rcx, %1
    mov rdx, %2
    call clear_strf
%endmacro

%macro q 1
    push qword %1
    prints rsp
    add rsp, 8
%endmacro
