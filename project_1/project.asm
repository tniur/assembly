code_seg segment
    ASSUME CS:code_seg,DS:code_seg,ES:code_seg
    org 100h
include macros.lib

;=============================== Start ===============================
start:

;-------------------------- Check Parameters -------------------------

check_parameters:
    mov SI, 80h
    mov AL, byte ptr[SI]
    cmp AL, 0
    je ask_filenames
    jmp read_psp_parameters

;---------------------------- Ask Filenames --------------------------

ask_filenames:
    _new_line_
    _print_message_ 'Input filename for read > '
    mov AH, 0Ah
    lea DX, NameReadFile
    int 21h
    xor BH, BH
    mov BL, NameReadFile[1]
    mov NameReadFile[BX+2], 0

    _new_line_
    _print_message_ 'Input filename for write > '
    lea DX, NameWriteFile
    int 21h
    mov BL, NameWriteFile[1]
    mov NameWriteFile[BX+2], 0

;-----------------------  Read PSP Parameters --------------------------

read_psp_parameters:
    inc SI
    _read_psp_parameters_ NameReadFile, Space
    inc SI
    _read_psp_parameters_ NameWriteFile, CR

;---------------------------------------------------------------------

int 20h

;============================ Procedures =============================

;----------------------------- Proc name -----------------------------
;---------------------------------------------------------------------

;=============================== DATA ================================

    CR      EQU 0Dh
    LF      EQU 0Ah
    Space   EQU 20h
    
    NameReadFile    DB 14,0,14 dup (0)
    NameWriteFile   DB 14,0,14 dup (0)

;=====================================================================

code_seg ends
end start