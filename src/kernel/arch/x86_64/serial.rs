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

use core::fmt::Arguments;
use core::fmt::Write;

use lazy_static::lazy_static;
use spin::Mutex;
use uart_16550::SerialPort;
use x86_64::instructions;

lazy_static! {
    /// Serial communication through 16550 UART interface.
    static ref UART_3F8: Mutex<SerialPort> = {
        // On x86_64 architecture, the UART serial device is accessed through port-mapped I/O.
        const SERIAL_IO_PORT: u16 = 0x3F8;

        let mut port = unsafe { SerialPort::new(SERIAL_IO_PORT) };
        port.init();

        Mutex::new(port)
    };
}

#[doc(hidden)]
pub fn _print(args: Arguments) {
    instructions::interrupts::without_interrupts(
        || { UART_3F8.lock().write_fmt(args).expect("failed to print to serial output"); }
    );
}
