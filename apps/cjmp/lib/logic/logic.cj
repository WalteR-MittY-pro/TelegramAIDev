package ohos_app_cangjie_entry.logic

import ohos.hilog.Hilog

@When[target_platform != "hos"]
public func logicTest(): String {
    let testStr: CString = unsafe { FfiLogicTest() }
    testStr.toString()
}

foreign func FfiLogicTest(): CString

@When[target_platform == "hos"]
public func logicTest(): String {
    return "String returned from logicTest func in CJ. HarmonyOS APP natively supports the Cangjie language."
}
