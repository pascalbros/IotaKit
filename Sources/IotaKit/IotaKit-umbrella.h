#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "addresses.h"
#import "common.h"
#import "conversion.h"
#import "iota_address.h"
#import "iota_types.h"
#import "kerl.h"
#import "macros.h"
#import "options.h"
#import "sha3new.h"
#import "sha3.h"

FOUNDATION_EXPORT double IotaKitVersionNumber;
FOUNDATION_EXPORT const unsigned char IotaKitVersionString[];

