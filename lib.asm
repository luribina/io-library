section .text

global exit
global string_length
global print_string
global print_error
global print_newline
global print_char
global print_int
global print_uint
global string_equals
global read_char
global read_word
global parse_uint
global parse_int
global string_copy

 
 
; rdi - exit code
exit:
    mov rax, 60
    syscall 

; rdi - null terminted string, return rax - string length
string_length:
    xor rax, rax
.loop:
    cmp byte[rdi+rax], 0
    je .loop_end
    inc rax
    jmp .loop
.loop_end:    
    ret

; rdi - null terminted string, prints to stderr
print_error:
   mov rsi, 2
   jmp print_to

; rdi - null terminted string, prints to stdout
print_string:
    mov rsi, 1


print_to:
    push rsi
    push rdi
    call string_length
    mov rdx, rax
    pop rsi
    pop rdi
    mov rax, 1
    syscall
    ret


print_newline:
    mov rdi, 0xA

; rdi - symbol code, print to stdout
print_char:
    push rdi
    mov rdi, rsp
    call print_string
    pop rdi
    ret


; rdi - int
print_int:
    test rdi, rdi
    jns print_uint
    push rdi
    mov rdi, '-'
    call print_char
    pop rdi
    neg rdi


; rdi - uint
print_uint:
    mov rsi, 10
    mov rax, rdi
    mov rdi, rsp
    dec rdi
    sub rsp, 24
    mov byte[rdi], 0
.loop:
    xor rdx, rdx
    div rsi
    or dl, 48
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .loop
    call print_string
    add rsp, 24
    ret

; rdi, rsi - null terminated strings, return 1 if string they are equal else 0
string_equals:
    mov al, byte[rdi]
    mov cl, byte[rsi]
    inc rdi
    inc rsi
    cmp al, cl
    je .is_end
    xor rax, rax
    ret
  .is_end:
    test al, al
    jnz string_equals
    mov rax, 1
    ret

; return one symbol from stdin and return it
read_char:
    xor rax, rax
    xor rdi, rdi
    push 0
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rax
    ret 

; rdi - buffer address, rsi buffer size
; read word from stdin, return rax - buffer size on success, rdx - word length 
; else  rax - 0

read_word:
    xor rdx, rdx
    xor r8, r8
    dec rsi
.read_char:
    push rdi
    push rsi
    push rdx
    call read_char
    pop rdx
    pop rsi
    pop rdi
    cmp rax, 0x20
    je .is_word_end
    cmp rax, 0x9
    je .is_word_end
    cmp rax, 0xA
    je .is_word_end
    mov r8, 1
    jmp .write_char
.is_word_end:
    test r8, r8
    jz .read_char
    jmp .word_end
.write_char:
    cmp rdx, rsi
    ja .too_long
    test al, al
    jz .word_end
    mov byte[rdi+rdx], al
    inc rdx
    jmp .read_char
.word_end:
    mov byte[rdi+rdx], 0
    mov rax, rdi
    ret
.too_long:
    xor rax, rax
    ret
 

; parse string to uint
parse_uint:
    xor rax, rax
    xor rsi, rsi
    mov r8, 10
    xor r9, r9
.parse_digit:
    mov sil, byte[rdi+r9]
    test sil, sil
    jz .uint_end
    cmp sil, 48
    jb .uint_end
    cmp sil, 57
    ja .uint_end
    sub sil, 48
    inc r9
    mul r8
    add rax, rsi
    jmp .parse_digit
.uint_end:
    mov rdx, r9
    ret




; parse string to int
parse_int:
    xor rsi, rsi
    mov sil, byte[rdi]
    cmp sil, '-'
    je .parse_signed
    call parse_uint
    ret
.parse_signed:
    inc rdi
    call parse_uint
    test rdx, rdx
    jnz .not_error
    ret 
.not_error:
    inc rdx
    neg rax
    ret

; copy stinr to buffer, rdi - buffer address, rsi - buffer size
string_copy:
    push rdi
    push rsi
    push rdx
    call string_length
    pop rdx
    pop rsi
    pop rdi
    cmp rdx, rax
    jae .copy
    xor rax, rax
    ret
.copy:
    xor rcx, rcx
    sub rcx, rax
    dec rcx
.loop:
    mov rdx, [rdi]
    mov [rsi], rdx
    inc rdi
    inc rsi
    inc rcx
    test rcx, rcx
    jnz .loop
    ret 
