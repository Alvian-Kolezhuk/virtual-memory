org 0x7c00          ; Start address
[bits 16]           ; Use 16-bit registers and instructions

start:              ; First stage
    xor ax, ax
    mov ds, ax      ; Data segment
    mov es, ax      ; Extra segment
    mov ax, 0x8
    mov ss, ax      ; Stack segment
    mov sp, 0       ; Initialize stack

    xor ax, ax      ; Reset Disk Drives
    int 13h         ; Low Level Disk Services
    mov si, disk_reset_error_message
    jc panic
    
; Load next sectors
    mov ah, 0x02    ; Read Sectors
    mov al, 4       ; Number of sectors to read
    mov ch, 0       ; Cylinder number
    mov cl, 2       ; Sector number
    mov dh, 0       ; Head number
    mov bx, 0x7E00  ; Buffer address in memory (where to load)
    int 0x13        ; Low Level Disk Services
    
    mov si, disk_read_error_message
    jc panic
    
; Enter to unreal mode
    lgdt [gdt_descriptor] ; Load GDT (Global Descriptor Table)
    
    cli             ; Disable interrupts
    mov eax, cr0
    or eax, 1
    mov cr0, eax    ; Enable protected mode
    
    jmp word (gdt_code - gdt_start):unreal_start ; Far jump to flush prefetch queue
    
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
    
; GDT (Global Descriptor Table)
align 8
gdt_start:
    ; Null descriptor
    dd 0x00000000, 0x00000000
gdt_code:
    ; Code segment descriptor
    dw 0xFFFF       ; Limit 0:15
    dw 0x0000       ; Base 0:15
    db 0x00         ; Base 16:23
    db 0x9A         ; Access byte: 7 - present, 4 - not system, 3 - executable, 1 - readable
    db 0xCF         ; Flag (page granularity and 32-bit mode) and limit 16:19
    db 0x00         ; Base 24:31
gdt_data:
    ; Data segment descriptor
    dw 0xFFFF       ; Limit 0:15
    dw 0x0000       ; Base 0:15
    db 0x00         ; Base 16:23
    db 0x92         ; Access byte: 7 - present, 4 - not system, 3 - not executable, 1 - writable
    db 0xCF         ; Flag (page granularity and 32-bit mode) and limit 16:19
    db 0x00         ; Base 24:31
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Limit of GDT
    dd gdt_start    ; Base address of GDT
    
[bits 32]           ; Use 32-bit registers and instructions
unreal_start:
    mov ax, (gdt_data - gdt_start)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    mov eax, cr0
    and eax, 0xFFFFFFFE
    mov cr0, eax    ; Return to real mode

    mov esp, 0x800000; Initialize stack
    jmp done
    
    times 510-($-$$) db 0 ; Number of bytes must be 512 in first stage
    dw 0xAA55       ; Last 2 bytes must be such

done:
