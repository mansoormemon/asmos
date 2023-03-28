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


.global _s_start


.extern k_main


.section .rodata
.set _S_PHYSICAL_MEMORY_OFFSET, 0xFFFFFF8000000000

.set _S_STACK_SIZE, 16384

.set _S_P_STACK_TOP, _S_STACK_TOP - _S_PHYSICAL_MEMORY_OFFSET

.set _S_P_PML4, _S_PML4 - _S_PHYSICAL_MEMORY_OFFSET
.set _S_P_PDPT, _S_PDPT - _S_PHYSICAL_MEMORY_OFFSET
.set _S_P_PD, _S_PD - _S_PHYSICAL_MEMORY_OFFSET
.set _S_P_GDT64_POINTER, _s_gdt64_pointer - _S_PHYSICAL_MEMORY_OFFSET


_s_gdt64_pointer:
    .word _s_gdt64_end - _s_gdt64 - 1
    .quad _s_gdt64

.align 16
_s_gdt64:
    .quad 0
    _s_gdt64_k_code = . - _s_gdt64
    .quad 0x00AF9A000000FFFF
    _s_gdt64_k_data = . - _s_gdt64
    .quad 0x00CF92000000FFFF
_s_gdt64_end:


.section .init
.code32
_s_start:
    # Disable interrupts.
    cli

    # Set up stack.
    mov esp, offset _S_P_STACK_TOP

    # Save multiboot structure address for later use.
    mov edi, ebx

    # Perform necessary checks to ensure compatibility.
    call _s_check_multiboot
    call _s_check_cpuid
    call _s_check_long_mode

    # Set up and enable paging.
    call _s_set_up_page_tables
    call _s_enable_paging

    # Load 64-bit GDT.
    lgdt [_S_P_GDT64_POINTER]

    # Load new data segment into segment registers.
    mov eax, _s_gdt64_k_data
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax
    mov ss, eax

    # Jump into new code segment.
    jmp _s_gdt64_k_code:_s_start_higher_kernel - _S_PHYSICAL_MEMORY_OFFSET

    hlt


/**
 * Check if the kernel was loaded by multiboot compliant bootloader.
 */
_s_check_multiboot:
    cmp eax, 0x36D76289
    jne ._s_no_multiboot
    ret
._s_no_multiboot:
    mov al, 0x30
    hlt


/**
 * Check if CPUID is supported.
 *
 * Reference: https://wiki.osdev.org/CPUID#Checking_CPUID_availability
 */
_s_check_cpuid:
    # Copy FLAGS in to EAX via stack.
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
    je ._s_no_cpuid
    ret
._s_no_cpuid:
    mov al, 0x31
    hlt


/**
 * Check if long mode is supported.
 */
_s_check_long_mode:
    # Test if extended processor info is available.
    mov eax, 0x80000000                                     # Implicit argument for cpuid.
    cpuid                                                   # Get highest supported argument.
    cmp eax, 0x80000001                                     # It needs to be at least 0x80000001.
    jb ._s_no_long_mode                                     # If it's less, the CPU is too old for long mode.

    # Use extended info to test if long mode is available.
    mov eax, 0x80000001                                     # Argument for extended processor info.
    cpuid                                                   # Returns various feature bits in ecx and edx.
    test edx, 0x20000000                                    # Test if the LM-bit is set in the D-register.
    je ._s_no_long_mode                                     # If it's not set, there is no long mode.
    ret
._s_no_long_mode:
    mov al, 0x32
    hlt


/**
 * Sets up the page tables for the kernel.
 *
 * Mapping:
 *      0x0 - 0x4000_0000 -> 1 GiB [Identity Mapping]
 *      0xFFFF_FF80_0000_0000 - 0xFFFF_FF80_4000_0000 -> 1 GiB [0x0 - 0x4000_0000]
 */
_s_set_up_page_tables:
    # Map the PDPT to the PML4.
    lea ebx, [_S_P_PDPT + 0x3]                              # Present + Writable

    lea eax, [_S_P_PML4]
    mov dword ptr [eax], ebx

    lea eax, [_S_P_PML4 + 511 * 8]
    mov dword ptr [eax], ebx

    # Map the PD to the PDPT.
    lea ebx, [_S_P_PD + 0x3]                                # Present + Writable
    # Map the first entry of the PD to the first entry of the PDPT.
    lea eax, [_S_P_PDPT]
    mov dword ptr [eax], ebx

    # In a loop, map each Page Directory (PD) entry to a 2 MiB region.
    mov ecx, 0                                              # Counter
    mov eax, 0x83                                           # Starting Address + [Present + Writable + Huge Page]

._s_map_page_directory:
    mov dword ptr [_S_P_PD + ecx * 8], eax
    add eax, 0x200000                                       # Step = 2 MiB

    inc ecx
    cmp ecx, 512
    jne ._s_map_page_directory

    ret


/**
 * This function enables paging in the x86-64 architecture.
 */
_s_enable_paging:
    # Enable flags in CR4 register:
    #   1. Protected-mode Virtual Interrupts (PVI)          [1]
    #   2. Physical Address Extension (PAE)                 [5]
    #   3. Page Global Enabled (PGE)                        [7]
    mov eax, cr4
    or eax, (1 << 7) | (1 << 5) | (1 << 1)
    mov cr4, eax

    # Load PML4 to CR3 register (CPU uses this to access the PML4 table).
    lea eax, [_S_P_PML4]
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
_s_start_higher_kernel:
    # Adjust the stack pointer to point to the higher half of memory.
    mov rax, _S_PHYSICAL_MEMORY_OFFSET
    or rsp, rax

    xor rbp, rbp

    # Call kernel.
    call k_main


/**
 * This is a fallback loop in case we arrive at this point.
 */
_s_halt:
    cli
    hlt
    jmp _s_halt


.section .bss
.align 4096
_S_PML4:
    .space 4096
_S_PDPT:
    .space  4096
_S_PD:
    .space 4096
_S_STACK_GUARD_PAGE:
    .space 4096
_S_STACK_BOTTOM:
    .space _S_STACK_SIZE
_S_STACK_TOP:
