#include <lame/lame.h>
#include <stdint.h>
long check_lame_set_VBR_quality(void) { return (long) lame_set_VBR_quality; }
int main(void) { int ret = 0;
ret |= ((intptr_t)check_lame_set_VBR_quality) & 0xFFFF;
return ret; }
