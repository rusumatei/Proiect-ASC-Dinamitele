DATA SEGMENT
    msg_sorted       db 13,10,'2. Sirul sortat (Descrescator): $'
    msg_max_bits     db 13,10,'3. Pozitia octetului cu cei mai multi biti de 1 (>3): $'
    msg_no_max       db 13,10,'3. Nu exista niciun octet cu mai mult de 3 biti de 1.',13,10,'$'
    msg_rotated      db 13,10,'4. Sirul dupa rotiri (Hex si Bin):',13,10,'$'
    
    space            db ' $'
    arrow            db ' -> $'
    
    max_bits_val     db 0
    max_bits_idx     db 0
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA

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