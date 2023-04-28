extern get_value
extern put_value

%macro direct 2
    cmp r8b, %1
    je %2
%endmacro

%macro push_jmp_loop 1
    push %1
    jmp .loop
%endmacro

section .data
    thread_locks times N dq -1

section .bss
    thread_values resq N

section .text
    global core

core:
    push rbp
    mov r8, 0
    push r12
    push r13
    push r14
    push r15

    mov rbp, rsp
    mov r12, rdi
    mov r13, rsi
    lea r14, [rel thread_locks]
    lea r15, [rel thread_values]

.loop:
    mov r8b, byte [r13]
    inc r13
    direct 0, .quit
    direct '+', .plus
    direct '*', .mult
    direct '-', .minus
    direct 'n', .thread_num
    direct 'B', .shift
    direct 'C', .delete
    direct 'D', .dup
    direct 'E', .exchange
    direct 'G', .get
    direct 'P', .put
    direct 'S', .sync
    jmp .number

.plus:
    pop r10
    pop r11
    add r11, r10
    push_jmp_loop r11

.mult:
    pop r10
    pop r11
    imul r11, r10
    push_jmp_loop r11

.minus:
    pop r10
    neg r10
    push_jmp_loop r10

.thread_num:
    push_jmp_loop r12

.shift:
    pop r10
    pop r11
    cmp r11, 0
    push r11
    je .loop
    add r13, r10
    jmp .loop  

.delete:
    pop r10
    jmp .loop

.dup:
    mov r10, QWORD [rsp]
    push_jmp_loop r10

.exchange:
    pop r10
    pop r11
    push r10
    push_jmp_loop r11

.get:
    mov rdi, r12
    call get_value
    push_jmp_loop rax

.put:
    mov rdi, r12
    pop rsi
    call put_value
    jmp .loop

.sync:
    pop r10 ; pop thread num (m)
    pop QWORD [r15 + 8 * r12] ; set thread_values[n] to value to exchange

    mov rax, r10
    xchg QWORD [r14 + 8 * r12], rax ; set lock[n] = m

.active_wait_1: ; active wait on lock[m] = n
    mov rax, r12
    lock \
    cmpxchg QWORD [r14 + 8 * r10], rax
    jne .active_wait_1

    push QWORD [r15 + 8 * r10] ; set thread_value[m] on top of stack

     
    mov QWORD [r14 + 8 * r10], -1; set lock[m] = -1

.active_wait_2: ; active wait on lock[n] = -1
    mov rax, -1
    lock \
    cmpxchg QWORD [r14 + 8 * r12], rax    
    jne .active_wait_2

    jmp .loop

.number:
    cmp   r8b, '0'
    jb    .quit
    cmp   r8b, '9'
    ja    .quit

    sub r8b, '0'
    push_jmp_loop r8

.quit:
    pop rax
    mov rsp, rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret