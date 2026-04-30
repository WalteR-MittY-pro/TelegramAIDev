# ifndef CJMP_H
# define CJMP_H

#include <jni.h>

extern "C" {
const char *FfiLogicTest(void);
long long FfiStartSmokeSuiteRunner(void);
long long FfiSaveDemoSessionPhone(const char *phoneNumber);
const char *FfiLoadDemoSessionPhone(void);
void FfiClearDemoSessionPhone(void);
void FfiFreeString(const char *str);
}

# endif
