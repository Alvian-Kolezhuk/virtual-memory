org 0x7e00          ; Start address
[bits 32]           ; Use 32-bit registers and instructions

%ifdef MODE
  %define RUN_IN_QEMU (MODE & 1)
  %define TEST_DISABLED_CACHE (MODE & 2)
  %define PRINT_COUNTERS (MODE & 4)
%else
  ; Setup: 0 or 1
  %define RUN_IN_QEMU 0
  %define TEST_DISABLED_CACHE 0
  %define PRINT_COUNTERS 0
%endif

%if (RUN_IN_QEMU || TEST_DISABLED_CACHE)
  %define MULTIPLIER 0x1
%else
  %define MULTIPLIER 0x10
%endif
    
%define ARRAY_SIZE (0x1000000 * MULTIPLIER) ; array of 4'194'304 in qemu or with disables cache or 67'108'864 in raw metal elements
%define FIRST_ARRAY_START (0x2000000 * MULTIPLIER)
%define FIRST_ARRAY_END (FIRST_ARRAY_START + ARRAY_SIZE)
%define SECOND_ARRAY_START FIRST_ARRAY_END
%define SECOND_ARRAY_END (SECOND_ARRAY_START + ARRAY_SIZE)

start:
    call initialize_page_table
    call clear_screen
.loop:
    mov dword [cursor], 0
    
%if TEST_DISABLED_CACHE
    mov esi, enabled_cache_message
    call println
%endif
    call test
    
%if TEST_DISABLED_CACHE
    mov esi, disabled_cache_message
    call println
; Disable cache
    mov eax, cr0
    or eax, 0x40000000
    mov cr0, eax
    wbinvd          ; Write back and invalidate cache
; Test
    call test
; Enable cache
    mov eax, cr0
    and eax, 0xbfffffff
    mov cr0, eax
    wbinvd          ; Write back and invalidate cache
%endif
    jmp .loop
    jmp $           ; Hang

panic:
    mov esi, panic_message
    call println
    jmp $           ; Hang
    
test:
; Enable unreal mode
    mov eax, cr0
    and eax, 0x7ffffffe
    mov cr0, eax
    
; Test unreal mode
    call test_merge_sort
    mov esi, unreal_message
    call println

%if PRINT_COUNTERS
    call print_counters
%endif
    
    call test_random_access
    mov esi, unreal_message
    call println

%if PRINT_COUNTERS
    call print_counters
%endif
    
; Enable protected mode with page addressing
    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax
    
; Test protected mode with page addressing
    call test_merge_sort
    mov esi, protected_message
    call println
    
%if PRINT_COUNTERS
    call print_counters
%endif
    
    call test_random_access
    mov esi, protected_message
    call println

%if PRINT_COUNTERS
    call print_counters
%endif
    
    ret
    
%define PAGE_SIZE_LOG 12
%define PAGE_SIZE (1 << PAGE_SIZE_LOG)
%define PT_ENTRY_SIZE_LOG 2
%define PT_ENTRY_SIZE (1 << PT_ENTRY_SIZE_LOG)
%define PAGE_DIRECTORY_ADDRESS 0xfff000
%define FIRST_PAGE_TABLE_ADDRESS 0x1000000
%define MAX_ADDRESS SECOND_ARRAY_END
%define NUMBER_OF_PAGES ((MAX_ADDRESS + PAGE_SIZE - 1) >> PAGE_SIZE_LOG)
%define NUMBER_OF_PAGE_TABLES ((NUMBER_OF_PAGES + PAGE_SIZE / PT_ENTRY_SIZE - 1) >> (PAGE_SIZE_LOG - PT_ENTRY_SIZE_LOG))

initialize_page_table:
; Initialize Page Directory
    mov edi, PAGE_DIRECTORY_ADDRESS
    mov ecx, (PAGE_SIZE / 4)
    xor eax, eax
    rep stosd       ; repeat(ecx) mov [edi], eax; add edi, 4
    
    mov edi, PAGE_DIRECTORY_ADDRESS
    mov eax, FIRST_PAGE_TABLE_ADDRESS
    or eax, 3       ; 1 bit -- enable write, 0 bit -- present
.initialize_page_directory_loop:
    stosd           ; mov [edi], eax; add edi, 4
    add eax, PAGE_SIZE
    cmp edi, (PAGE_DIRECTORY_ADDRESS + NUMBER_OF_PAGE_TABLES * PT_ENTRY_SIZE)
    jl .initialize_page_directory_loop
    
; Initialize Page Tables
    mov edi, FIRST_PAGE_TABLE_ADDRESS
    mov ecx, (NUMBER_OF_PAGES + PAGE_SIZE - 1) / PAGE_SIZE * PAGE_SIZE / 4 * PT_ENTRY_SIZE ; Ceiled number of pages
    xor eax, eax
    rep stosd       ; repeat(ecx) mov [edi], eax; add edi, 4
    
    mov edi, FIRST_PAGE_TABLE_ADDRESS
    mov eax, 3      ; 1 bit -- enable write, 0 bit -- present
.initialize_page_tables_loop:
    stosd           ; mov [edi], eax; add edi, 4
    add eax, PAGE_SIZE
    cmp edi, (FIRST_PAGE_TABLE_ADDRESS + NUMBER_OF_PAGES * PT_ENTRY_SIZE)
    jl .initialize_page_tables_loop
    
; Write to CR3 PAGE_DIRECTORY_ADDRESS
    mov eax, PAGE_DIRECTORY_ADDRESS
    mov cr3, eax
    
    ret
    
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
    
panic_message:
    db 'Algorithm is not correct', 0
    
unreal_message:
    db ' tacts in unreal mode', 0
    
protected_message:
    db ' tacts in protected mode with page addressing', 0
    
merge_sort_message:
    db 'Merge sort:    ', 0
    
random_access_message:
    db 'Random access: ', 0
    
%if TEST_DISABLED_CACHE
enabled_cache_message:
    db 'Enabled cache:', 0
    
disabled_cache_message:
    db 'Disabled cache:', 0
%endif

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

save_time:
    rdtsc           ; Read Time Stamp Counter
    mov [edi], edx
    add edi, 4
    mov [edi], eax
    ret

print_time:
    mov eax, [start_time + 4]
    mov edx, [end_time + 4]
    sub edx, eax
    mov [time + 4], edx
    mov eax, [start_time]
    mov edx, [end_time]
    sbb edx, eax
    mov [time], edx
    mov eax, edx
    call prepare_eax
    call print
    mov eax, [time + 4]
    call prepare_eax
    call print
    ret

start_time:
    dd 0, 0

end_time:
    dd 0, 0

time:
    dd 0, 0
    
; Random from glibc
rand_r:
    mov edx, 1103515245
    mul edx
    add eax, 12345
    and eax, 0x7fffffff
    ret

check_sum:
    dd 0

fill_array:
    mov eax, 42     ; Random seed
    xor ecx, ecx    ; Check sum
    mov edi, FIRST_ARRAY_START
.loop:
    call rand_r
    mov [edi], eax
    add ecx, eax
    add edi, 4
    cmp edi, FIRST_ARRAY_END
    jne .loop
    mov [check_sum], ecx
    ret
    
merge_sort:
    mov ecx, 3      ; Granularity - 1 (4 bytes - 1)

.granularity_loop:  ; for granularity = 3; granularity < (ARRAY_SIZE >> 1); granularity <<= 1
    mov esi, FIRST_ARRAY_START
    mov edi, SECOND_ARRAY_START
    call subarrays_procedure
    and ecx, ((ARRAY_SIZE >> 1) - 1)
    
    mov esi, SECOND_ARRAY_START
    mov edi, FIRST_ARRAY_START
    call subarrays_procedure
    cmp ecx, (ARRAY_SIZE >> 1)
    jl .granularity_loop
    
    ret

subarrays_procedure:
    mov ebx, esi
    add ebx, ecx
    inc ebx
    mov eax, [esi]
    mov edx, [ebx]
.loop:
    cmp eax, edx
    jnb .second
.first:
    mov [edi], eax
    add edi, 4
    add esi, 4
    test esi, ecx
    jz .first_out
    mov eax, [esi]
    jmp .loop
.first_out:
    test edx, 0x80000000
    jnz .end
    mov eax, 0x80000000 ; Greater than all
    jmp .loop
.second:
    mov [edi], edx
    add edi, 4
    add ebx, 4
    test ebx, ecx
    jz .second_out
    mov edx, [ebx]
    jmp .loop
.second_out:
    test eax, 0x80000000
    jnz .end
    mov edx, 0x80000000 ; Greater than all
    jmp .loop
.end:
    mov esi, ebx
    test esi, (ARRAY_SIZE - 1)
    jnz subarrays_procedure
    shl ecx, 1
    inc ecx
    ret

test_correctness:
    mov esi, FIRST_ARRAY_START
    mov edx, 0
    xor ecx, ecx
.loop:
    mov eax, edx
    mov edx, [esi]
    add esi, 4
    add ecx, edx
    cmp eax, edx
    jg .fail
    cmp esi, FIRST_ARRAY_END
    jnz .loop
    
    mov eax, [check_sum]
    cmp eax, ecx
    ;jne .fail
.ok:
    xor eax, eax
    ret
.fail:
    mov eax, 1
    ret

test_merge_sort:
    mov esi, merge_sort_message
    call print

    call fill_array
    
    call start_test
    
    call merge_sort
    
    call end_test
    
    call test_correctness
    test eax, eax
    jnz panic
    
    call print_time
    
    ret
    
test_random_access:
    mov esi, random_access_message
    call print
    
    call start_test
    
    mov ecx, (0x1000000 * MULTIPLIER)
    mov eax, 42
    
.loop:
    call rand_r
    mov edi, eax
    and edi, ((ARRAY_SIZE - 1) & 0xfffffffc)
    add edi, FIRST_ARRAY_START
    call rand_r
    mov [edi], eax
    dec ecx
    jnz .loop
    
    call end_test
    
    call print_time
    ret
    
start_test:
    wbinvd          ; Write back and invalidate cache
    mov eax, cr3
    mov cr3, eax    ; Flush TLB cache

%if PRINT_COUNTERS
    call setup_counters
%endif
    
    mov edi, start_time
    call save_time
    
    ret

end_test:
    mov edi, end_time
    call save_time
    
%if PRINT_COUNTERS
    mov edi, counters
    call save_counters
%endif
    
    ret
    
%if PRINT_COUNTERS

setup_counters:
    mov ecx, 0xc0010000 ; First Performance Event Select Register
    mov eax, 0x00430745 ; L1 DTLB Miss and L2 DTLB Hit
    mov edx, 0x00000000 ; L1 DTLB Miss and L2 DTLB Hit
    wrmsr
    
    mov ecx, 0xc0010001 ; Second Performance Event Select Register
    mov eax, 0x00430746 ; L1 DTLB and L2 DTLB Miss
    mov edx, 0x00000000 ; L1 DTLB and L2 DTLB Miss
    wrmsr
    
    mov ecx, 0xc0010002 ; Third Performance Event Select Register
    mov eax, 0x0043074d ; L1 DTLB Hit
    mov edx, 0x00000000 ; L1 DTLB Hit
    wrmsr
    
    mov ecx, 0xc0010004 ; First Performance Event Counter Register
    mov eax, 0x00000000
    mov edx, 0x00000000
    wrmsr
    
    mov ecx, 0xc0010005 ; Second Performance Event Counter Register
    mov eax, 0x00000000
    mov edx, 0x00000000
    wrmsr
    
    mov ecx, 0xc0010006 ; Third Performance Event Counter Register
    mov eax, 0x00000000
    mov edx, 0x00000000
    wrmsr
    
    ret
    
save_counters:
    mov ecx, 0xc0010004 ; First Performance Event Counter Register
    rdmsr
    mov [edi], edx
    add edi, 4
    mov [edi], eax
    add edi, 4
    
    mov ecx, 0xc0010005 ; Second Performance Event Counter Register
    rdmsr
    mov [edi], edx
    add edi, 4
    mov [edi], eax
    add edi, 4
    
    mov ecx, 0xc0010006 ; Third Performance Event Counter Register
    rdmsr
    mov [edi], edx
    add edi, 4
    mov [edi], eax
    add edi, 4
    
    ret
    
print_counters:
    mov esi, counters_message
    call print
    mov eax, [counters + 16]
    call prepare_eax
    call print
    mov eax, [counters + 20]
    call prepare_eax
    call print
    mov esi, slash
    call print
    mov eax, [counters + 0]
    call prepare_eax
    call print
    mov eax, [counters + 4]
    call prepare_eax
    call print
    mov esi, slash
    call print
    mov eax, [counters + 8]
    call prepare_eax
    call print
    mov eax, [counters + 12]
    call prepare_eax
    call println
    
    ret

slash:
    db '/', 0

counters_message:
    db 'DTLB1/DTLB2/Memory ', 0

counters:
    dd 0, 0
    dd 0, 0
    dd 0, 0
    
%endif
    
    times 512 * 4 - ($ - $$) db 0
