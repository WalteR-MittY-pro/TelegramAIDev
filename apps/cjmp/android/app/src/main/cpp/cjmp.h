# ifndef CJMP_H
# define CJMP_H

#include <jni.h>

extern "C" {
void InitJni(JNIEnv *env);
const char *FfiLogicTest(void);
}

# endif