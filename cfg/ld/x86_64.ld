OUTPUT_FORMAT("elf64-x86-64")
ENTRY(_start)

_KERNEL_OFFSET = 0xFFFFFFFF80000000;

SECTIONS {
    _RESERVED_REGION_BEGIN = .;

    . = 1M;

    _PRELUDE_REGION_BEGIN = .;

    .init : {
		KEEP(*(.meta*))
		KEEP(*(.init*))
	    . = ALIGN(4K);
    }

    _PRELUDE_REGION_END = .;

    . += _KERNEL_OFFSET;

	_KERNEL_REGION_BEGIN = .;

	.text : AT(ADDR(.text) - _KERNEL_OFFSET) {
		*(.text*)
	    . = ALIGN(4K);
	}

	.rodata : AT(ADDR(.rodata) - _KERNEL_OFFSET) {
        *(.rodata*)
	    . = ALIGN(4K);
    }

	.data : AT(ADDR(.data) - _KERNEL_OFFSET) {
        *(.data*)
	    . = ALIGN(4K);
    }

    .bss : AT(ADDR(.bss) - _KERNEL_OFFSET) {
        *(.bss*)
	    . = ALIGN(4K);
    }

    .got : AT(ADDR(.got) - _KERNEL_OFFSET) {
        *(.got*)
	    . = ALIGN(4K);
    }

	_KERNEL_REGION_END = .;

    . = ALIGN(2M);
	_RESERVED_REGION_END = . - _KERNEL_OFFSET;

	/DISCARD/ : {
		*(.comment*)
        *(.eh_frame*)
        *(.gcc_except_table*)
        *(.note*)
        *(.rel.eh_frame*)
	}
}
