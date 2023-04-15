# MIT License
#
# Copyright (c) 2023 Mansoor Ahmed Memon.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

.intel_syntax noprefix


.include "meta.s"


.global _start


.extern k_main


.section .rodata

.set _KERNEL_OFFSET, 0xFFFFFFFF80000000

.set _STACK_SIZE, 16384
.set _P_STACK_TOP, _STACK_TOP - _KERNEL_OFFSET

.set _P_PML4, _PML4 - _KERNEL_OFFSET
.set _P_PDPT_L, _PDPT_L - _KERNEL_OFFSET
.set _P_PDPT_H, _PDPT_H - _KERNEL_OFFSET
.set _P_PD, _PD - _KERNEL_OFFSET


.section .init
.code32

/**
 * The Global Descriptor Table (GDT) is a structure that contains the segments of the program.
 */
.align 16
_gdt64:
    .quad 0
    _gdt64_k_code = . - _gdt64
    .quad 0x00AF9A000000FFFF
    _gdt64_k_data = . - _gdt64
    .quad 0x00CF92000000FFFF
_gdt64_end:

_gdt64_pointer:
    .word _gdt64_end - _gdt64 - 1
    .quad _gdt64


_start:
    # Disable interrupts.
    cli

    # Set up stack.
    mov esp, offset _P_STACK_TOP

    # Save multiboot structure address for later use.
    mov edi, ebx

    # Perform necessary checks to ensure compatibility.
    call _check_multiboot
    call _check_cpuid
    call _check_long_mode

    # Set up and enable paging.
    call _set_up_page_tables
    call _enable_paging

    # Load 64-bit GDT.
    lgdt [_gdt64_pointer]

    # Load the new data segment into the segment registers.
    mov eax, _gdt64_k_data
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax
    mov ss, eax

    # Jump to the new code segment.
    jmp _gdt64_k_code:_start_higher_kernel - _KERNEL_OFFSET

    hlt


/**
 * Check if the kernel was loaded by multiboot compliant bootloader.
 */
_check_multiboot:
    cmp eax, 0x36D76289
    jne ._no_multiboot
    ret
._no_multiboot:
    mov al, 0x30
    hlt


/**
 * Check if CPUID is supported.
 *
 * Reference: https://wiki.osdev.org/CPUID#Checking_CPUID_availability
 */
_check_cpuid:
    pushfd
    pop eax
    # Copy to ECX as well for comparing later on.
    mov ecx, eax
    # Flip the ID bit.
    xor eax, 0x200000
    # Copy EAX to FLAGS via the stack.
    push eax
    popfd
    # Copy FLAGS back to EAX (with the flipped bit if CPUID is supported).
    pushfd
    pop eax
    # Restore FLAGS from the old version stored in ECX (i.e. flipping the ID bit back if
    # it was ever flipped).
    push ecx
    popfd

    # Compare EAX and ECX. If they are equal then that means the bit wasn't flipped, and
    # CPUID isn't supported.
    cmp eax, ecx
    je ._no_cpuid
    ret
._no_cpuid:
    mov al, 0x31
    hlt


/**
 * Check if long mode is supported.
 *
 * Reference: https://wiki.osdev.org/Setting_Up_Long_Mode#x86_or_x86-64
 */
_check_long_mode:
    # Test if extended processor info is available.
    mov eax, 0x80000000                                     # Implicit argument for cpuid.
    cpuid                                                   # Get highest supported argument.
    cmp eax, 0x80000001                                     # It needs to be at least 0x80000001.
    jb ._no_long_mode                                       # If it's less, the CPU is too old for long mode.

    # Use extended info to test if long mode is available.
    mov eax, 0x80000001                                     # Argument for extended processor info.
    cpuid                                                   # Returns various feature bits in ecx and edx.
    test edx, 0x20000000                                    # Test if the LM-bit is set in the D-register.
    je ._no_long_mode                                       # If it's not set, there is no long mode.
    ret
._no_long_mode:
    mov al, 0x32
    hlt


/**
 * Sets up page tables for the kernel.
 *
 * =====================================================================================
 *                                      MEMORY MAP
 * -------------------------------------------------------------------------------------
 *  0x0 - 0x4000_0000                               |   1 GiB   |   [0x0 - 0x4000_0000]
 *  0xFFFF_FFFF_8000_0000 - 0xFFFF_FFFF_C000_0000   |   1 GiB   |   [0x0 - 0x4000_0000]
 * =====================================================================================
 */
_set_up_page_tables:
    # Map the lower 1 GiB of memory to the PML4.
    lea ebx, [_P_PDPT_L + 0x3]                              # Load the address of the lower PDPT with the PRESENT and WRITABLE flags.
    lea eax, [_P_PML4]                                      # Load the address of the PML4 into EAX.
    mov dword ptr [eax], ebx                                # Set the value of the PML4 to the lower PDPT address.

    # Map the upper 511 GiB of memory to the PML4.
    lea ebx, [_P_PDPT_H + 0x3]                              # Load the address of the higher PDPT with the PRESENT and WRITABLE flags.
    lea eax, [_P_PML4 + 511 * 8]                            # Load the address of the last PML4 entry into EAX.
    mov dword ptr [eax], ebx                                # Set the value of the last PML4 entry to the higher PDPT address.

    # Map the PD to the PDPT.
    lea ebx, [_P_PD + 0x3]                                  # Load the address of the PD with the PRESENT and WRITABLE flags.

    lea eax, [_P_PDPT_L]                                    # Load the address of the lower PDPT into EAX.
    mov dword ptr [eax], ebx                                # Set the value of the lower PDPT to the PD address.

    lea eax, [_P_PDPT_H + 510 * 8]                          # Load the address of the 510th PDPT entry into EAX.
    mov dword ptr [eax], ebx                                # Set the value of the 510th PDPT entry to the PD address.

    # In a loop, map each Page Directory (PD) entry to a 2 MiB region.
    mov ecx, 0                                              # Counter
    mov eax, 0x83                                           # Starting Address + [Present + Writable + Huge Page]

._map_page_directory:
    mov dword ptr [_P_PD + ecx * 8], eax
    add eax, 0x200000                                       # Step = 2 MiB

    inc ecx
    cmp ecx, 512
    jne ._map_page_directory

    ret


/**
 * This function enables paging in the x86-64 architecture.
 */
_enable_paging:
    # Enable flags in CR4 register:
    #   1. Protected-mode Virtual Interrupts (PVI)          [1]
    #   2. Physical Address Extension (PAE)                 [5]
    #   3. Page Global Enabled (PGE)                        [7]
    mov eax, cr4
    or eax, (1 << 7) | (1 << 5) | (1 << 1)
    mov cr4, eax

    # Load PML4 to CR3 register (CPU uses this to access the PML4 table).
    lea eax, [_P_PML4]
    mov cr3, eax

    # Set the long mode bit in the Extended Feature Enable Register (EFER).
    mov ecx, 0xC0000080
    # Enable flags in EFER MSR:
    #   1. Long Mode Enable (LME)           [8]
    #   2. No-Execute Enable (NXE)          [11]
    rdmsr
    or eax, (1 << 11) | (1 << 8)
    wrmsr

    # Enable flags in CR0 register:
    #   1. Write Protect (WP)           [16]
    #   2. Paging (PG)                  [31]
    mov eax, cr0
    or eax, (1 << 31) | (1 << 16)
    mov cr0, eax

    ret


.section .text
.code64

_start_higher_kernel:
    # Adjust the stack pointer to point to the higher half of memory.
    mov rax, _KERNEL_OFFSET
    or rsp, rax

    xor rbp, rbp

    # Call kernel.
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
_PML4:
    .space 4096
_PDPT_L:
    .space 4096
_PDPT_H:
    .space 4096
_PD:
    .space 4096
_STACK_GUARD_PAGE:
    .space 4096
_STACK_BOTTOM:
    .space _STACK_SIZE
_STACK_TOP:
