ENTRY(_s_start)

_L_PHYSICAL_MEMORY_OFFSET = 0xFFFFFF8000000000;

SECTIONS {
    . = 1M;

    .init ALIGN(4K) : {
		KEEP(*(.meta*))
		KEEP(*(.init*))
    }

    . += _L_PHYSICAL_MEMORY_OFFSET;

	. = ALIGN(4K);
	_L_KERNEL_BEGIN = .;

	.text ALIGN(4K) : AT(ADDR(.text) - _L_PHYSICAL_MEMORY_OFFSET) {
		*(.text*)
	}

	.rodata ALIGN(4K) : AT(ADDR(.rodata) - _L_PHYSICAL_MEMORY_OFFSET) {
        *(.rodata*)
    }

	.data ALIGN(4K) : AT(ADDR(.data) - _L_PHYSICAL_MEMORY_OFFSET) {
        *(.data*)
    }

    .bss ALIGN(4K) : AT(ADDR(.bss) - _L_PHYSICAL_MEMORY_OFFSET) {
        *(.bss*)
    }

    .got ALIGN(4K) : AT(ADDR(.got) - _L_PHYSICAL_MEMORY_OFFSET) {
        *(.got*)
    }

    . = ALIGN(4K);
	_L_KERNEL_END = .;

	/DISCARD/ :{
		*(.comment*)
        *(.eh_frame*)
        *(.gcc_except_table*)
        *(.note*)
        *(.rel.eh_frame*)
	}
}
