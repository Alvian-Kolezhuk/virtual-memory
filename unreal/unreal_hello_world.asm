org 0x7e00          ; Start address
[bits 32]           ; Use 32-bit registers and instructions

start:
    mov esi, message
    mov edi, 0x200000
    mov ecx, (end_message - message)
    rep movsb       ; Move message to large address

.print:
    call clear_screen
    mov esi, 0x200000
    call println
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
    db 'Hello world from 0x200000!', 0
end_message:

line:
    db 0xA, 0xD, 0
    
    times 512 * 4 - ($ - $$) db 0
