package com.example.cjmp;

import android.content.Context;
import android.content.Intent;
import android.os.SystemClock;
import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

@RunWith(AndroidJUnit4.class)
public class CjmpSmokeInstrumentedTest {
    private static final String PACKAGE_NAME = "com.example.cjmp";
    private static final String ACTIVITY_NAME = "com.example.cjmp.EntryEntryAbilityActivity";
    private static final String STATUS_FILE_NAME = "telegram_ui_smoke_status.txt";
    private static final long SMOKE_TIMEOUT_MS = 120000L;
    private static final long STATUS_POLL_INTERVAL_MS = 1000L;
    private static final String[] TERMINAL_STATUSES = {
            "passed",
            "failed",
            "crashed"
    };

    @Test
    public void runSmokeFromUiTestPage() throws Exception {
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        appContext.deleteFile(STATUS_FILE_NAME);

        Intent intent = new Intent();
        intent.setClassName(PACKAGE_NAME, ACTIVITY_NAME);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        appContext.startActivity(intent);

        String terminalStatus = waitForTerminalStatus(appContext, SMOKE_TIMEOUT_MS);
        assertNotNull("Smoke suite did not expose a terminal status", terminalStatus);
        assertEquals("passed", terminalStatus);
    }

    private String waitForTerminalStatus(Context appContext, long timeoutMs) throws IOException {
        File statusFile = new File(appContext.getFilesDir(), STATUS_FILE_NAME);
        long deadline = SystemClock.uptimeMillis() + timeoutMs;
        while (SystemClock.uptimeMillis() < deadline) {
            if (statusFile.exists()) {
                String status = new String(Files.readAllBytes(statusFile.toPath()), StandardCharsets.UTF_8).trim();
                for (String terminalStatus : TERMINAL_STATUSES) {
                    if (terminalStatus.equals(status)) {
                        return status;
                    }
                }
            }
            SystemClock.sleep(STATUS_POLL_INTERVAL_MS);
        }
        return null;
    }
}
