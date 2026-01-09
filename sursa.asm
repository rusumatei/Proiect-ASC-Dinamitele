DATA SEGMENT
    msg_intro        db 13,10,'>>> PROIECT ASM: Operatii pe Siruri de Octeti <<<',13,10,'$'
    msg_req_input    db 13,10,'Introduceti 8-16 octeti in format HEX (ex: 6C 7B ..): $'

    msg_error_len    db 13,10,'EROARE: Numar incorect de octeti! (Min 8, Max 16).',13,10,'$'
    msg_error_hex    db 13,10,'EROARE: Input HEX invalid! Folositi doar 0-9, A-F si EXACT 2 cifre / octet.',13,10,'$'

    msg_word_c       db 13,10,'1. Cuvantul C calculat (Hex): $'
    msg_word_c_bin   db 13,10,'   Cuvantul C calculat (Bin): $'
    msg_sorted       db 13,10,'2. Sirul sortat (Descrescator): $'
    msg_max_bits     db 13,10,'3. Pozitia octetului cu cei mai multi biti de 1 (>3): $'
    msg_no_max       db 13,10,'3. Nu exista niciun octet cu mai mult de 3 biti de 1.',13,10,'$'
    msg_rotated      db 13,10,'4. Sirul dupa rotiri (Hex si Bin):',13,10,'$'

    msg_wait         db 13,10,13,10,'>>> APASATI ORICE TASTA PENTRU A CONTINUA... $'
    newline          db 13,10,'$'
    space            db ' $'
    arrow            db ' -> $'

    buffer_struct    db 60
    buffer_len       db ?
    buffer_data      db 60 dup(?)

    byte_array       db 20 dup(0)
    array_count      db 0
    word_c           dw 0

    temp_byte        db 0
    max_bits_val     db 0
    max_bits_idx     db 0

    hex_error_flag   db 0

    stack_area       db 256 dup(0)
    stack_top        label byte
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:DATA

START:
    mov ax, DATA
    mov ds, ax
    mov ss, ax
    mov sp, offset stack_top

    lea dx, msg_intro
    call PRINT_STRING

READ_LOOP:
    lea dx, msg_req_input
    call PRINT_STRING

    lea dx, buffer_struct
    mov ah, 0Ah
    int 21h

    call PARSE_INPUT_STRICT

    cmp hex_error_flag, 0
    je  HEX_OK
    jmp INPUT_ERROR_HEX
HEX_OK:

    cmp array_count, 8
    jae LEN_MIN_OK
    jmp INPUT_ERROR_LEN
LEN_MIN_OK:

    cmp array_count, 16
    jbe LEN_OK
    jmp INPUT_ERROR_LEN
LEN_OK:

    lea dx, newline
    call PRINT_STRING

    call CALCULATE_C

    lea dx, msg_word_c
    call PRINT_STRING
    mov ax, word_c
    mov bh, ah
    call PRINT_HEX_BYTE
    mov ax, word_c
    mov bh, al
    call PRINT_HEX_BYTE

    lea dx, msg_word_c_bin
    call PRINT_STRING
    mov ax, word_c
    mov bh, ah
    call PRINT_BIN_BYTE
    mov ax, word_c
    mov bh, al
    call PRINT_BIN_BYTE

    call WAIT_FOR_USER

    call SORT_DESCENDING

    lea dx, msg_sorted
    call PRINT_STRING
    call PRINT_ARRAY

    call WAIT_FOR_USER

    call FIND_MAX_BITS_POS

    cmp max_bits_val, 3
    jle NO_MAX_FOUND

    lea dx, msg_max_bits
    call PRINT_STRING
    mov al, max_bits_idx
    add al, 1
    mov bh, al
    call PRINT_HEX_BYTE
    jmp AFTER_MAX

NO_MAX_FOUND:
    lea dx, msg_no_max
    call PRINT_STRING

AFTER_MAX:
    call WAIT_FOR_USER

    lea dx, msg_rotated
    call PRINT_STRING
    call APPLY_ROTATIONS

    call WAIT_FOR_USER

    mov ax, 4C00h
    int 21h

INPUT_ERROR_LEN:
    lea dx, msg_error_len
    call PRINT_STRING
    call WAIT_FOR_USER
    jmp READ_LOOP

INPUT_ERROR_HEX:
    lea dx, msg_error_hex
    call PRINT_STRING
    call WAIT_FOR_USER
    jmp READ_LOOP

PRINT_STRING PROC NEAR
    mov ah, 09h
    int 21h
    ret
PRINT_STRING ENDP

WAIT_FOR_USER PROC NEAR
    push ax
    push dx

    lea dx, msg_wait
    mov ah, 09h
    int 21h

    mov ah, 0Ch
    mov al, 07h
    int 21h

    lea dx, newline
    mov ah, 09h
    int 21h

    pop dx
    pop ax
    ret
WAIT_FOR_USER ENDP

PARSE_INPUT_STRICT PROC NEAR
    xor di, di
    mov array_count, 0
    mov hex_error_flag, 0

    mov cl, buffer_len
    lea si, buffer_data

PARSE_NEXT:
    cmp cl, 0
    jle PARSE_DONE_OK

    mov al, [si]
    cmp al, 13
    je  PARSE_DONE_OK

    cmp al, ' '
    je  SKIP_CHAR
    cmp al, 9
    je  SKIP_CHAR

    call HEX_CHAR_TO_BIN_STRICT
    cmp hex_error_flag, 0
    jne PARSE_DONE_ERR
    mov bl, al

    inc si
    dec cl
    cmp cl, 0
    jle SET_ERR_INCOMPLETE

    mov al, [si]
    cmp al, 13
    je  SET_ERR_INCOMPLETE
    cmp al, ' '
    je  SET_ERR_INCOMPLETE
    cmp al, 9
    je  SET_ERR_INCOMPLETE

    call HEX_CHAR_TO_BIN_STRICT
    cmp hex_error_flag, 0
    jne PARSE_DONE_ERR

    shl bl, 4
    or  bl, al

    mov byte_array[di], bl
    inc di
    inc array_count

    inc si
    dec cl
    jmp PARSE_NEXT

SKIP_CHAR:
    inc si
    dec cl
    jmp PARSE_NEXT

SET_ERR_INCOMPLETE:
    mov hex_error_flag, 1
    jmp PARSE_DONE_ERR

PARSE_DONE_OK:
    ret
PARSE_DONE_ERR:
    ret
PARSE_INPUT_STRICT ENDP

HEX_CHAR_TO_BIN_STRICT PROC NEAR
    cmp al, '0'
    jb  NOT_HEX
    cmp al, '9'
    jbe DIGIT

    cmp al, 'A'
    jb  CHECK_LOWER
    cmp al, 'F'
    jbe UPPER

CHECK_LOWER:
    cmp al, 'a'
    jb  NOT_HEX
    cmp al, 'f'
    jbe LOWER
    jmp NOT_HEX

DIGIT:
    sub al, '0'
    ret
UPPER:
    sub al, 'A'
    add al, 10
    ret
LOWER:
    sub al, 'a'
    add al, 10
    ret
NOT_HEX:
    mov hex_error_flag, 1
    mov al, 0
    ret
HEX_CHAR_TO_BIN_STRICT ENDP

CALCULATE_C PROC NEAR
    xor ax, ax
    xor cx, cx
    mov cl, array_count
    lea si, byte_array
SUM_LOOP:
    xor bx, bx
    mov bl, [si]
    add ax, bx
    inc si
    loop SUM_LOOP
    mov byte ptr [word_c + 1], al

    lea si, byte_array
    mov bl, [si]
    shr bl, 4

    xor di, di
    mov al, array_count
    cbw
    mov di, ax
    dec di
    mov bh, byte_array[di]
    and bh, 0Fh

    xor bl, bh
    and bl, 0Fh
    mov temp_byte, bl

    xor dx, dx
    mov cl, array_count
    lea si, byte_array
OR_LOOP:
    mov al, [si]
    and al, 00111100b
    shr al, 2
    or  dl, al
    inc si
    loop OR_LOOP

    and dl, 0Fh
    shl dl, 4

    mov al, temp_byte
    or  al, dl
    mov byte ptr [word_c], al
    ret
CALCULATE_C ENDP

SORT_DESCENDING PROC NEAR
    mov cl, array_count
    dec cl
OUTER:
    push cx
    lea si, byte_array
    mov ch, array_count
    dec ch
INNER:
    mov al, [si]
    mov ah, [si+1]
    cmp al, ah
    jae NO_SWAP
    mov [si], ah
    mov [si+1], al
NO_SWAP:
    inc si
    dec ch
    cmp ch, 0
    jg INNER
    pop cx
    loop OUTER
    ret
SORT_DESCENDING ENDP

FIND_MAX_BITS_POS PROC NEAR
    lea si, byte_array
    mov cl, array_count
    xor di, di
    mov max_bits_val, 0
    mov max_bits_idx, 0

SCAN_LOOP:
    mov al, [si]
    push cx
    mov cx, 8
    xor bl, bl
    mov dl, al
COUNT_BITS:
    shl dl, 1
    adc bl, 0
    loop COUNT_BITS
    pop cx

    cmp bl, max_bits_val
    jle NEXT_VAL
    mov max_bits_val, bl
    mov ax, di
    mov max_bits_idx, al

NEXT_VAL:
    inc si
    inc di
    dec cl
    jnz SCAN_LOOP
    ret
FIND_MAX_BITS_POS ENDP

APPLY_ROTATIONS PROC NEAR
    lea si, byte_array
    mov ch, 0
    mov cl, array_count

ROT_LOOP:
    push cx
    mov al, [si]

    xor bh, bh
    test al, 1
    jz  CHECK_B1
    inc bh
CHECK_B1:
    test al, 2
    jz  DO_ROT
    inc bh

DO_ROT:
    call ROTATE_BYTE_LEFT
    mov [si], al

    push ax
    mov bh, al
    call PRINT_HEX_BYTE
    lea dx, arrow
    call PRINT_STRING
    pop ax

    mov bh, al
    call PRINT_BIN_BYTE
    lea dx, newline
    call PRINT_STRING

    inc si
    pop cx
    dec cl
    jnz ROT_LOOP
    ret
APPLY_ROTATIONS ENDP

ROTATE_BYTE_LEFT PROC NEAR
    mov cl, bh
    cmp cl, 0
    je ROT_DONE
    rol al, cl
ROT_DONE:
    ret
ROTATE_BYTE_LEFT ENDP

PRINT_ARRAY PROC NEAR
    lea si, byte_array
    mov cl, array_count
    xor ch, ch
PR_LOOP:
    mov bh, [si]
    call PRINT_HEX_BYTE
    lea dx, space
    call PRINT_STRING
    inc si
    loop PR_LOOP
    ret
PRINT_ARRAY ENDP

PRINT_HEX_BYTE PROC NEAR
    push ax
    push bx
    push cx
    push dx

    mov dl, bh
    shr dl, 4
    call PRINT_NIBBLE
    mov dl, bh
    and dl, 0Fh
    call PRINT_NIBBLE

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_HEX_BYTE ENDP

PRINT_NIBBLE PROC NEAR
    cmp dl, 9
    jle P_DIGIT
    add dl, 7
P_DIGIT:
    add dl, '0'
    mov ah, 02h
    int 21h
    ret
PRINT_NIBBLE ENDP

PRINT_BIN_BYTE PROC NEAR
    push cx
    push dx
    mov cx, 8
P_BIN_LOOP:
    shl bh, 1
    jc P_ONE
    mov dl, '0'
    jmp P_OUT
P_ONE:
    mov dl, '1'
P_OUT:
    mov ah, 02h
    int 21h
    loop P_BIN_LOOP
    mov dl, ' '
    mov ah, 02h
    int 21h
    pop dx
    pop cx
    ret
PRINT_BIN_BYTE ENDP

CODE ENDS
END START