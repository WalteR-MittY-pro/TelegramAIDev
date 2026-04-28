# cjmp

A new keels project.

## Getting Started

A new keels project.

## ios
测试：
./build.sh debug ios autorun

xcodebuild test \                                        
  -project /Users/dzy/Desktop/project/TelegramAIDev/apps/cjmp/ios/cjmp.xcodeproj \
  -scheme cjmp \
  -destination "id=00008140-000408510A02801C" \
  -only-testing:cjmpUITests/CjmpUITests/testRunSmokeCheckFromUiTestPage \
  -resultBundlePath /tmp/cjmp-ui-test.xcresult

产品：
keels build ios
keels run
## android
测试
./build.sh debug android autorun


产品：
keels build apk
keels run

