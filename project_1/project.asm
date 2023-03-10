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
    mov AH, 0Ah

    call new_line
    _print_message_ 'Input filename for read > '
    lea DX, InputFileName
    int 21h

    call new_line
    _print_message_ 'Input filename for write > '
    lea DX, OutputFileName
    int 21h
    
    cld
    xor CX, CX

    mov CL, InputFileName[1]
    mov DI, offset InputFileName[2]

    call skip_space_and_tab
    mov DX, DI
    call add_zero_to_end
    
    mov CL, OutputFileName[1]
    mov DI, offset OutputFileName[2]
    
    call skip_space_and_tab
    mov BX, DI
    call add_zero_to_end

    jmp open_input_file

;-----------------------  Read PSP Parameters -------------------------

read_psp_parameters:    
    
    cld
    xor CX, CX
    mov CL, ES:80h
    mov AL, ' '
    mov DI, 81h
    
    repe scasb
    dec DI
    inc CL
    mov DX, DI

    repne scasb
    dec DI
    inc CL
    mov byte ptr [DI], 0

    inc DI
    repe scasb
    dec DI
    inc CL
    mov BX, DI

    repne scasb
    dec DI
    mov byte ptr [DI], 0

;-------------------------- Open input file ---------------------------

open_input_file:
    mov AX, 3D00h
    int 21h
    jnc openInputOK
    call new_line
    _print_message_ '*** ERROR open input file ***'
    jmp _end

openInputOK:
    mov InputDescriptor, AX
    call new_line
    _print_message_ '*** SUCCESS open input file ***'

;------------------------- Read input file ---------------------------

_read_file_ InputDescriptor, InputBuffer, InputBufferSize, ByteInBuffer
_close_file_ InputDescriptor    

;------------------------- Open output file --------------------------

open_output_file:
    mov AX, 3D01h
    push DX
    mov DX, BX
    int 21h
    pop DX
    jnc openOutputOK
    jmp openInputLikeOutput

openOutputOK:
    mov OutputDescriptor, AX
    call new_line
    _print_message_ '*** SUCCESS open output file ***'
    jmp work_with_buffer

openInputLikeOutput:
    mov AH, 3Ch
    int 21h
    mov AX, 3D01h
    int 21h
    mov OutputDescriptor, AX
    call new_line
    _print_message_ '*** SUCCESS open output file (input)***'
    
work_with_buffer:

;------------------------ Work with buffer ---------------------------

mov CX, ByteInBuffer
mov SI, offset InputBuffer
mov DI, offset OutputBuffer
cycle:
    mov AL, [SI]
    cmp AL, SPACE
    je is_space
    cmp AL, LF ; ДЛЯ РАБОТЫ НА ВИНДЕ ЗАМЕНИТЬ НА CR
    je is_CR

    mov AL, [SI]
    mov [DI], AL
    jmp next

    is_space:
        mov [DI], TAB
        jmp next
    
    is_CR:
        mov [DI], AL
        inc DI
        mov [DI], LF
        inc ByteInBuffer
    
    next:
        inc SI
        inc DI
        loop cycle

;------------------------ Print new buffer ---------------------------

mov CX, ByteInBuffer
mov SI, offset OutputBuffer
call new_line
call new_line
print_buffer:
    mov AL, [SI]
    _print_letter_ AL
    inc SI
    loop print_buffer

;------------------------ Write output file --------------------------

_write_file_ OutputDescriptor, OutputBuffer, ByteInBuffer
_close_file_ OutputDescriptor

;---------------------------------------------------------------------

_end:
int 20h

;=========================== Procedures ==============================

;----------------------------- New line ------------------------------

new_line proc
    _print_letter_ LF
    _print_letter_ CR
    ret
new_line endp

;----------------------- Skip SPACE and TAB --------------------------

skip_space_and_tab proc
    push AX
    continue_1:
            mov AL, SPACE
            repe scasb
            dec DI
            mov AL, TAB
            repe scasb
            dec DI
            mov AL, byte ptr [DI]
            cmp AL, SPACE
            je continue_1
    
    pop AX
    ret
skip_space_and_tab endp

;----------------------- Add ZERO to ASCII --------------------------

add_zero_to_end proc
    push AX
    mov SI, DI
    continue_2:
        mov AL, byte ptr [SI]
        cmp AL, SPACE
        je add_zero
        cmp AL, TAB
        je add_zero
        cmp AL, CR
        je add_zero
        inc SI
        jmp continue_2
    add_zero:
        mov byte ptr [SI], 0
    pop AX
    ret
add_zero_to_end endp

;---------------------------------------------------------------------

;=============================== DATA ================================

    CR                  EQU 0Dh
    LF                  EQU 0Ah
    SPACE               EQU 20h
    TAB                 EQU 09h
    
    InputBufferSize     EQU 10000
    OutputBufferSize    EQU 20000
    
    InputFileName       DB  30,0,30 dup (0)
    OutputFileName      DB  30,0,30 dup (0)

    InputDescriptor     DW  ?
    OutputDescriptor    DW  ?
    InputBuffer         DB  InputBufferSize dup (?)
    OutputBuffer        DB  OutputBufferSize dup (?)
    ByteInBuffer        DW  ?

;=====================================================================

code_seg ends
end start