default rel

extern GetStdHandle
extern WriteConsoleA
extern ReadConsoleA
extern ExitProcess
extern GetLastError
extern RaiseException
extern GetSystemInfo
extern GetProcessHeap
extern HeapAlloc
extern HeapFree
extern GetSystemTime
extern GetTimeZoneInformation
extern Sleep


section .rodata
    DEC_TABLE            db   "0123456789",0
    HEX_TABLE            db   "0123456789ABCDEF",0
    ALPHABET             db   "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",0
    CIPHERTEXT_RAW       db   "DePk6rqSKIcsDzx177WKCeD6uEYOo3iRkMszgy1sMJLD8rbSSP2J+FGF3L3yL8GmQQAA",0
    CIPHERTEXT           db   3,30,15,36,58,43,42,18,10,8,28,44,3,51,49,53,59,59,22,10,2,30,3,58,46,4,24,14,40,55,34,17,36,12,44,51,32,50,53,44,12,9,11,3,60,43,27,18,18,15,54,9,62,5,6,5,55,11,55,50,11,60,6,38,16,16,0,0
    CRLF                 db   0x0D, 0x0A
    CR                   equ  0x0D
    LF                   equ  0x0A
    STD_INPUT_HANDLE     equ -10
    STD_OUTPUT_HANDLE    equ -11
    MAX_KEY_SIZE         equ  16
    CIPHERTEXT_LENGTH    equ  68
    DECODED_UTF8_LENGTH  equ  51

section .data
    HEAP_HANDLE       dq  0
    STDOUT            dq  0
    STDIN             dq  0

    CURRENT_TIME      dq  0
    CURRENT_TIMEZONE  dq  0

    INPUT_BUFFER      dq  0
    INPUT_LEN         dq  0

    THREAD_COUNT      dq  0
    OPS_PER_THREAD    dq  20_000_000
    CURRENT           dq  0
    CURRENT_ASCII     dq  0
    CURRENT_LENGTH    dq  0

    DECODED_BASE64    dq  0
    DECODED_UTF8      dq  0

section .text
    global start

    input_inv         db  "Invalid, try again. ",0
    input_s           db  "Selected ",0
    input_sdef        db  "a default of ",0
    
    input_tc          db  "Input thread count (empty for default): ",0
    input_tc_t        db  " threads.",0

    input_opt         db  "Input operations per thread-iteration (empty for def.): ",0
    input_opt_o       db  " operations per thread.",0

    input_sa          db  "Input start_at value (empty for def.): ",0

    start_a           db  "Starting at ",0
    start_w           db  " with ",0
    start_t           db  " threads @ ",0
    start_opti        db  " ops/ti...",0

    ok    db  "SUCCESS",0
    errs  db  "ERROR CODE ",0


start:
;--------------SETUP CONSOLE--------------;
    mov  rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [STDOUT], rax

    mov  rcx, STD_INPUT_HANDLE
    call GetStdHandle
    mov [STDIN],  rax

;--------------SETUP HEAP--------------;
    call GetProcessHeap
    mov [HEAP_HANDLE], rax
    ;printi [HEAP_HANDLE], 1, 16

    heap_alloc 16
    mov [CURRENT_TIME], rax

    heap_alloc 172
    mov [CURRENT_TIMEZONE], rax

;--------------GET LCC--------------;
    heap_alloc 64
    
    push rax
    push rax

    mov rcx, rax
    call GetSystemInfo

    pop rax
    xor rcx, rcx
    mov cl, [rax+32]
    mov [THREAD_COUNT], cl
    
    mov rcx, [HEAP_HANDLE]
    mov rdx,  0
    pop r8
    call HeapFree
    check_err

;--------------THREAD SELECT--------------;
    heap_alloc 256
    mov [INPUT_BUFFER], rax

    call print_time_str
    input_tcs: prints input_tc

    call input
    
    call print_time_str

    cmp qword  [INPUT_LEN], 0
    je  if_tc_null
        parse_str INPUT_BUFFER, [INPUT_LEN]
        test rax, rax
        jne  if_tc_valid
            prints input_inv
            clear_str INPUT_BUFFER
            jmp    input_tcs
        if_tc_valid:
            mov [THREAD_COUNT], rax
            prints  input_s
    jmp if_tc_null_end
    if_tc_null:
        prints  input_s
        prints  input_sdef
    if_tc_null_end:
    printi [THREAD_COUNT]
    prints input_tc_t, 1

;--------------OPS PER THREAD SELECT--------------;
    call print_time_str
    input_opts: prints input_opt

    call input
    
    call print_time_str

    cmp qword  [INPUT_LEN], 0
    je  if_opt_null
        parse_str INPUT_BUFFER, [INPUT_LEN]
        cmp  rax,  0
        jne  if_opt_valid
            prints input_inv
            clear_str INPUT_BUFFER
            jmp    input_opts
        if_opt_valid:
            mov [OPS_PER_THREAD], rax
            prints  input_s
    jmp if_opt_null_end
    if_opt_null:
        prints  input_s
        prints  input_sdef
    if_opt_null_end:
    printi [OPS_PER_THREAD]
    prints input_opt_o, 1

;--------------START AT SELECT--------------;
    heap_alloc MAX_KEY_SIZE
    mov [CURRENT], rax
    heap_alloc MAX_KEY_SIZE, 0x8
    mov [CURRENT_ASCII], rax

    call print_time_str
    input_sas: prints input_sa
    
    call input

    cmp qword [INPUT_LEN], 0
    je  if_sa_null
        cmp qword [INPUT_LEN], MAX_KEY_SIZE
        jle if_sa_valid
            prints input_inv
            clear_str INPUT_BUFFER
            jmp    input_sas
        if_sa_valid:
            copy_str   INPUT_BUFFER, [CURRENT]
            push qword [INPUT_LEN]
            pop  qword [CURRENT_LENGTH]
    jmp if_sa_null_end
    if_sa_null:
        mov rax,  [CURRENT]
        mov qword [rax], 0x000000 ;indexes corresponding to AAA
        mov qword [CURRENT_LENGTH], 3
        ;mov [CURRENT],           rax
    if_sa_null_end:

;--------------START COMPUTE ST--------------;
    heap_alloc CIPHERTEXT_LENGTH
    mov [DECODED_BASE64], rax
    heap_alloc DECODED_UTF8_LENGTH
    mov [DECODED_UTF8], rax

    call    print_time_str
    prints  start_a
    call    current_to_str
    prints [CURRENT_ASCII], 0, [CURRENT_LENGTH]
    prints  start_w
    printi [THREAD_COUNT]
    prints  start_t
    printi [OPS_PER_THREAD]
    prints  start_opti, 1

    
    mov r8,  [DECODED_BASE64]
    mov r9,   CIPHERTEXT
    mov r10, [CURRENT]
    mov r11, [CURRENT_LENGTH]
    xor r12, r12
    
    compute_loop_inf:
        mov rcx, [OPS_PER_THREAD]
        compute_loop:
            xor rbx, rbx

            ciphertext_loop:
                mov rax, rbx

                xor rdx, rdx
                div qword r11
                mov r12b, [r9+rbx]

                sub  r12b, [r10+rdx]
                test r12b,  r12b
                jnl  ciphertext_no_underflow
                    add r12b, 64
                ciphertext_no_underflow:
                mov  r14,     ALPHABET
                mov  r13b,   [r12+r14]
                mov [r8+rbx], r13b

                inc rbx
            cmp rbx, CIPHERTEXT_LENGTH
            jl  ciphertext_loop

            push_all
            mov [CURRENT_LENGTH], r11
            call print_time_str
            call current_to_str
            prints [CURRENT_ASCII], 0, r11
            q ": "
            prints [DECODED_BASE64], 1, CIPHERTEXT_LENGTH

            mov rcx, 250
            call Sleep
            pop_all

            call cadd_one
        dec rcx
        jnz compute_loop
    jmp compute_loop_inf




    endl 2
    call print_time_str
    prints ok
    xor  rcx, rcx
call ExitProcess


cadd_one:; r10 ptr IN, r11 len IN/OUT, r15 EMPTY PLS
    mov r15, r10
    mov rbx, r11

    cadd_one_loop:
        cmp byte [r15], 63
        je cadd_one_eq63
            inc byte [r15]
            ret
        cadd_one_eq63:
        mov byte [r15], 0
        inc r15
    dec rbx
    jnz cadd_one_loop

    inc r11
ret


print_time_str: ;rcx optional hour offset
    mov   rcx, [CURRENT_TIMEZONE]
    call  GetTimeZoneInformation
    mov   rcx, [CURRENT_TIMEZONE]
    movsx rdx,  dword [rcx]
    cmp   rax,  2
    jne   if_dst_end
        movsx rax, dword [rcx+168]
        add   rdx, rax
    if_dst_end:
    neg   rdx

    mov  rcx, rdx
    call min_to_hmin
    push rcx
    push rax


    mov  rcx, [CURRENT_TIME]
    call GetSystemTime
    mov  rcx, [CURRENT_TIME]
    
    xor rax, rax
    mov  ax, word [rcx+8]

    pop rdx
    add rax, rdx
    
    cmp rax, 10
    jge if_hours_lower_10_end
        push qword '0'
        prints rsp, 0,1
        add rsp, 8
    if_hours_lower_10_end:

    printi rax
    push qword ':'
    prints rsp, 0, 1
    
    add rsp, 8
    mov rcx, [CURRENT_TIME]
    mov ax, word [rcx+10]
    pop rdx
    add rax, rdx
    cmp rax, 10
    jge if_mins_lower_10_end
        push qword '0'
        prints rsp, 0,1
        add rsp, 8
    if_mins_lower_10_end:
    printi rax
    push qword ':'
    prints rsp, 0, 1
    
    mov rcx, [CURRENT_TIME]
    mov ax, word [rcx+12]
    cmp rax, 10
    jge if_secs_lower_10_end
        push qword '0'
        prints rsp, 0,1
        add rsp, 8
    if_secs_lower_10_end:
    printi rax
    push qword '.'
    prints rsp, 0, 1

    xor rax, rax
    
    mov rcx, [CURRENT_TIME]
    mov ax, word [rcx+14]
    cmp rax, 10
    jge if_ms_lower_10_end
        push qword '0'
        prints rsp, 0,1
        add rsp, 8
    if_ms_lower_10_end:
    cmp rax, 100
    jge if_ms_lower_100_end
        push qword '0'
        prints rsp, 0,1
        add rsp, 8
    if_ms_lower_100_end:
    printi rax

    push qword ': '
    prints rsp, 0, 2
    add rsp, 24
ret

min_to_hmin: ;rcx min IN/OUT, rax h OUT
    push rdx

    xor rdx, rdx
    mov rax, rcx
    cqo

    mov rcx, 60
    idiv rcx

    mov rcx, rdx

    pop rdx
ret

current_to_str: ;no args, affects [CURRENT_ASCII]
    push_all

    mov rax, [CURRENT]
    mov rcx,  ALPHABET
    mov rdx, [CURRENT_ASCII]
    mov r8,  [CURRENT_LENGTH]

    xor rbx, rbx
    xor r9,  r9

    current_to_str_loop:
        dec r8

        mov  bl, [rax+r8]
        mov  r9b, [rcx+rbx]
        mov [rdx+r8], r9b
    test r8, r8
    jg  current_to_str_loop

    pop_all
ret

copy_strf: ;src ptr rcx IN, dest ptr rdx IN, optional len r8 IN
    push_all

    test r8, r8
    je   copy_strf_ret
    cmp  r8, -1
    jne copy_strf_len_known
    copy_strf_loop:
        mov  r9b,  [rcx]
        mov [rdx],  r9b
        inc  rcx
        inc  rdx
    cmp byte [rcx], 0
    jne copy_strf_loop
    jmp copy_strf_ret
    copy_strf_len_known:
    push rcx
    mov  rcx, r8
    pop  r8
    copy_strfk_loop:
        mov  r9b,  [r8]
        mov [rdx],  r9b
        inc  r8
        inc  rdx
    loop copy_strfk_loop

    copy_strf_ret:
    pop_all
ret

clear_strf: ;ptr rcx IN, optional len rdx IN
    push_all

    test rdx, rdx
    je   clear_strf_ret
    cmp  rdx, -1
    jne clear_strf_len_known
    clear_strf_loop:
        mov byte [rcx], 0
        inc       rcx
    cmp byte [rcx], 0
    jne clear_strf_loop
    jmp clear_strf_ret
    clear_strf_len_known:
    push rcx
    mov  rcx, rdx
    pop  rdx
    clear_strfk_loop:
        mov byte [rdx], 0
        inc       rdx
    loop clear_strfk_loop

    clear_strf_ret:
    pop_all
ret

input: ;no args
    push_all
    mov  rcx, [STDIN]
    mov  rdx,  INPUT_BUFFER
    mov  r8,   256
    mov  r9,   INPUT_LEN
    push qword 0
    call ReadConsoleA
    check_err
    sub qword [INPUT_LEN], 2
    add rsp,   8
    pop_all
ret


parse_string: ;string ptr rcx IN, len rdx IN, u64 rax OUT
    xor rax, rax
    mov r8,  rcx
    xor r9,  r9
    mov r10, 10

    parse_string_loop:
        mov       r9b,   byte [r8]
        movq      xmm0,  r9
        pcmpistri xmm0, [DEC_TABLE], 0b_00_00_11_00
        cmp       rcx,   16
        je        parse_string_invalid

        push rdx
            xor  rdx, rdx
            mul  r10
            add  rax, rcx
        pop rdx

        inc r8
    dec  rdx
    test rdx, rdx
    jne  parse_string_loop
ret
parse_string_invalid:
    xor rax, rax
ret


endlf: ;number of endls rcx IN
    push_all
    endlf_loop:
    test rcx, rcx
    je   endlf_ret
        push rcx
        
        mov  rcx, [STDOUT];rax
        mov  rdx,  CRLF
        mov  r8,   2
        mov  r9,   0
        call WriteConsoleA
        pop rcx
        dec rcx
    jmp endlf_loop
    endlf_ret:
    pop_all
ret

print_str: ;string ptr rcx IN, optional len rdx IN
    push_all

    test rdx, rdx
    je  print_str_ret
    cmp rdx, -1
    jne print_str_len_known
        mov rdx, rcx

        print_str_loop:
            inc rdx
        cmp byte [rdx], 0
        jne print_str_loop
        sub rdx,   rcx
    print_str_len_known:
    
    mov  r9,   0
    mov  r8,   rdx
    mov  rdx,  rcx
    mov  rcx,  [STDOUT]
    call WriteConsoleA
    print_str_ret:
    pop_all
ret

print_bytes: ;ptr rcx IN, length rdx IN
    push_all

    push rcx
    mov  rcx, rdx
    pop  rdx

    print_bytes_loop:
        inc     rdx

        push   rcx
        push   rdx
        mov    cl, byte [rdx]
        printi rcx, 0, 16, 0
        push   byte ' '
        prints rsp, 0, 1
        dec    rsp
        pop    rdx
        pop    rcx
    loop print_bytes_loop

    pop_all
ret

print_int: ;number rcx IN, numerical base rdx IN, format bool r8 IN
    push_all
    
    mov  r15, 2

    mov  r14, rdx

    ;mov  r9,  2
    ;dec  rsp
    ;mov  byte [rsp], 0x0A ;LF
    ;dec  rsp
    ;mov  byte [rsp], 0x0D ;CR

    xor  r9, r9

    ;iterate, on each div by base^(i+1) & store mod as char
    mov  rax, rcx

    print_int_loop:
        inc r9

        test r8,  r8
        je   if_bin_end
        cmp  r14, 2
        jne  if_bin_end
            push rax
            mov  rax, r9
            xor  rdx, rdx
            mov  rcx, 5  ;should be 4 idk why it has to be 5
            div  rcx
            test rdx, rdx
            pop  rax
            jne if_bin_end
                dec  rsp
                mov  byte [rsp], '_'
                inc  r9
        if_bin_end:

        xor rdx,  rdx
        div qword r14

        mov  r10,   HEX_TABLE
        add  rdx,   r10
        mov  r11b, [rdx]
        dec  rsp
        mov [rsp],  r11b
    test rax, rax
    jne  print_int_loop

    test r8,  r8
    je   if_hex_end
    cmp  r14, 16
    jne  if_hex_end
        dec  rsp
        mov  byte [rsp], 'x'
        dec  rsp
        mov  byte [rsp], '0'
        add  r9,   2
    if_hex_end:
    
    mov  r15,  r9
    
    mov  rdx,  rsp
    mov  rcx, [STDOUT]
    mov  r8,   r9
    mov  r9,   0
    call WriteConsoleA

    add  rsp,  r15

    pop_all
ret


err:
    call GetLastError
    endl 2
    prints errs
    printi [rsp]

    mov rcx, rax ;err code
    mov rdx, 1   ;non-continuable
    mov r8,  0
    mov r9,  0
call RaiseException


infl: nop
jmp infl