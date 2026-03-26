#include "cjmp.h"
#include <android/log.h>
#include <jni.h>

JavaVM *g_javaVm = nullptr;
JNIEnv *g_jniEnv = nullptr;
jobject g_cls = nullptr;

#define LOGTAG "CJMP_JNI"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOGTAG, __VA_ARGS__)

jint JNI_OnLoad(JavaVM *vm, void *reserved) {
  g_javaVm = vm;

  if (vm->GetEnv((void **)&g_jniEnv, JNI_VERSION_1_6) != JNI_OK) {
    return JNI_ERR;
  }

  jclass myClass =
      g_jniEnv->FindClass("com/example/cjmp/cjmp");
  g_cls = g_jniEnv->NewGlobalRef(myClass);
  if (g_cls == nullptr) {
    LOGE("class not found.");
    return JNI_ERR;
  }

  return JNI_VERSION_1_6;
}

const char *FfiLogicTest() {
  if (g_javaVm == nullptr) {
    LOGE("JavaVM not initialized");
    return nullptr;
  }
  jclass cls = (jclass)g_cls;
  jmethodID ffiLogicTest =
      g_jniEnv->GetStaticMethodID(cls, "logicTest", "()Ljava/lang/String;");
  jobject result = g_jniEnv->CallStaticObjectMethod(cls, ffiLogicTest);
  return g_jniEnv->GetStringUTFChars((jstring)result, nullptr);
}
