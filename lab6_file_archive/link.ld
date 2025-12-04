ENTRY(_start)

SECTIONS
{
    /* Code starts at address 0x0 */
    . = 0x80000000;
    .text : { *(.text*) }
}