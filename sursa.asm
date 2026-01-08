DATA SEGMENT
    msg_intro        db 13,10,'>>> PROIECT ASM: Operatii pe Siruri de Octeti <<<',13,10,'$'
    msg_req_input    db 13,10,'Introduceti 8-16 octeti in format HEX (ex: 6C 7B ..): $'
    msg_error_len    db 13,10,'EROARE: Numar incorect de octeti! (Min 8, Max 16).',13,10,'$'
    msg_error_hex    db 13,10,'EROARE: Input HEX invalid! Folositi doar 0-9, A-F si EXACT 2 cifre / octet.',13,10,'$'
    msg_wait         db 13,10,13,10,'>>> APASATI ORICE TASTA PENTRU A CONTINUA... $'
    newline          db 13,10,'$'

    buffer_struct    db 60
    buffer_len       db ?
    buffer_data      db 60 dup(?)

    byte_array       db 20 dup(0)
    array_count      db 0
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
    jmp FINAL_EXIT

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

FINAL_EXIT:
    mov ax, 4C00h
    int 21h

CODE ENDS
END START