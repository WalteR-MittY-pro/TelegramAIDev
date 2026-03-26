#include "cjmp_ffi.h"

#import "cjmp.h"
#import <Foundation/Foundation.h>

const char* FfiLogicTest(void) {
    @autoreleasepool {
        NSString *result = [cjmp logicTest];
        return strdup([result UTF8String]);
    }
}

void FfiFreeString(const char* str) {
    free((void*)str);
}