org 0x7e00          ; Start address
[bits 32]           ; Use 32-bit registers and instructions

start:
    call clear_screen
.loop:
    mov dword [cursor], 0
    rdtsc           ; Read Time Stamp Counter
    mov eax, edx
    call prepare_eax
    call print
    rdtsc           ; Read Time Stamp Counter
    call prepare_eax
    call print
    mov esi, message
    call print
    jmp .loop
    jmp $           ; Hang
    
%define VIDEO_MEMORY 0xb8000 ; Video memory address
%define ROWS 25
%define COLS 80

cursor:
    dd 0

clear_screen:
    mov edi, VIDEO_MEMORY
    mov ax, 0
.loop:
    stosw           ; mov [edi], ax; inc edi
    cmp edi, VIDEO_MEMORY + ROWS * COLS * 2
    jne .loop
    
    mov dword [cursor], 0
    ret

print:
    mov edi, [cursor]
    add edi, VIDEO_MEMORY
    
.loop:
    lodsb           ; mov al, [esi]; inc esi
    
    cmp al, 0
    je .done
    cmp al, 0xA
    je .nl
    cmp al, 0xD
    je .ret
    
    mov ah, 0x07    ; Color
    stosw           ; mov [edi], ax; inc edi
    jmp .loop

; \n
.nl:
    add edi, COLS * 2
    jmp .loop

; \r
.ret:
    mov eax, edi
    sub eax, VIDEO_MEMORY
    mov edx, 0
    mov ecx, COLS * 2
    div ecx
    sub edi, edx
    
    jmp .loop
    
.done:
    sub edi, VIDEO_MEMORY
    mov [cursor], edi
    ret

println:
    call print
    mov esi, line
    call print
    ret
    
message:
    db ' tacts of processor since reset', 0

line:
    db 0xA, 0xD, 0

number_buffer:
    times 9 db 0
number_buffer_end:

prepare_eax:
    mov esi, (number_buffer_end - 1)
    mov cl, 0
.loop:
    mov edx, eax
    shr edx, cl
    and dl, 0xf
    call .prepare_symbol
    dec esi
    mov [esi], dl
    add cl, 4
    cmp cl, 32
    jne .loop
    ret

.prepare_symbol:
    cmp dl, 10
    jnl .af
    add dl, '0'
    ret
.af:
    add dl, ('A' - 10)
    ret
    
    times 512 * 4 - ($ - $$) db 0
