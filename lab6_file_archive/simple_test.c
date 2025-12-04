void main(void) {
    *((unsigned int*) 0x80001000) = 0xdeadbeef;
    *((unsigned int*) 0x80001004) = 0x11223344;
    *((unsigned int*) 0x80001008) = 0x99887766;
    *((unsigned int*) 0x80002228) = 0xbeefabcd;
}