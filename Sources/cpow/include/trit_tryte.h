#ifndef __COMMON_TRINARY_TRIT_TRYTE_H_
#define __COMMON_TRINARY_TRIT_TRYTE_H_

#include <stdint.h>
#include "trits.h"
#include "tryte.h"

void trits_to_trytes(trit_t*, tryte_t*, size_t);
void trytes_to_trits(tryte_t*, trit_t*, size_t);

#endif
