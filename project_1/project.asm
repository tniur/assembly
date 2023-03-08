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

    mov DX, offset InputFileName[2]
    xor BX, BX
    mov BX, offset OutputFileName[2]

    jmp open_input_file

;-----------------------  Read PSP Parameters -------------------------

read_psp_parameters:    
    
    cld
    xor CX, CX
    mov CL, ES:80h
    mov DI, 81h
    
    mov AL, ' '
    repe scasb
    dec DI
    inc CL
    mov DX, DI

    mov AL, ' '
    repne scasb
    dec DI
    inc CL
    mov byte ptr [DI], 0

    inc DI
    mov AL, ' '
    repe scasb
    dec DI
    inc CL
    mov BX, DI

    mov AL, ' '
    repne scasb
    dec DI
    mov byte ptr [DI], 0

;-------------------------- Open input file ---------------------------

open_input_file:
    mov AX, 3D00h
    ;mov DX, offset InputFileName[2]
    int 21h
    jnc openInputOK
    _new_line_
    _print_message_ '*** ERROR open input file ***'
    jmp _end

openInputOK:
    mov InputDescriptor, AX
    _new_line_
    _print_message_ '*** SUCCESS open input file ***'

;------------------------- Read input file ---------------------------

ReadFile InputDescriptor, InputBuffer, InputBufferSize, ReadByte
CloseFile InputDescriptor    

;------------------------- Open output file --------------------------

open_output_file:
    mov AX, 3D01h
    ;mov DX, offset OutputFileName[2]
    mov DX, BX
    int 21h
    jnc openOutputOK
    _new_line_
    _print_message_ '*** ERROR open output file ***'
    jmp _end

openOutputOK:
    mov OutputDescriptor, AX
    _new_line_
    _print_message_ '*** SUCCESS open output file ***'

;------------------------ Work with buffer ---------------------------

mov CX, ReadByte
mov SI, offset InputBuffer
mov DI, offset OutputBuffer
cycle:
    mov AL, byte ptr [SI]
    cmp AL, Space
    je is_space
    mov AX, [SI]
    cmp AX, VK
    je is_VK

    mov AL, byte ptr [SI] 
    mov byte ptr [DI], AL
    inc SI
    inc DI
    jmp next

    is_space:
        mov AL, TAB
        mov byte ptr [DI], AL
        inc SI
        inc DI
        jmp next
    
    is_VK:
        mov word ptr [DI], AX
        add DI, 2
        mov AX, PS
        mov word ptr [DI], AX
        add DI, 2
        add SI, 2
        add ReadByte, 2
    
    next:
    loop cycle

;------------------------ Print new buffer ---------------------------

mov CX, ReadByte
mov SI, offset OutputBuffer
_new_line_
print_buffer:
    mov AL, [SI]
    _print_letter_ AL
    inc SI
    loop print_buffer

;------------------------ Write output file --------------------------

WriteFile OutputDescriptor, OutputBuffer, ReadByte
CloseFile OutputDescriptor

;---------------------------------------------------------------------

_end:
int 20h

;============================ Procedures =============================

;------------------------ Print register DL --------------------------

print_DL proc near
    push DX
    rcr DL,4
    call print_hex
    pop DX
    call print_hex
    ret
print_DL endp

;---------------------------- Print HEX ------------------------------

print_hex proc near
    and DL, 0Fh
    add DL, 30h
    cmp DL, 3Ah
    jl print_
    add DL, 07h
    print_:
    int 21H
    ret
 print_hex endp

;---------------------------------------------------------------------

;=============================== DATA ================================

    CR                  EQU 0Dh
    LF                  EQU 0Ah
    ;LetterB             EQU 0C2h
    ;LetterK             EQU 0CAh
    ;LetterP             EQU 0CFh
    ;LetterC             EQU 0D1h
    VK                  EQU 4B56h
    PS                  EQU 5350h
    Space               EQU 20h
    TAB                 EQU 09h
    InputBufferSize     EQU 2048
    OutputBufferSize    EQU 4096
    
    InputFileName       DB  14,0,14 dup (0)
    OutputFileName      DB  14,0,14 dup (0)

    InputDescriptor     DW  ?
    OutputDescriptor    DW  ?
    InputBuffer         DB  InputBufferSize dup (?)
    OutputBuffer        DB  OutputBufferSize dup (?)
    ReadByte            DW  ?

;=====================================================================

code_seg ends
end start