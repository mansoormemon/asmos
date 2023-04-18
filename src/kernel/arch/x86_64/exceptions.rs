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

use x86_64::structures::idt::InterruptStackFrame;

use crate::serial_println;

/// Breakpoint Exception (#BP, 0x03)
///
/// A breakpoint exception occurs when the processor encounters a debug breakpoint instruction in enabling the
/// program's execution to be paused for the inspection of its current state.
///
/// OS Dev Wiki: https://wiki.osdev.org/Exceptions#Breakpoint
pub struct BreakpointException;

impl BreakpointException {
    pub const CODE: u8 = 0x03;
    pub const MNEMONIC: &'static str = "#BP";

    pub extern "x86-interrupt" fn handler(stack_frame: InterruptStackFrame) {
        serial_println!("({}, {:#04X}) @ {:#?}", Self::MNEMONIC, Self::CODE, stack_frame);
    }
}

/// Double Fault Exception (#DF, 0x08)
///
/// A double fault exception occurs when the processor encounters an error while handling a prior exception,
/// indicating a critical system error that needs appropriate handling.
///
/// OS Dev Wiki: https://wiki.osdev.org/Exceptions#Double_Fault
pub struct DoubleFaultException;

impl DoubleFaultException {
    pub const IST_INDEX: usize = 0x0;
    pub const CODE: u8 = 0x08;
    pub const MNEMONIC: &'static str = "#DF";

    pub extern "x86-interrupt" fn handler(stack_frame: InterruptStackFrame, err_code: u64) -> ! {
        panic!("({}, {:#04X}) @ {:#?}, E={}", Self::MNEMONIC, Self::CODE, stack_frame, err_code);
    }
}
