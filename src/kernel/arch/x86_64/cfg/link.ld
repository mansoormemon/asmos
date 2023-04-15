ENTRY(_start)

_KERNEL_OFFSET = 0xFFFFFFFF80000000;

SECTIONS {
    . = 1M;

    .init ALIGN(4K) : {
		KEEP(*(.meta*))
		KEEP(*(.init*))
    }

    . += _KERNEL_OFFSET;

	. = ALIGN(4K);
	_KERNEL_BEGIN = .;

	.text ALIGN(4K) : AT(ADDR(.text) - _KERNEL_OFFSET) {
		*(.text*)
	}

	.rodata ALIGN(4K) : AT(ADDR(.rodata) - _KERNEL_OFFSET) {
        *(.rodata*)
    }

	.data ALIGN(4K) : AT(ADDR(.data) - _KERNEL_OFFSET) {
        *(.data*)
    }

    .bss ALIGN(4K) : AT(ADDR(.bss) - _KERNEL_OFFSET) {
        *(.bss*)
    }

    .got ALIGN(4K) : AT(ADDR(.got) - _KERNEL_OFFSET) {
        *(.got*)
    }

    . = ALIGN(4K);
	_KERNEL_END = .;

	/DISCARD/ :{
		*(.comment*)
        *(.eh_frame*)
        *(.gcc_except_table*)
        *(.note*)
        *(.rel.eh_frame*)
	}
}
