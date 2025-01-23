org 0x7c00          ; Start address
[bits 16]           ; Use 16-bit registers and instructions

_start:
    xor ax, ax
    mov ds, ax      ; Data segment
    mov es, ax      ; Extra segment
    mov ss, ax      ; Stack segment
    mov sp, 0x8000  ; Initialize stack
    
    mov si, _message
    call _print
    jmp $           ; Hang
    
_message:
    db 'Hello world!', 0xA, 0xD, 0
    
_print:
.loop:
    lodsb           ; mov al, [si]; inc si
    cmp al, 0
    je .done
    mov ah, 0x0E    ; Write Character in TTY Mode
    int 0x10        ; BIOS video services
    jmp .loop
.done:
    ret
    
    times 510-($-$$) db 0 ; Number of bytes must be 512
    dw 0xAA55       ; Last 2 bytes must be such
