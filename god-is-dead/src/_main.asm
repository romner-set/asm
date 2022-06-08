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


section .rodata
    dec_table         db  "0123456789",0
    hex_table         db  "0123456789ABCDEF",0
    CRLF              db  0x0D, 0x0A
    STD_INPUT_HANDLE  equ -10
    STD_OUTPUT_HANDLE equ -11
    MAX_KEY_SIZE      equ 16

section .data
    HEAP_HANDLE       dq  0
    STDOUT            dq  0
    STDIN             dq  0

    CURRENT_TIME      dq  0
    CURRENT_TIMEZONE  dq  0

    INPUT_BUFFER      dq  0
    INPUT_LEN         dq  0

    THREAD_COUNT      dq  0
    OPS_PER_THREAD    dq  1
    START_AT          dq  0
    START_AT_LEN      dq  0

section .text
    global start

    input_inv         db  "Invalid, try again. ",0
    input_s           db  "Selected ",0
    input_sdef        db  "a default of ",0
    
    input_tc          db  "Input thread count (empty for default): ",0
    input_tc_t        db  " threads.",0

    input_opt         db  "Input operations per thread-iteration (empty for def.):",0
    input_opt_o       db  " operations per thread.",0

    input_sa          db  "Input start_at value (empty for def.): ",0

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

    call print_time_str

    endl

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

    input_tcs: prints input_tc

    call input

    cmp qword  [INPUT_LEN], 0
    je  if_tc_null
        parse_str INPUT_BUFFER, [INPUT_LEN]
        cmp  rax,  0
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
    input_opts: prints input_opt

    call input

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
    mov [START_AT], rax

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
            copy_str   INPUT_BUFFER, [START_AT]
            push qword [INPUT_LEN]
            pop  qword [START_AT_LEN]
    jmp if_sa_null_end
    if_sa_null:
        mov qword [rax],          "AAA";,0
        mov qword [START_AT_LEN], 3
        mov [START_AT],           rax
    if_sa_null_end:
    prints [START_AT], 1, [START_AT_LEN]
    printi [START_AT_LEN]
    
;--------------START COMPUTE ST--------------;


    endl 2
    prints ok
    xor  rcx, rcx
call ExitProcess



print_time_str: ;rcx optional hour offset
    mov rcx, [CURRENT_TIME]
    call GetSystemTime
    mov rcx, [CURRENT_TIME]
    
    mov  ax, word [rcx+8]
    push rax

    mov   rcx, [CURRENT_TIMEZONE]
    call  GetTimeZoneInformation
    mov   rcx, [CURRENT_TIMEZONE]
    movsx rdx, dword [rcx]
    ;push_all
    ;printi rdx,1,2
    ;pop_all

    pop rax
    ;add rax, rdx

    printi rax
    push qword ':'
    prints rsp, 0, 1
    
    mov rcx, [CURRENT_TIME]
    mov ax, word [rcx+10]
    printi rax
    prints rsp
    
    mov rcx, [CURRENT_TIME]
    mov ax, word [rcx+12]
    printi rax
    push qword '.'
    prints rsp
    add rsp,16

    xor rax, rax
    
    mov rcx, [CURRENT_TIME]
    mov ax, word [rcx+14]
    printi rax
ret

min_to_hmin:

ret

get_unix_time: ;rax OUT
    push rcx
    push rdx
    push r8
    push r9
    mov rcx, [CURRENT_TIME]
    call GetSystemTime

    mov rcx, [CURRENT_TIME]
    xor rax,  rax
    xor rdx,  rdx
    mov ax, word [rcx]
    sub ax, 1970
    mov r8,   31_536_000_000 ;ms in year
    mul r8
    mov r9,   rax

    xor rax,  rax
    xor rdx,  rdx
    mov ax, word [rcx+2]
    mov r8,   2_628_000_000 ;ms in month
    mul r8
    add r9,   rax

    xor rax,  rax
    xor rdx,  rdx
    mov ax, word [rcx+6]
    mov r8,   86_400_000 ;ms in day
    mul r8
    add r9,   rax

    xor rax,  rax
    xor rdx,  rdx
    mov ax, word [rcx+8]
    mov r8,   3_600_000 ;ms in hour
    mul r8
    add r9,   rax

    xor rax,  rax
    xor rdx,  rdx
    mov ax, word [rcx+10]
    mov r8,   60000 ;ms in minute
    mul r8
    add r9,   rax

    xor rax,  rax
    xor rdx,  rdx
    mov ax, word [rcx+12]
    mov r8,   1000 ;ms in sec
    mul r8
    add r9,   rax
    
    xor rax,  rax
    mov ax, word [rcx+14]
    add r9,   rax
    
    ;mov r8, qword 0x19DB1DED53E8000 ;unix time start
    ;sub r9, r8
    sub r9, 1_684_800_000 ;1970 years, 19 days & 12 hours
    mov rax, r9
    pop r9
    pop r8
    pop rdx
    pop rcx
ret

copy_strf: ;src ptr rcx IN, dest ptr rdx IN, optional len r8 IN
    push_all

    cmp r8, 0
    je  copy_strf_ret
    cmp r8, -1
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

    cmp rdx, 0
    je  clear_strf_ret
    cmp rdx, -1
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
        pcmpistri xmm0, [dec_table], 0b_00_00_11_00
        cmp       rcx,   16
        je        parse_string_invalid

        push rdx
            xor  rdx, rdx
            mul  r10
            add  rax, rcx
        pop rdx

        inc r8
    dec rdx
    cmp rdx, 0
    jne  parse_string_loop
ret
parse_string_invalid:
    xor rax, rax
ret


endlf: ;number of endls rcx IN
    push_all
    endlf_loop:
    cmp rcx, 0
    je  endlf_ret
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

    cmp rdx, 0
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

        cmp r8,  0
        je  if_bin_end
        cmp r14, 2
        jne if_bin_end
            push rax
            mov  rax, r9
            xor  rdx, rdx
            mov  rcx, 5  ;should be 4 idk why it has to be 5
            div  rcx
            cmp  rdx, 0
            pop  rax
            jne if_bin_end
                dec  rsp
                mov  byte [rsp], '_'
                inc  r9
        if_bin_end:

        xor rdx,  rdx
        div qword r14

        mov  r10,   hex_table
        add  rdx,   r10
        mov  r11b, [rdx]
        dec  rsp
        mov [rsp],  r11b
    cmp rax, 0
    jne print_int_loop

    cmp r8,  0
    je  if_hex_end
    cmp r14, 16
    jne if_hex_end
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