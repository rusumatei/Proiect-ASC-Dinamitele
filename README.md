# Proiect ASM: Operații pe Șiruri de Octeți (x86)

Acest repository conține proiectul final pentru disciplina Arhitectura Sistemelor de Calcul. Aplicația este scrisă în limbaj de asamblare (x86) și realizează o serie de operații complexe asupra unui șir de octeți introdus de utilizator, conform cerințelor specificate în tema de proiect.

## 📋 Descriere Generală

Programul este o aplicație interactivă care rulează în consolă (MS-DOS). Utilizatorul introduce un șir de valori hexazecimale (între 8 și 16 octeți), iar programul procesează aceste date în mai multe etape: validare, calcule logice și aritmetice, sortare și manipulare la nivel de bit (rotiri).

**Tehnologii:**
* **Limbaj:** Assembly x86
* **Asamblor:** TASM (Turbo Assembler)
* **Linker:** TLINK
* **Arhitectură:** 16-bit Real Mode

## 🚀 Funcționalități Implementate

Conform cerințelor din tema de proiect, aplicația include următoarele module funcționale:

### 1. Citire și Validare Date
* **Interactivitate:** Programul solicită utilizatorului introducerea datelor cu mesaje clare.
* **Input:** Citește un șir de caractere folosind întreruperea DOS `INT 21h`, funcția `0Ah`.
* **Conversie:** Transformă șirul ASCII (ex: "A5") în valori numerice (ex: `0xA5`).
* **Validare Strictă:**
    * Verifică lungimea șirului: Minim 8, Maxim 16 octeți.
    * Verifică formatul: Acceptă doar caracterele `0-9`, `A-F`.
    * Afișează mesaje de eroare specifice și permite reintroducerea datelor.

### 2. Calculul Cuvântului C (16 biți)
Programul calculează o variabilă `word_c` compusă din 3 părți distincte:
* **Biții 0-3 (Low Nibble):** Rezultatul `XOR` între primii 4 biți ai primului octet și ultimii 4 biți ai ultimului octet.
* **Biții 4-7 (High Nibble din Low Byte):** Rezultatul `OR` între biții 2-5 ai fiecărui octet din șir.
* **Biții 8-15 (High Byte):** Suma aritmetică a tuturor octeților din șir, modulo 256.

### 3. Manipularea Șirului
* **Sortare:** Șirul de octeți este rearanjat în ordine **descrescătoare** folosind algoritmul Bubble Sort.
* **Statistică:** Programul identifică și afișează poziția octetului care are cei mai mulți biți de '1' în reprezentarea binară (condiție: > 3 biți).

### 4. Rotiri și Shiftări
Pentru fiecare octet din șirul sortat:
1.  Se calculează `N` = suma primilor 2 biți (Bit0 + Bit1).
2.  Octetul este rotit la stânga (Circular Shift Left - `ROL`) cu `N` poziții.
3.  Rezultatul este afișat vizual în format HEX și BINAR (ex: `A5 -> 10100101`).

## 🛠️ Structura Codului și Subrutine

Codul este modularizat pentru claritate și reutilizare, folosind proceduri (`PROC`):

* `PARSE_INPUT_STRICT`: Gestionează logica de conversie ASCII-Hex și validarea erorilor.
* `CALCULATE_C`: Implementează logica matematică pentru cele 3 componente ale cuvântului C.
* `SORT_DESCENDING`: Implementează algoritmul de sortare.
* `FIND_MAX_BITS_POS`: Analizează biții fiecărui octet pentru statistică.
* `APPLY_ROTATIONS`: Calculează numărul de rotiri necesare și aplică transformarea.
* `PRINT_HEX_BYTE` / `PRINT_BIN_BYTE`: Proceduri de afișare refolosibile.

## 💻 Instrucțiuni de Compilare și Rulare

Pentru a rula proiectul, este necesar un mediu DOS (ex: DOSBox) cu `TASM` și `TLINK` instalate.

1.  **Asamblare:**
    ```bash
    tasm /zi sursa.asm
    ```

2.  **Linkare:**
    ```bash
    tlink /v sursa.obj
    ```

3.  **Execuție:**
    ```bash
    td sursa.exe
    ```

## 👥 Echipa

Proiect realizat de:

* **Rusu Matei:** Citirea datelor, conversia ASCII-Hex, gestionarea șirului în memorie.
* **Șuteu Rodica-Maria:** Operații pe biți, calculul cuvântului C, implementarea rotirilor.
* **Suciu Maria-Adriana:** Algoritmul de sortare, afișarea rezultatelor, documentație și diagrama bloc.

---
*Proiect realizat pentru disciplina Arhitectura Sistemelor de Calcul.*
