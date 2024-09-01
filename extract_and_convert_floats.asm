; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Lebogang Masenya u23535246
; Group member 03: Name_Surname_student-nr
; ==========================
section .text
    global extractAndConvertFloats


; Prompts the user to enter a string of numbers
; Enter values separated by whitespace and enclosed in pipes => | 32.133 45.66 -21.255 |
; convert to float
; store in dynamic array
; return float*


section .data
    prompt db "Enter values separated by whitespace and enclosed in pipes (|):", 0
     length equ $ - prompt
    format db "%f", 0
    pipe db "|", 0
     sys_read equ 0               ; Syscall number for reading input
    sys_write equ 1


section .bss
    input_buffer resb 128       ; Buffer for user input
    float_array resd 1          ; Reserve space for one float (will be dynamically expanded)
    num_floats resd 1 

section .text
    global extractAndConvertFloats
    extern printf, malloc, realloc, convertStringToFloat

extractAndConvertFloats:
    mov dword [num_floats], 0

    ; Step 2: Prompt the user
    mov rax, sys_write           ; syscall number for sys_write (1)
    mov rdi, 1                   ; file descriptor 1 (stdout)
    mov rsi, prompt              ; pointer to the prompt message
    mov rdx, length              ; length of the message
    syscall                      ; make the syscall to write

    ; Step 2: Read user input
    mov rax, sys_read            ; syscall number for sys_read (0)
    mov rdi, 0                   ; file descriptor 0 (stdin)
    mov rsi, input_buffer        ; pointer to input buffer
    mov rdx, 128                 ; maximum number of bytes to read
    syscall                      ; make the syscall to read input

    ; Step 3: Find the first pipe
    lea rsi, [input_buffer]      ; RSI points to the input buffer
    call find_first_pipe         ; Find the first pipe and move RSI to the next character

    ; Step 4: Extract and convert numbers between pipes
parse_loop:
    ; Step 4.1: Skip whitespace
    call skip_whitespace

    ; Step 4.2: Check if we have reached the end pipe
    cmp byte [rsi], '|'
    je end_parsing

    ; Step 4.3: Convert the string to float
    push rsi                     ; Save the current pointer to the string
    call convertStringToFloat
    pop rsi                      ; Restore the pointer


   ; Allocate or reallocate the float array
    mov rax, [num_floats]        ; Get the current float count
    inc rax                      ; Increase by 1 for the new float
    mov [num_floats], eax        ; Update num_floats

    ; Reallocate float_array to accommodate the new float
    mov rdi, [float_array]       ; Load current pointer
    imul rsi, rax, 4             ; Calculate the new size (num_floats * 4)
    mov rdi, rax                 ; rdi = num_floats * sizeof(float)
    call realloc
    mov [float_array], rax       ; Update float_array with new address

    ; Step 4.4: Store the float in the array
    mov rdi, float_array         ; Load the float array pointer
    mov rax, [num_floats]        ; Get the current float count
    dec rax
    movss [rdi + rax * 4], xmm0  ; Store the float returned by convertStringToFloat

    ; Step 4.5: Update the count of floats
    inc dword [num_floats]

    ; Step 4.6: Move to the next number
    call skip_to_next_number
    jmp parse_loop

end_parsing:
    ; Step 5: Return the pointer to the float array
    mov rax, [float_array]
    ret

find_first_pipe:
    ; Helper function to find the first pipe ('|')
    find_pipe_loop:
        cmp byte [rsi], '|'
        je found_pipe
        inc rsi
        jmp find_pipe_loop
    found_pipe:
        inc rsi                  ; Move to the character after the pipe
        call parse_loop


skip_whitespace:
    ; Helper function to skip over whitespace
    skip_ws_loop:
        cmp byte [rsi], ' '
        je skip_ws_next
        cmp byte [rsi], 0xA       ; Newline?
        je skip_ws_next
        cmp byte [rsi], 0x9       ; Tab?
        je skip_ws_next
        ret
    skip_ws_next:
        inc rsi
        jmp skip_ws_loop

skip_to_next_number:
    ; Helper function to move to the next number
    skip_num_loop:
        cmp byte [rsi], ' '
        je inc_rsi_and_return
        cmp byte [rsi], '|'
        je inc_rsi_and_return
        inc rsi
        jmp skip_num_loop
    inc_rsi_and_return:
        ret