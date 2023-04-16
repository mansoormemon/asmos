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
use x86_64::structures::idt::InterruptDescriptorTable;

lazy_static! {
    /// Interrupt Descriptor Table (IDT)
    ///
    /// TThe Interrupt Descriptor Table (IDT) is a binary data structure specific to the IA-32 and x86-64
    /// architectures. It is the Protected Mode and Long Mode counterpart to the Real Mode Interrupt Vector
    /// Table (IVT) telling the CPU where the Interrupt Service Routines (ISR) are located (one per interrupt
    /// vector).
    ///
    /// NOTE: Before implementing the IDT, ensure that a functional GDT is available.
    ///
    /// OS Dev Wiki: https://wiki.osdev.org/Interrupt_Descriptor_Table
    static ref IDT: InterruptDescriptorTable = {
        let idt = InterruptDescriptorTable::new();

        idt
    };
}

pub fn init() -> Result<(), ()> {
    IDT.load();

    Ok(())
}
