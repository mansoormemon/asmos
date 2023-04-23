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

use log::{Level, LevelFilter, Metadata, Record, SetLoggerError};
use log::Log;

use crate::{serial_print, serial_println};

struct Logger;

impl Log for Logger {
    fn enabled(&self, metadata: &Metadata) -> bool { metadata.level() <= Level::Trace }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) { return; }

        match record.level() {
            Level::Debug => serial_print!("\x1b[1;32m debug:\x1b[0m "),
            Level::Error => serial_print!("\x1b[1;31m error:\x1b[0m "),
            Level::Info => serial_print!("\x1b[1;36m info:\x1b[0m "),
            Level::Warn => serial_print!("\x1b[1;33m warn:\x1b[0m "),
            Level::Trace => serial_print!("\x1b[1;37m trace:\x1b[0m "),
        }
        serial_println!("{}", record.args());
    }

    fn flush(&self) {}
}

pub fn init() -> Result<(), SetLoggerError> {
    log::set_logger(&Logger)?;
    log::set_max_level(LevelFilter::Trace);

    Ok(())
}
