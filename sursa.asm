DATA SEGMENT
    ; ==============================================================================
    ; ZONA DE DATE (Variabile și Constante)
    ; ==============================================================================
    
    ; --- Mesaje de interfață (terminate cu '$' pentru funcția DOS 09h) ---
    msg_intro        db 13,10,'>>> PROIECT ASM: Operatii pe Siruri de Octeti <<<',13,10,'$'
    msg_req_input    db 13,10,'Introduceti 8-16 octeti in format HEX (ex: 6C 7B ..): $'

    ; --- Mesaje de eroare ---
    msg_error_len    db 13,10,'EROARE: Numar incorect de octeti! (Min 8, Max 16).',13,10,'$'
    msg_error_hex    db 13,10,'EROARE: Input HEX invalid! Folositi doar 0-9, A-F si EXACT 2 cifre / octet.',13,10,'$'

    ; --- Etichete pentru afișarea rezultatelor ---
    msg_word_c       db 13,10,'1. Cuvantul C calculat (Hex): $'
    msg_word_c_bin   db 13,10,'   Cuvantul C calculat (Bin): $'
    msg_sorted       db 13,10,'2. Sirul sortat (Descrescator): $'
    msg_max_bits     db 13,10,'3. Pozitia octetului cu cei mai multi biti de 1 (>3): $'
    msg_no_max       db 13,10,'3. Nu exista niciun octet cu mai mult de 3 biti de 1.',13,10,'$'
    msg_rotated      db 13,10,'4. Sirul dupa rotiri (Hex si Bin):',13,10,'$'

    msg_wait         db 13,10,13,10,'>>> APASATI ORICE TASTA PENTRU A CONTINUA... $'
    
    ; --- Elemente de formatare vizuală ---
    newline          db 13,10,'$'   ; Codurile ASCII 13 (Carriage Return) și 10 (Line Feed)
    space            db ' $'        ; Spațiu simplu
    arrow            db ' -> $'     ; Săgeată separatoare

    ; --- Structura Buffer pentru citire (INT 21h, AH=0Ah) ---
    ; Această structură este cerută strict de DOS:
    ; Octet 1: Dimensiunea maximă a bufferului (setăm 60)
    ; Octet 2: DOS va scrie aici câți octeți a citit efectiv (fără Enter)
    ; Octet 3+: Aici se stochează caracterele introduse de utilizator
    buffer_struct    db 60          
    buffer_len       db ?           
    buffer_data      db 60 dup(?)   

    ; --- Variabile pentru stocarea datelor procesate ---
    byte_array       db 20 dup(0)   ; Vectorul unde ținem numerele convertite (ex: 0xA5, nu "A5")
    array_count      db 0           ; Numărul real de elemente valide din vector
    word_c           dw 0           ; Variabilă pe 16 biți (Word) pentru rezultatul C

    ; --- Variabile auxiliare ---
    temp_byte        db 0           ; Folosită pentru stocări intermediare în calcule complexe
    max_bits_val     db 0           ; Ține minte maximul curent de biți de 1
    max_bits_idx     db 0           ; Ține minte indexul unde am găsit maximul

    hex_error_flag   db 0           ; Flag boolean: 0 = Totul OK, 1 = Am găsit caracter invalid

    ; --- Zona de Stivă ---
    stack_area       db 256 dup(0)  ; Alocăm 256 octeți pentru stivă
    stack_top        label byte     ; Etichetă care marchează vârful stivei (adresa de start a SP)
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:DATA

START:
    ; ==============================================================================
    ; INITIALIZARE PROGRAM
    ; ==============================================================================
    mov ax, DATA
    mov ds, ax          ; Inițializăm DS (Data Segment) pentru a putea accesa variabilele
    mov ss, ax          ; Inițializăm SS (Stack Segment)
    mov sp, offset stack_top ; Setăm SP (Stack Pointer) la vârful zonei rezervate

    lea dx, msg_intro
    call PRINT_STRING   ; Afișăm titlul

READ_LOOP:
    ; ==============================================================================
    ; BUCLA DE CITIRE ȘI VALIDARE
    ; ==============================================================================
    lea dx, msg_req_input
    call PRINT_STRING   ; Solicităm input

    ; Citire șir de la tastatură folosind funcția DOS 0Ah
    ; Aceasta așteaptă până când utilizatorul apasă ENTER
    lea dx, buffer_struct
    mov ah, 0Ah
    int 21h

    ; Apelăm procedura de conversie din șir de caractere în numere
    call PARSE_INPUT_STRICT

    ; Verificăm dacă conversia a reușit
    cmp hex_error_flag, 0
    je  HEX_OK              ; Dacă flag-ul e 0, trecem mai departe
    jmp INPUT_ERROR_HEX     ; Altfel, afișăm eroare și reluăm
HEX_OK:

    ; Validare număr minim de octeți (Minim 8)
    cmp array_count, 8
    jae LEN_MIN_OK          ; Jump if Above or Equal
    jmp INPUT_ERROR_LEN
LEN_MIN_OK:

    ; Validare număr maxim de octeți (Maxim 16)
    cmp array_count, 16
    jbe LEN_OK              ; Jump if Below or Equal
    jmp INPUT_ERROR_LEN
LEN_OK:

    lea dx, newline
    call PRINT_STRING

    ; ==============================================================================
    ; 1. CALCULUL CUVÂNTULUI C
    ; ==============================================================================
    call CALCULATE_C

    ; Afișăm rezultatul C (Hexazecimal)
    lea dx, msg_word_c
    call PRINT_STRING
    
    ; Afișăm octetul High din C
    mov ax, word_c
    mov bh, ah          
    call PRINT_HEX_BYTE
    
    ; Afișăm octetul Low din C
    mov ax, word_c
    mov bh, al          
    call PRINT_HEX_BYTE

    ; Afișăm rezultatul C (Binar)
    lea dx, msg_word_c_bin
    call PRINT_STRING
    mov ax, word_c
    mov bh, ah
    call PRINT_BIN_BYTE
    mov ax, word_c
    mov bh, al
    call PRINT_BIN_BYTE

    call WAIT_FOR_USER

    ; ==============================================================================
    ; 2. SORTARE DESCRESCĂTOARE
    ; ==============================================================================
    call SORT_DESCENDING

    lea dx, msg_sorted
    call PRINT_STRING
    call PRINT_ARRAY    ; Afișăm întreg vectorul sortat

    call WAIT_FOR_USER

    ; ==============================================================================
    ; 3. GĂSIRE MAXIM BIȚI DE 1
    ; ==============================================================================
    call FIND_MAX_BITS_POS

    cmp max_bits_val, 3 ; Verificăm condiția din enunț (> 3 biți)
    jle NO_MAX_FOUND    ; Dacă <= 3, afișăm mesajul de lipsă

    ; Dacă am găsit, afișăm poziția
    lea dx, msg_max_bits
    call PRINT_STRING
    mov al, max_bits_idx
    add al, 1           ; Convertim din index 0-based în poziție 1-based pentru utilizator
    mov bh, al
    call PRINT_HEX_BYTE
    jmp AFTER_MAX

NO_MAX_FOUND:
    lea dx, msg_no_max
    call PRINT_STRING

AFTER_MAX:
    call WAIT_FOR_USER

    ; ==============================================================================
    ; 4. ROTIRI LA STÂNGA
    ; ==============================================================================
    lea dx, msg_rotated
    call PRINT_STRING
    call APPLY_ROTATIONS ; Execută logica de rotire pe fiecare octet

    call WAIT_FOR_USER

    ; Ieșire curată în DOS
    mov ax, 4C00h       ; AH=4Ch (Exit), AL=00h (Cod de retur 0 - Succes)
    int 21h

; --- Handlere de Erori ---
INPUT_ERROR_LEN:
    lea dx, msg_error_len
    call PRINT_STRING
    call WAIT_FOR_USER
    jmp READ_LOOP       ; Salt necondiționat înapoi la citire

INPUT_ERROR_HEX:
    lea dx, msg_error_hex
    call PRINT_STRING
    call WAIT_FOR_USER
    jmp READ_LOOP       ; Salt necondiționat înapoi la citire

; ==============================================================================
; PROCEDURI AUXILIARE
; ==============================================================================

PRINT_STRING PROC NEAR
    mov ah, 09h         ; Întrerupere DOS: Scrie string terminat în '$' la stdout
    int 21h
    ret
PRINT_STRING ENDP

WAIT_FOR_USER PROC NEAR
    push ax             ; Salvăm registrele pentru a nu afecta programul principal
    push dx

    lea dx, msg_wait
    mov ah, 09h
    int 21h

    ; Așteaptă o tastă (AH=0Ch curăță bufferul, apoi apelează funcția din AL=07h)
    ; Funcția 07h: Direct Console Input without Echo
    mov ah, 0Ch
    mov al, 07h
    int 21h

    lea dx, newline
    mov ah, 09h
    int 21h

    pop dx              ; Restaurăm registrele
    pop ax
    ret
WAIT_FOR_USER ENDP

; ------------------------------------------------------------------------------
; PARSE_INPUT_STRICT
; Transformă șirul ASCII ("A5 0B ...") în vector de octeți (0xA5, 0x0B)
; ------------------------------------------------------------------------------
PARSE_INPUT_STRICT PROC NEAR
    xor di, di              ; DI = Index în vectorul destinație (byte_array)
    mov array_count, 0      ; Resetăm contorul de elemente
    mov hex_error_flag, 0   ; Resetăm flag-ul de eroare

    mov cl, buffer_len      ; CL = Câți octeți a citit DOS de la tastatură
    lea si, buffer_data     ; SI = Pointer la caracterele citite

PARSE_NEXT:
    cmp cl, 0
    jle PARSE_DONE_OK       ; Dacă lungimea e 0, am terminat

    mov al, [si]            ; Încărcăm caracterul curent
    cmp al, 13              ; Verificăm dacă e Carriage Return (Enter)
    je  PARSE_DONE_OK

    cmp al, ' '             ; Ignorăm spațiile
    je  SKIP_CHAR
    cmp al, 9               ; Ignorăm tab-urile
    je  SKIP_CHAR

    ; --- Cifra 1 (High Nibble) ---
    call HEX_CHAR_TO_BIN_STRICT ; Conversie 'A' -> 10
    cmp hex_error_flag, 0
    jne PARSE_DONE_ERR      ; Ieșim dacă e caracter invalid
    mov bl, al              ; Salvăm valoarea (ex: 10) în BL

    inc si                  ; Trecem la următorul caracter din buffer
    dec cl                  ; Scădem contorul de caractere rămase
    
    ; Verificăm dacă șirul s-a terminat brusc (ex: am citit "A" și atât)
    cmp cl, 0
    jle SET_ERR_INCOMPLETE  

    ; Verificăm să nu urmeze spațiu (ex: "A B") -> Invalid, trebuie "AB"
    mov al, [si]
    cmp al, 13
    je  SET_ERR_INCOMPLETE
    cmp al, ' '
    je  SET_ERR_INCOMPLETE
    cmp al, 9
    je  SET_ERR_INCOMPLETE

    ; --- Cifra 2 (Low Nibble) ---
    call HEX_CHAR_TO_BIN_STRICT ; Conversie '5' -> 5
    cmp hex_error_flag, 0
    jne PARSE_DONE_ERR

    ; --- Combinare Nibbles ---
    ; Avem BL = 00001010 (10) și AL = 00000101 (5)
    shl bl, 4               ; BL devine 10100000 (160 sau A0h)
    or  bl, al              ; BL devine 10100101 (A5h)

    mov byte_array[di], bl  ; Scriem octetul complet în vector
    inc di                  ; Incrementăm indexul vectorului
    inc array_count         ; Incrementăm numărul de elemente găsite

    inc si
    dec cl
    jmp PARSE_NEXT          ; Reluăm bucla

SKIP_CHAR:
    inc si
    dec cl
    jmp PARSE_NEXT

SET_ERR_INCOMPLETE:
    mov hex_error_flag, 1   ; Setăm eroare (număr impar de cifre sau format greșit)
    jmp PARSE_DONE_ERR

PARSE_DONE_OK:
    ret
PARSE_DONE_ERR:
    ret
PARSE_INPUT_STRICT ENDP

; ------------------------------------------------------------------------------
; HEX_CHAR_TO_BIN_STRICT
; Intrare: AL (caracter ASCII) -> Ieșire: AL (valoare numerică 0-15)
; Setează hex_error_flag = 1 dacă caracterul nu e valid.
; ------------------------------------------------------------------------------
HEX_CHAR_TO_BIN_STRICT PROC NEAR
    cmp al, '0'
    jb  NOT_HEX         ; Sub '0' -> Eroare
    cmp al, '9'
    jbe DIGIT           ; Între '0'-'9' -> E cifră

    cmp al, 'A'
    jb  CHECK_LOWER     ; Între '9' și 'A' -> Verificăm litere mici
    cmp al, 'F'
    jbe UPPER           ; Între 'A'-'F' -> E literă mare

CHECK_LOWER:
    cmp al, 'a'
    jb  NOT_HEX
    cmp al, 'f'
    jbe LOWER           ; Între 'a'-'f' -> E literă mică
    jmp NOT_HEX

DIGIT:
    sub al, '0'         ; ASCII '0'(30h) -> 0
    ret
UPPER:
    sub al, 'A'         ; ASCII 'A'(41h) -> 0
    add al, 10          ; 0 + 10 = 10 (Valoarea hex A)
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

; ------------------------------------------------------------------------------
; CALCULATE_C
; Calculează cuvântul C (16 biți) conform formulei specifice
; ------------------------------------------------------------------------------
CALCULATE_C PROC NEAR
    ; --- Partea 1: Octetul High (Suma aritmetică) ---
    xor ax, ax          ; AX = 0 (Acumulator sumă)
    xor cx, cx
    mov cl, array_count ; Numărul de elemente pentru buclă
    lea si, byte_array  ; Pointer la începutul vectorului
SUM_LOOP:
    xor bx, bx
    mov bl, [si]        ; Luăm octetul curent
    add ax, bx          ; Adunăm la sumă
    inc si
    loop SUM_LOOP       ; Decrementează CX și sare dacă != 0
    mov byte ptr [word_c + 1], al ; Salvăm octetul Low din sumă în High-ul lui C

    ; --- Partea 2: Octetul Low ---
    
    ; Pasul A: (Nibble High Primul Octet) XOR (Nibble Low Ultimul Octet)
    lea si, byte_array
    mov bl, [si]        ; Luăm primul octet
    shr bl, 4           ; Păstrăm doar primii 4 biți (High Nibble)

    xor di, di
    mov al, array_count
    cbw                 ; Convert Byte to Word (AX = array_count)
    mov di, ax
    dec di              ; DI = Indexul ultimului element (count - 1)
    mov bh, byte_array[di]
    and bh, 0Fh         ; Mască cu 00001111 pentru a păstra doar Low Nibble

    xor bl, bh          ; Operația XOR
    and bl, 0Fh         ; Siguranță: rezultatul trebuie să fie max 4 biți
    mov temp_byte, bl   ; Salvăm rezultatul intermediar (biții 0-3 ai rezultatului final)

    ; Pasul B: OR intre biții 2-5 ai tuturor octeților
    xor dx, dx          ; DX va fi acumulatorul pentru OR
    mov cl, array_count
    lea si, byte_array
OR_LOOP:
    mov al, [si]
    and al, 00111100b   ; Mască: Păstrăm doar biții 2,3,4,5
    shr al, 2           ; Îi mutăm pe pozițiile 0,1,2,3
    or  dl, al          ; Facem OR cu ce am acumulat până acum
    inc si
    loop OR_LOOP

    and dl, 0Fh         ; Avem rezultatul pe 4 biți
    shl dl, 4           ; Îl mutăm pe pozițiile 4-7 (High Nibble al octetului rezultat)

    mov al, temp_byte   ; Recuperăm rezultatul pasului A (biții 0-3)
    or  al, dl          ; Combinăm cu rezultatul pasului B (biții 4-7)
    mov byte ptr [word_c], al ; Salvăm în octetul Low al lui C
    ret
CALCULATE_C ENDP

; ------------------------------------------------------------------------------
; SORT_DESCENDING
; Algoritmul Bubble Sort clasic
; ------------------------------------------------------------------------------
SORT_DESCENDING PROC NEAR
    mov cl, array_count
    dec cl              ; Loop exterior merge de N-1 ori
OUTER:
    push cx             ; Salvăm contorul exterior (CX este folosit și de LOOP)
    lea si, byte_array
    mov ch, array_count
    dec ch              ; Loop interior
INNER:
    mov al, [si]        ; Elementul curent
    mov ah, [si+1]      ; Elementul următor
    cmp al, ah          ; Comparație
    jae NO_SWAP         ; Jump if Above or Equal (Nu schimbăm dacă e deja descrescător)
    
    ; Swap (Interschimbare)
    mov [si], ah
    mov [si+1], al
NO_SWAP:
    inc si              ; Avansăm pointerul
    dec ch              ; Scădem contorul interior
    cmp ch, 0
    jg INNER            ; Repetăm bucla interioară
    
    pop cx              ; Restaurăm contorul exterior
    loop OUTER          ; Decrementează CX și repetă bucla exterioară
    ret
SORT_DESCENDING ENDP

; ------------------------------------------------------------------------------
; FIND_MAX_BITS_POS
; Caută indexul octetului care are cei mai mulți biți de 1
; ------------------------------------------------------------------------------
FIND_MAX_BITS_POS PROC NEAR
    lea si, byte_array
    mov cl, array_count
    xor di, di          ; DI = Index curent (0, 1, 2...)
    mov max_bits_val, 0 ; Reset maxim
    mov max_bits_idx, 0 ; Reset poziție

SCAN_LOOP:
    mov al, [si]        ; Luăm valoarea
    push cx             ; Salvăm contorul principal
    mov cx, 8           ; Vom roti de 8 ori (pentru 8 biți)
    xor bl, bl          ; BL = Contor biți de 1 pentru numărul curent
    mov dl, al          ; Copie a numărului
COUNT_BITS:
    shl dl, 1           ; Shift Left: Bitul cel mai semnificativ intră în CF (Carry Flag)
    adc bl, 0           ; Add with Carry: BL = BL + 0 + CF (dacă bitul a fost 1, BL crește)
    loop COUNT_BITS
    pop cx              ; Restaurăm contorul principal

    ; Verificăm dacă e nou maxim
    cmp bl, max_bits_val
    jle NEXT_VAL        ; Dacă e mai mic sau egal, ignorăm
    
    ; Am găsit un nou maxim
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

; ------------------------------------------------------------------------------
; APPLY_ROTATIONS
; Aplică rotiri la stânga (ROL) în funcție de primii 2 biți
; ------------------------------------------------------------------------------
APPLY_ROTATIONS PROC NEAR
    lea si, byte_array
    mov ch, 0
    mov cl, array_count

ROT_LOOP:
    push cx
    mov al, [si]

    ; Calculăm numărul de rotiri N = Bit0 + Bit1
    ; Exemplu: Dacă numărul e ...011 (3), Bit0=1, Bit1=1 -> Rotim de 2 ori
    xor bh, bh          ; BH va fi contorul de rotații
    test al, 1          ; Testăm bitul 0 (AND logic fără a schimba AL)
    jz  CHECK_B1        ; Dacă e 0, sărim
    inc bh              ; Dacă e 1, incrementăm
CHECK_B1:
    test al, 2          ; Testăm bitul 1
    jz  DO_ROT
    inc bh              ; Dacă e 1, incrementăm
    ; BH poate fi acum 0, 1 sau 2

DO_ROT:
    call ROTATE_BYTE_LEFT ; Execută 'rol al, cl'
    mov [si], al          ; Actualizează valoarea în memorie

    ; Afișare vizuală: Hex -> Bin
    push ax
    mov bh, al
    call PRINT_HEX_BYTE   ; Printează ex: A5
    lea dx, arrow
    call PRINT_STRING     ; Printează " -> "
    pop ax

    mov bh, al
    call PRINT_BIN_BYTE   ; Printează ex: 10100101
    lea dx, newline
    call PRINT_STRING

    inc si
    pop cx
    dec cl
    jnz ROT_LOOP
    ret
APPLY_ROTATIONS ENDP

ROTATE_BYTE_LEFT PROC NEAR
    mov cl, bh          ; Punem numărul de rotiri în CL (registrul de count pentru shift/rol)
    cmp cl, 0
    je ROT_DONE         ; Dacă e 0, nu facem nimic
    rol al, cl          ; Rotate Left: biți ies prin stânga și intră prin dreapta
ROT_DONE:
    ret
ROTATE_BYTE_LEFT ENDP

; ------------------------------------------------------------------------------
; PRINT_ARRAY
; Iterează prin vector și afișează fiecare element HEX
; ------------------------------------------------------------------------------
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

; ------------------------------------------------------------------------------
; PRINT_HEX_BYTE
; Afișează valoarea din BH ca două caractere hexazecimale
; ------------------------------------------------------------------------------
PRINT_HEX_BYTE PROC NEAR
    push ax
    push bx
    push cx
    push dx

    mov dl, bh
    shr dl, 4           ; Aduce nibble-ul de sus jos (ex: A5 -> 0A)
    call PRINT_NIBBLE   ; Afișează prima cifră
    
    mov dl, bh
    and dl, 0Fh         ; Maschează nibble-ul de sus (ex: A5 -> 05)
    call PRINT_NIBBLE   ; Afișează a doua cifră

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_HEX_BYTE ENDP

; Helper: Printează 4 biți (0-15) ca caracter ('0'-'9', 'A'-'F')
PRINT_NIBBLE PROC NEAR
    cmp dl, 9
    jle P_DIGIT         ; Dacă e 0-9, doar adăugăm '0'
    add dl, 7           ; Dacă e A-F, adăugăm 7 pentru a sări peste caracterele ASCII dintre 9 și A
P_DIGIT:
    add dl, '0'         ; Conversie la ASCII
    mov ah, 02h         ; Funcția DOS output char
    int 21h
    ret
PRINT_NIBBLE ENDP

; ------------------------------------------------------------------------------
; PRINT_BIN_BYTE
; Afișează cei 8 biți ai valorii din BH (ex: "10010011")
; ------------------------------------------------------------------------------
PRINT_BIN_BYTE PROC NEAR
    push cx
    push dx
    mov cx, 8           ; 8 biți de afișat
P_BIN_LOOP:
    shl bh, 1           ; Shift Left -> Bitul MSB intră în Carry Flag
    jc P_ONE            ; Jump if Carry (bitul a fost 1)
    mov dl, '0'
    jmp P_OUT
P_ONE:
    mov dl, '1'
P_OUT:
    mov ah, 02h
    int 21h
    loop P_BIN_LOOP
    
    mov dl, ' '         ; Spațiu separator
    mov ah, 02h
    int 21h
    pop dx
    pop cx
    ret
PRINT_BIN_BYTE ENDP

CODE ENDS
END START
