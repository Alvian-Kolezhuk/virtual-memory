org 0x7c00          ; Start address
[bits 16]           ; Use 16-bit registers and instructions

start:              ; First stage
    xor ax, ax
    mov ds, ax      ; Data segment
    mov es, ax      ; Extra segment
    mov ss, ax      ; Stack segment
    mov sp, 0x8000  ; Initialize stack

    xor ax, ax      ; Reset Disk Drives
    int 13h         ; Low Level Disk Services
    mov si, disk_reset_error_message
    jc panic
    
; Load next sectors
    mov ah, 0x02    ; Read Sectors
    mov al, (end - $$ + 511) / 512 - 1 ; Number of sectors to read
    mov ch, 0       ; Cylinder number
    mov cl, 2       ; Sector number
    mov dh, 0       ; Head number
    mov bx, 0x7E00  ; Buffer address in memory (where to load)
    int 0x13        ; Low Level Disk Services
    
    mov si, disk_read_error_message
    jc panic
    
    jmp second_stage
    
print:
.loop:
    lodsb           ; mov al, [si]; inc si
    cmp al, 0
    je .done
    mov ah, 0x0E    ; Write Character in TTY Mode
    int 0x10        ; BIOS video services
    jmp .loop
.done:
    ret

println:
    call print
    mov si, line
    call print
    ret
    
panic:
    call println
    mov si, panic_message
    call println
    mov ah, 0x00    ; Read character
    int 0x16        ; Keyboard services
    int 0x19        ; Reboot

disk_reset_error_message:
    db 'Disk reset error', 0

disk_read_error_message:
    db 'Disk read error', 0

panic_message:
    db 'Press any key to reboot', 0

line:
    db 0xA, 0xD, 0
    
    times 510-($-$$) db 0 ; Number of bytes must be 512 in first stage
    dw 0xAA55       ; Last 2 bytes must be such
    
second_stage:       ; Second stage
    mov si, message
    call println
    jmp $           ; Hang
    
message:
    db 'Hello world!', 0

end:
