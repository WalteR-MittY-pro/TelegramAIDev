package com.example.cjmp;

public class cjmp {
    private static Thread smokeRunnerThread;

    public static native void initDemoSessionStorageRoot(String storageRoot);
    public static native long runSmokeSuiteFromNative();

    static public String logicTest() {
        return "String returned from logicTest func in java class.";
    }

    public static synchronized long startSmokeSuiteRunner() {
        if (smokeRunnerThread != null && smokeRunnerThread.isAlive()) {
            return 0L;
        }
        smokeRunnerThread = new Thread(() -> {
            try {
                Thread.sleep(500L);
                runSmokeSuiteFromNative();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "cjmp-smoke-runner");
        smokeRunnerThread.start();
        return 1L;
    }
}
