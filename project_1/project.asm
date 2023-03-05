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
    lea DX, InputFileName
    int 21h
    xor BH, BH
    mov BL, InputFileName[1]
    mov InputFileName[BX+2], 0

    _new_line_
    _print_message_ 'Input filename for write > '
    lea DX, OutputFileName
    int 21h
    mov BL, OutputFileName[1]
    mov OutputFileName[BX+2], 0

    jmp open_input_file

;-----------------------  Read PSP Parameters -------------------------

read_psp_parameters:    
    _read_psp_parameters_ InputFileName, OutputFileName

;-------------------------  Open read file ---------------------------

open_input_file:
    mov AX, 3D00h
    mov DX, offset InputFileName[2]
    int 21h
    jnc openOK
    _new_line_
    _print_message_ '*** ERROR open input file ***'
    jmp _end

openOK:
    _new_line_
    _print_message_ '*** SUCCES open input file ***'

;---------------------------------------------------------------------

_end:
int 20h

;============================ Procedures =============================

;----------------------------- Proc name -----------------------------
;---------------------------------------------------------------------

;=============================== DATA ================================

    CR      EQU 0Dh
    LF      EQU 0Ah
    Space   EQU 20h
    
    InputFileName    DB 14,0,14 dup (0)
    OutputFileName   DB 14,0,14 dup (0)

;=====================================================================

code_seg ends
end start