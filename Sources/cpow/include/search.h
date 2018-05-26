#ifndef __COMMON_CURL_P_SEARCH_H_
#define __COMMON_CURL_P_SEARCH_H_

#include "pearl_diver.h"
#include "pcurl_ptrit.h"
#include "trit.h"

PearlDiverStatus pd_search(Curl *, unsigned short const, unsigned short const,
                           short (*)(PCurl *, unsigned short), unsigned short);

#endif
