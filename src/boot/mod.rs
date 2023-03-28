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

use multiboot2::BootInformation;

macro_rules! foreign_symbol {
    ($symbol:ident) => (unsafe { &$symbol as *const u8 as usize });
}

extern "C" {
    static _L_PHYSICAL_MEMORY_OFFSET: u8;

    static _L_KERNEL_BEGIN: u8;
    static _L_KERNEL_END: u8;
}

static mut MULTIBOOT_INFO: Option<BootInformation> = None;

pub fn init(boot_info_addr: usize) {
    unsafe {
        MULTIBOOT_INFO = multiboot2::load(boot_info_addr).ok();
    }
}

pub fn get_info() -> &'static BootInformation {
    unsafe { MULTIBOOT_INFO.as_ref().unwrap() }
}

pub fn physical_memory_offset() -> usize {
    foreign_symbol!(_L_PHYSICAL_MEMORY_OFFSET)
}

pub fn kernel_begin() -> usize {
    foreign_symbol!(_L_KERNEL_BEGIN)
}

pub fn kernel_end() -> usize {
    foreign_symbol!(_L_KERNEL_END)
}
