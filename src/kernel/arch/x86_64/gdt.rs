// MIT License
//
// Copyright (c) 2023 Mansoor Ahmed Memon.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

use lazy_static::lazy_static;
use x86_64::instructions;
use x86_64::instructions::segmentation::{CS, DS, ES, FS, GS, SS};
use x86_64::instructions::segmentation::Segment;
use x86_64::structures::gdt::{Descriptor, GlobalDescriptorTable, SegmentSelector};
use x86_64::structures::tss::TaskStateSegment;

lazy_static! {
    /// Task State Segment (TSS)
    ///
    /// A Task State Segment (TSS) is a binary data structure specific to the IA-32 and x86-64 architectures.
    /// It holds information about a task. In Protected Mode the TSS is primarily suited for Hardware Task
    /// Switching, where each individual Task has its own TSS. For use in software multitasking, one or two are
    /// also generally used, as they allow for entering Ring 0 code after an interrupt. In Long Mode, the TSS
    /// has a separate structure and is used to change the Stack Pointer after an interrupt or permission level
    /// change. You'll have to update the TSS yourself in the multitasking function, as it apparently does not
    /// save registers automatically.
    ///
    /// OS Dev Wiki: https://wiki.osdev.org/Task_State_Segment
    static ref TSS: TaskStateSegment = TaskStateSegment::new();
}

lazy_static! {
    /// Global Descriptor Table (GDT)
    ///
    /// The Global Descriptor Table (GDT) is a relic that was used for memory segmentation before paging became
    /// the de facto standard. However, it is still needed in 64-bit mode for various things, such as kernel/user
    /// mode configuration or TSS loading.
    ///
    /// The GDT is a structure that contains the segments of the program. It was used on older architectures
    /// to isolate programs from each other before paging became the standard.
    ///
    /// OS Dev Wiki: https://wiki.osdev.org/Global_Descriptor_Table
    static ref GDT: (GlobalDescriptorTable, [SegmentSelector; 3]) = {
        let mut gdt = GlobalDescriptorTable::new();

        let k_code_selector = gdt.add_entry(Descriptor::kernel_code_segment());
        let k_data_selector = gdt.add_entry(Descriptor::kernel_data_segment());
        let tss_selector = gdt.add_entry(Descriptor::tss_segment(&TSS));

        (
            gdt,
            [
                k_code_selector,
                k_data_selector,
                tss_selector,
            ]
        )
    };
}

#[repr(usize)]
pub enum GDTEntry {
    KernelCodeSegment,
    KernelDataSegment,
    TaskStateSegment,
}

pub fn init() -> Result<(), ()> {
    GDT.0.load();
    unsafe {
        // Jump to the new code segment.
        CS::set_reg(GDT.1[GDTEntry::KernelCodeSegment as usize]);

        // Load the new data segment into the segment registers.
        DS::set_reg(GDT.1[GDTEntry::KernelDataSegment as usize]);
        ES::set_reg(GDT.1[GDTEntry::KernelDataSegment as usize]);
        FS::set_reg(GDT.1[GDTEntry::KernelDataSegment as usize]);
        GS::set_reg(GDT.1[GDTEntry::KernelDataSegment as usize]);

        // In long mode, the stack segment selector's default value is 0, indicating a null segment.
        SS::set_reg(SegmentSelector::NULL);

        // Load the TSS into the processor's Task Register (TR).
        instructions::tables::load_tss(GDT.1[GDTEntry::TaskStateSegment as usize]);
    }

    Ok(())
}
