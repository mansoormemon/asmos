/*
 * MIT License
 *
 * Copyright (c) 2023 Mansoor Ahmed Memon.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

.intel_syntax noprefix


.include "meta.s"


.global _start


.extern k_main


.section .rodata

.set _KERNEL_OFFSET, 0xFFFFFFFF80000000

.set _STACK_SIZE, 16384
.set _P_STACK_TOP, _STACK_TOP - _KERNEL_OFFSET

.set _P_P4T, _P4T - _KERNEL_OFFSET

.set _P_P3T_I, _P3T_I - _KERNEL_OFFSET
.set _P_P3T_K, _P3T_K - _KERNEL_OFFSET

.set _P_P2T_I, _P2T_I - _KERNEL_OFFSET
.set _P_P2T_K, _P2T_K - _KERNEL_OFFSET

.set _P_P1T_I, _P1T_I - _KERNEL_OFFSET
.set _P_P1T_K, _P1T_K - _KERNEL_OFFSET

/**
 * The Global Descriptor Table (GDT) is a structure that contains the segments of the program.
 *
 * Note: This is a temporary
 */
.align 16
_GDT64:
    .quad 0
    _GDT64_K_CODE = . - _GDT64
    .quad 0x00AF9A000000FFFF
    _GDT64_K_DATA = . - _GDT64
    .quad 0x00CF92000000FFFF
_GDT64_END:

_GDT64_POINTER:
    .word _GDT64_END - _GDT64 - 1
    .quad _GDT64 - _KERNEL_OFFSET

.set _P_GDT64_POINTER, _GDT64_POINTER - _KERNEL_OFFSET


.section .init.text, "ax", @progbits
.code32
_start:
    /* Disable interrupts. */
    cli

    /* Set up stack. */
    mov esp, offset _P_STACK_TOP

    /* Save multiboot structure address for later use. */
    mov edi, ebx

    /* Perform necessary checks to ensure compatibility. */
    call _check_multiboot
    call _check_cpuid
    call _check_long_mode

    /* Set up and enable paging. */
    call _set_up_page_tables
    call _enable_paging

    /* Load 64-bit GDT. */
    lgdt [_P_GDT64_POINTER]

    /* Load the new data segment into the segment registers. */
    mov eax, _GDT64_K_DATA
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax
    mov ss, eax

    /* Jump to the new code segment. */
    jmp far ptr _GDT64_K_CODE:_start_higher_kernel - _KERNEL_OFFSET

    hlt


/**
 * Checks if the kernel was loaded by multiboot compliant bootloader.
 */
_check_multiboot:
    cmp eax, 0x36D76289
    jne ._no_multiboot
    ret
._no_multiboot:
    mov al, 0x30
    hlt


/**
 * Checks if CPUID is supported.
 *
 * Reference: https://wiki.osdev.org/CPUID#Checking_CPUID_availability
 */
_check_cpuid:
    pushfd
    pop eax
    /* Copy to ECX as well for comparing later on. */
    mov ecx, eax
    /* Flip the ID bit. */
    xor eax, 0x200000
    /* Copy EAX to FLAGS via the stack. */
    push eax
    popfd
    /* Copy FLAGS back to EAX (with the flipped bit if CPUID is supported). */
    pushfd
    pop eax
    /* Restore FLAGS from the old version stored in ECX. */
    push ecx
    popfd

    /* Compare EAX and ECX. If they are equal then that means the bit wasn't flipped, and CPUID isn't supported. */
    cmp eax, ecx
    je ._no_cpuid
    ret
._no_cpuid:
    mov al, 0x31
    hlt


/**
 * Checks if long mode is supported.
 *
 * Reference: https://wiki.osdev.org/Setting_Up_Long_Mode#x86_or_x86-64
 */
_check_long_mode:
    /* Test if extended processor info is available. */
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb ._no_long_mode

    /* Use extended info to test if long mode is available. */
    mov eax, 0x80000001
    cpuid
    test edx, 0x20000000
    je ._no_long_mode
    ret
._no_long_mode:
    mov al, 0x32
    hlt


/**
 * Sets up page tables for the kernel.
 */
_set_up_page_tables:
    lea ebx, [_P_P3T_I + 0x3]
    lea eax, [_P_P4T]
    mov dword ptr [eax], ebx

    lea ebx, [_P_P2T_I + 0x3]
    lea eax, [_P_P3T_I]
    mov dword ptr [eax], ebx

    lea ebx, [_P_P1T_I + 0x3]
    lea eax, [_P_P2T_I]
    mov dword ptr [eax], ebx

    mov ecx, 0
    mov eax, 0x3

._identity_map:
    mov dword ptr [_P_P1T_I + ecx * 8], eax
    add eax, 0x1000

    inc ecx
    cmp ecx, 512
    jne ._identity_map

    lea ebx, [_P_P3T_K + 0x3]
    lea eax, [_P_P4T + 511 * 8]
    mov dword ptr [eax], ebx

    lea ebx, [_P_P2T_K + 0x3]
    lea eax, [_P_P3T_K + 510 * 8]
    mov dword ptr [eax], ebx

    lea ebx, [_P_P1T_K + 0x3]
    lea eax, [_P_P2T_K]
    mov dword ptr [eax], ebx

    mov ecx, 0
    mov eax, 0x3

._kernel_map:
    mov dword ptr [_P_P1T_K + ecx * 8], eax
    add eax, 0x1000

    inc ecx
    cmp ecx, 512
    jne ._kernel_map

    ret


/**
 * Enables paging.
 */
_enable_paging:
    /*
     * Enable flags in CR4 register:
     * 1. Protected-mode Virtual Interrupts (PVI)          [1]
     * 2. Physical Address Extension (PAE)                 [5]
     * 3. Page Global Enabled (PGE)                        [7]
     */
    mov eax, cr4
    or eax, (1 << 7) | (1 << 5) | (1 << 1)
    mov cr4, eax

    /* Load PML4 to CR3 register (CPU uses this to access the PML4 table). */
    lea eax, [_P_P4T]
    mov cr3, eax

    /* Set the long mode bit in the Extended Feature Enable Register (EFER). */
    mov ecx, 0xC0000080
    /*
     * Enable flags in EFER MSR:
     *  1. Long Mode Enable (LME)           [8]
     *  2. No-Execute Enable (NXE)          [11]
     */
    rdmsr
    or eax, (1 << 11) | (1 << 8)
    wrmsr

    /*
     * Enable flags in CR0 register:
     *  1. Write Protect (WP)           [16]
     *  2. Paging (PG)                  [31]
     */
    mov eax, cr0
    or eax, (1 << 31) | (1 << 16)
    mov cr0, eax

    ret


.section .text, "ax", @progbits
.code64
_start_higher_kernel:
    /* Adjust the stack pointer to point to the higher half of memory. */
    mov rax, _KERNEL_OFFSET
    or rsp, rax

    or rdi, rax

    xor rbp, rbp

    /* Call kernel. */
    call k_main


/**
 * This is a fallback loop in case we arrive at this point.
 */
_halt:
    cli
    hlt
    jmp _halt


.section .bss

.align 4096
_P4T:
    .space 4096
_P3T_I:
    .space 4096
_P3T_K:
    .space 4096
_P2T_I:
    .space 4096
_P2T_K:
    .space 4096
_P1T_I:
    .space 4096
_P1T_K:
    .space 4096
_STACK_GUARD_PAGE:
    .space 4096
_STACK_BOTTOM:
    .space _STACK_SIZE
_STACK_TOP:
