DATA SEGMENT
    word_c           dw 0
    temp_byte        db 0
    
    msg_word_c       db 13, 10, '1. Cuvantul C calculat (Hex): $'
    msg_word_c_bin   db 13, 10, '   Cuvantul C calculat (Bin): $'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA

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

CODE ENDS