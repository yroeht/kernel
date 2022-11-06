#include "gdt.h"
#include "idt.h"
#include "isr.h"

static struct gate_descriptor idt[256];

static struct idt_descriptor idt_descriptor;

void init_idt(void)
{
#define ISR(n, str, has_error, is_excn)                        \
	idt[n].offset_lo =                                     \
	     (int)interrupt_handler##n & 0xffff;               \
	idt[n].segment_selector = kernel_cs;                   \
	idt[n].reserved0 = 0;                                  \
	if (is_excn)                                           \
		idt[n].gate_type = is_excn                     \
			? gate_type_32bit_trap                 \
		 	: gate_type_32bit_int;                 \
	idt[n].reserved1 = 0;                                  \
	idt[n].dpl = 0;                                        \
	idt[n].present = 1;                                    \
	idt[n].offset_hi =                                     \
		(int)interrupt_handler##n >> 16;               \

#include "isr-list.inc"

#undef ISR

	idt_descriptor.size = sizeof (struct idt_descriptor)
		* sizeof idt - 1;
	idt_descriptor.offset = (long)idt;

	asm volatile("lidt %0" : : "m"(idt_descriptor));
	asm volatile("sti");
}
