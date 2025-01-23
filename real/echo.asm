org 0x7c00          ; Start address
[bits 16]           ; Use 16-bit registers and instructions

_start:
    xor ax, ax
    mov ds, ax      ; Data segment
    mov es, ax      ; Extra segment
    mov ss, ax      ; Stack segment
    mov sp, 0x8000  ; Initialize stack
    
.loop:
    mov ah, 0x00    ; Read character
    int 0x16        ; Keyboard services
    mov ah, 0x0E    ; Write Character in TTY Mode
    int 0x10        ; BIOS video services
    jmp .loop
    
    times 510-($-$$) db 0 ; Number of bytes must be 512
    dw 0xAA55       ; Last 2 bytes must be such
