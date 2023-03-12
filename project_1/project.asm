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

    _print_message_ 'Input filename for read > '
    lea DX, InputFileName
    int 21h

    call new_line
    _print_message_ 'Input filename for write > '
    lea DX, OutputFileName
    int 21h
    call new_line
    
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

;-------------------------- Open input file --------------------------

open_input_file:
    mov AX, 3D00h
    int 21h
    jnc openInputOK
    _print_error_ '*** Error opening the input file ***'
    jmp _end

openInputOK:
    mov InputDescriptor, AX    

;------------------------- Open output file --------------------------

open_output_file:
    mov AX, 3D01h
    push DX
    mov DX, BX
    int 21h
    pop DX
    jnc openOutput
    
openInputLikeOutput:
    mov AX, 3D01h
    int 21h

openOutput:
    mov OutputDescriptor, AX
    
;------------------------------ Main ------------------------------

main:
    read_file:
        _read_file_ InputDescriptor, InputBuffer, InputBufferSize, InpBuffRealBytes
        cmp InpBuffRealBytes, InputBufferSize
        je work_with_file
        jmp end_read

    work_with_file:
        _buffer_proc_ InpBuffRealBytes, OutBuffRealBytes, InputBuffer, OutputBuffer
        _print_buffer_ OutBuffRealBytes, OutputBuffer
        _write_file_ OutputDescriptor, OutputBuffer, OutBuffRealBytes
        jmp read_file
    
    end_read:
        cmp InpBuffRealBytes, 0
        jne last_read
        jmp close_files

        last_read:
            _buffer_proc_ InpBuffRealBytes, OutBuffRealBytes, InputBuffer, OutputBuffer
            _print_buffer_ OutBuffRealBytes, OutputBuffer
            _write_file_ OutputDescriptor, OutputBuffer, OutBuffRealBytes

    close_files:
        _close_file_ InputDescriptor
        _close_file_ OutputDescriptor

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

skip_space_and_tab proc near
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

add_zero_to_end proc near
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

;---------------------------- Print DL -------------------------------

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
        jl print
        add DL, 07h
        print:
            int 21H
            ret
print_hex endp

;---------------------------------------------------------------------

;=============================== DATA ================================

    CR                  EQU 0Dh
    LF                  EQU 0Ah
    SPACE               EQU 20h
    TAB                 EQU 09h
    
    InputBufferSize     EQU 1
    OutputBufferSize    EQU 2
    
    InputFileName       DB  30,0,30 dup (0)
    OutputFileName      DB  30,0,30 dup (0)

    InputDescriptor     DW  ?
    OutputDescriptor    DW  ?
    InputBuffer         DB  InputBufferSize dup (?)
    OutputBuffer        DB  OutputBufferSize dup (?)
    InpBuffRealBytes    DW  ?
    OutBuffRealBytes    DW  ?

;=====================================================================

code_seg ends
end start