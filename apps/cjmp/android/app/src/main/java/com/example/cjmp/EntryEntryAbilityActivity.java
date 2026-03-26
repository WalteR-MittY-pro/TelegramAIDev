package com.example.cjmp;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import ohos.stage.ability.adapter.StageActivity;


public class EntryEntryAbilityActivity extends StageActivity {
    static {
        System.loadLibrary("jnicjmp");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.e("HiHelloWorld", "EntryEntryAbilityActivity");

        Intent intent = getIntent();
        if (intent != null) {
            intent.putExtra("test", "test");             // value对于本测试框架无意义
            intent.putExtra("bundleName", "bundleName"); // value对于本测试框架无意义
            intent.putExtra("moduleName", "moduleName"); // value对于本测试框架无意义
            intent.putExtra("unittest", "unittest");     // value对于本测试框架无意义
            intent.putExtra("timeout", "101");           // value对于本测试框架无意义
        }

        setInstanceName("com.example.cjmp:entry:EntryAbility:");
        super.onCreate(savedInstanceState);
    }
}
