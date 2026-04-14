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

long long FfiSaveDemoSessionPhone(const char* phoneNumber) {
    @autoreleasepool {
        NSString *value = phoneNumber == NULL ? @"" : [NSString stringWithUTF8String:phoneNumber];
        return [cjmp saveDemoSessionPhone:value] ? 1 : 0;
    }
}

const char* FfiLoadDemoSessionPhone(void) {
    @autoreleasepool {
        NSString *result = [cjmp loadDemoSessionPhone];
        return strdup([result UTF8String]);
    }
}

void FfiClearDemoSessionPhone(void) {
    @autoreleasepool {
        [cjmp clearDemoSessionPhone];
    }
}
