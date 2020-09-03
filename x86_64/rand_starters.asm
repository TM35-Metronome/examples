section     .data
buflen  equ 2048

number_of_pokemons db 0,0,0,0,0,0,0,0
starters           db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh

section     .text
global      _start

_start:
    call main

main:
    enter buflen,0

    ; Keep track of a pointer to inside buf. For partial lines
    ; we need to refill the buffer with the rest of the line.

    mov r8,rsp ; Start of partial line
    mov r9,rsp ; End of partial line
rw_loop:
    mov r10,r9 ; Calc length of partial line
    sub r10,r8

    ; Memcpy partial line to the start of the buffer
    mov rsi,r8
    mov rdi,rsp
    mov rcx,r10
    rep movsb

    ; Figure out length of the rest of buffer
    mov r11,r10
    sub r11,buflen
    neg r11

    ; Make r8 point to the unfilled part of the buffer
    mov r8,rsp
    add r8,r10

    ; Fill rest of buffer
    mov rax,0
    mov rdi,0
    mov rsi,r8
    mov rdx,r11
    syscall

    cmp rax,0
    je end_of_rw_loop
    jl exit_program

    ; End of buffer to be r8+rax
    mov r9,r8
    add r9,rax

    mov r11,rsp ; Start of line
line_loop:
    mov r10,r9 ; Calc length of the rest of the buffer
    sub r10,r8

    test r10,r10
    jz no_line

    ; Look for newline
    mov rdi,r8
    mov rcx,r10
    mov al,0ah
    repnz scasb

    jz got_line
no_line:
    mov r8,r11

    ; We have a partial line. Go back and get the rest.p
    jmp rw_loop
got_line:

    mov r8,rdi ; Change r8 to the end of the line

    mov rax,r11
    mov rbx,r8
    sub rbx,1
    call parse_tm35_format
    call store_parsed_data_to_global_tables

    mov rdi,1
    mov rsi,r11
    mov rdx,r8
    sub rdx,rsi
     ; branchless logic. rax is 0 when we don't want to write and 1 otherwise
    imul rdx,rax
    call write_all

    mov r11,r8
    jmp line_loop
end_of_rw_loop:

    mov r8,rsp
    mov r9,r8
    add r9,r10
    cmp r8,r9
    je randomize

    mov rax,r8
    mov rbx,r9
    call parse_tm35_format
    call store_parsed_data_to_global_tables

    ; TODO: r9 might point to a byte outside the buffer, so this might
    ;       trigger a buffer overflow.
    mov byte [r9],10 ; \n
    mov rdi,1
    mov rsi,r8
    mov rdx,r9
    add rdx,1
    sub rdx,rsi
     ; branchless logic. rax is 0 when we don't want to write and 1 otherwise
    imul rdx,rax
    call write_all

randomize:

    mov r15,0
randomize_loop:
    cmp r15,3
    jge end_of_randomize_loop

    ; r13: The starter we want to randomize
    ; r14: The value at r13
    mov r13,r15
    mov r14,[starters+r15*8]
    inc r15
    test r14,r14
    js randomize_loop

    ; TODO: Actually getrandom can return a partial fill of the buffer.
    ;       A correct solution would be to loop until the buffer is filled.
    mov rax,318
    mov rdi,rsp
    mov rsi,8
    mov rdx,0
    syscall

    cmp rax,8
    mov rax,-1
    jne exit_program

    mov rax,[rsp]
    mov rbx,[number_of_pokemons]
    xor rdx,rdx
    div rbx
    mov [starters+r13*8],rdx

    jmp randomize_loop
end_of_randomize_loop:

    ; Copy '.starters[' into our buffer
    mov rsi,starters_prefix+1
    mov rdi,rsp
    mov cl,[starters_prefix]
    movzx ecx,cl
    rep movsb
    mov r8,rdi

    mov r15,0
print_loop:
    cmp r15,3
    jge exit_program

    ; r13 will be the index to print
    ; r14 will be the value to print
    mov r13,r15
    mov r14,[starters+r15*8]
    inc r15
    test r14,r14
    js print_loop

    ; print index
    mov rax,r13
    mov rdi,r8
    mov rcx,10
    call format_number

    mov byte [rdi  ],93 ; ]
    mov byte [rdi+1],61 ; =
    add rdi,2

    ; print value
    mov rax,r14
    mov rcx,10
    call format_number

    mov byte [rdi],10 ; \n
    inc rdi

    ; write(stdout, buf, buflen)
    mov rsi,rsp
    mov rdx,rdi
    sub rdx,rsi
    mov rdi,1
    call write_all

    jmp print_loop

exit_program:
    ; exit(rax)
    mov rdi,rax
    mov rax,60
    syscall


; Performs the write syscall as many times as it take to write
; out the buffer completly to the file descriptor.
; takes:
;   * rdi: File discriptor
;   * rsi: Pointer to buffer
;   * rdx: Number of bytes to write
; returns:
;   * rax: 0 on success. Otherwise, an error occured
write_all:
    ; Keep track of the end of the buffer
    mov rbx,rdx
    add rbx,rsi

write_all_loop:
    mov rax,0
    cmp rdx,rsi
    je write_all_exit

    mov rax,1
    mov rdx,rbx
    sub rdx,rsi
    syscall

    cmp rax,0
    jl write_all_exit
    je write_all_error_exit

    add rsi,rax
    jmp write_all_loop

write_all_error_exit:
    mov rax,-1
write_all_exit:
    ret

; takes:
;   * The registers returned from parser_tm35_format
;   * rax: Type of match
;     * 0: No match
;     * 1: Staters
;     * 2: Pokemons
;   * rbx: Index
;   * rcx: Value
; returns:
;   * rax: 0 if the data is gonna be randomized, otherwise 1
store_parsed_data_to_global_tables:
    cmp rax,1
    jl store_parsed_data_to_global_tables_exit
    je store_starter_to_global_table

    inc rbx
    cmp rbx,[number_of_pokemons]
    jle store_parsed_data_to_global_tables_exit
    mov [number_of_pokemons],rbx
    jmp store_parsed_data_to_global_tables_exit
store_starter_to_global_table:
    mov rax,0
    cmp rbx,3
    jge store_parsed_data_to_global_tables_exit

    mov rax,0
    mov [starters+rbx*8],rcx
    ret
store_parsed_data_to_global_tables_exit:
    mov rax,1
    ret

; takes:
;   * rax: Buffer to parse
;   * rbx: End of buffer to parse
; returns:
;   * rax: Type of match
;     * 0: No match
;     * 1: Staters
;     * 2: Pokemons
;   * rbx: Index
;   * rcx: Value
parse_tm35_format:
    mov rdi,rax
    mov rdx,rbx
    sub rdx,rdi
    mov rsi,starters_prefix
    call starts_with_length_prefix
    mov rcx,1 ; rcx will be 1, if starters_prefix match
    jz parse_tm35_format_tail

    mov rdi,rax
    mov rdx,rbx
    sub rdx,rdi
    mov rsi,pokemons_prefix
    call starts_with_length_prefix
    mov rcx,2 ; rcx will be 2, if pokemons_prefix match
    jz parse_tm35_format_tail
    jmp parse_tm35_format_exit_no_match

parse_tm35_format_tail:
    ; We have now parsed '.starters[' or '.pokemons['
    push rcx

    mov rsi,rbx
    call parse_number
    test rax,rax
    js parse_tm35_format_exit_no_match1

    push rax
    mov rax,0
    cmp rcx,2
    je parse_tm35_format_exit_success

    mov rdx,rbx
    sub rdx,rdi
    mov rsi,common_suffix
    call starts_with_length_prefix
    jnz parse_tm35_format_exit_no_match2

    mov rsi,rbx
    call parse_number
    test rax,rax
    js parse_tm35_format_exit_no_match2

    cmp rdi,rbx
    jne parse_tm35_format_exit_no_match2

parse_tm35_format_exit_success:
    mov rcx,rax
    pop rbx
    pop rax
    ret

parse_tm35_format_exit_no_match2:
    pop rax
parse_tm35_format_exit_no_match1:
    pop rax
parse_tm35_format_exit_no_match:
    xor rax,rax
    xor rbx,rbx
    xor rcx,rcx
    ret

; takes:
;   * rdi: Buffer to match
;   * rdx: Length of buffer
;   * rsi: Length prefixed string
; returns:
;   * Z flag set if rdi starts with rsi
starts_with_length_prefix:
    mov cl,[rsi]
    add rsi,1
    movzx ecx,cl
    cmp rdx,rcx
    jl exit_starts_with_length_prefix

    repz cmpsb
exit_starts_with_length_prefix:
    ret

align 64
starters_prefix db 10,".starters["
pokemons_prefix db 10,".pokemons["
common_suffix   db  2,"]="

; takes:
;   * rdi: Pointer to start of buffer
;   * rsi: Pointer to end of buffer
; returns:
;   * rax: The parsed number. Negative number is returned on parse error
;   * rdi: Pointer to after the number
parse_number:
    mov rax,08000000000000000h
    cmp rsi,rdi
    je parse_number_exit
    xor edx,edx
parse_number_loop:
    mov dl,[rdi]
    cmp dl,30h
    jl parse_number_exit
    cmp dl,39h
    jg parse_number_exit

    and dl,0Fh
    btr rax,63 ; Remove signed bit from our result
    imul rax,10
    add rax,rdx

    add rdi,1
    cmp rsi,rdi
    jne parse_number_loop
parse_number_exit:
    ret

; Thanks @bitRAKE for this very compact format number impl. Very cool
; takes:
;   * rax: Number to format
;   * rcx: Base to use. Allowed: 2 to 36
;   * rdi: Start of a buffer of size 65 to 14 based on the base.
; returns:
;   * rdi: End of buffer
format_number:
    push 0

format_number_push_stack_loop:
    xor edx,edx
    div rcx
    push qword [digit_table+rdx]
    test rax,rax
    jnz format_number_push_stack_loop

format_number_pop_stack_loop:
    pop rax
    stosb
    test al,al
    jnz format_number_pop_stack_loop

    sub rdi,1
    ret

align 64
digit_table db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'

