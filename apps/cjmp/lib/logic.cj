package ohos_app_cangjie_entry

import cjmp.business_exception.*
import cjmp.net.connection.*
import cjmp.business_exception.BusinessException
import cjmp.hilog.Hilog

public func getNetIPName(){
    try{
        let address = getAddressesByName("localhost")
    }catch(e : BusinessException){
        Hilog.info(0,"test","${e.message}")
    }
    Hilog.info(0,"test","getNetIPName")
}

