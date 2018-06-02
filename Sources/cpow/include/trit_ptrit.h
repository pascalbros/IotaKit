#ifndef __COMMON_TRINARY_TRIT_PTRIT_H_
#define __COMMON_TRINARY_TRIT_PTRIT_H_

#include <stdint.h>
#include "ptrit_incr.h"
#include "trits.h"

void trits_to_ptrits(trit_t*, ptrit_t*, size_t);
void ptrits_to_trits(ptrit_t*, trit_t*, size_t, size_t);

#endif
