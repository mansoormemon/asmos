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

.section .meta
.align 8
_multiboot_header:
    .long 0xE85250D6
    .long 0
    .long _multiboot_header_end - _multiboot_header
    .long -(0xE85250D6 + 0 + (_multiboot_header_end - _multiboot_header))

.align 8
_info_request:
    .short 1
    .short 0
    .long _info_request_end - _info_request
    .long 6
_info_request_end:

.align 8
_console_request:
    .short 4
    .short 0
    .long _console_request_end - _console_request
    .long 3
_console_request_end:

.align 8
_framebuffer_request:
    .short 5
    .short 1
    .long _framebuffer_request_end - _framebuffer_request
    .long 80
    .long 25
    .long 0
_framebuffer_request_end:

.align 8
    .short 0
    .short 0
    .long 8
_multiboot_header_end:
