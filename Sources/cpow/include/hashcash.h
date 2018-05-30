#ifndef __COMMON_CURL_P_HASHCASH_H_
#define __COMMON_CURL_P_HASHCASH_H_

#include "pearl_diver.h"
#include "trit.h"

typedef enum {
  TAIL,
  BODY,
  HEAD,
} SearchType;

PearlDiverStatus hashcash(Curl *const ctx, SearchType type,
                          unsigned short const offset, unsigned short const end,
                          unsigned short const min_weight);
#endif
