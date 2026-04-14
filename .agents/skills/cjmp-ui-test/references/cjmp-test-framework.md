> Preserved copy of `/Users/dzy/Desktop/CJMP/docs/zh-cn/app-dev/quick-start/test-framework.md` for the `cjmp-ui-test` skill. Keep this file as a fallback reference if the original CJMP documentation moves or is deleted.

# CJMP 测试框架介绍

## 1. 简介

这是CJMP自动化UI测试框架的使用指南，该框架为跨平台应用开发自动化测试提供所需的能力，可支持针对应用界面的组件进行查找，并可基于组件或坐标进行如点击、滑动等基本操作能力。
开始本章的阅读前，建议您先行阅读[创建CJMP应用](./get-start.md)。

- 本测试框架是基于鸿蒙开源的 ohos.ui_test 做的 Android&iOS 适配，因此可参考鸿蒙官方开源文档：[ohos.ui_test（UI测试）](https://developer.huawei.com/consumer/cn/doc/cangjie-references/cj-apis-ui_test#func-getdisplaysize)

> 备注：已实现接口均保持三端统一（详情见[已实现接口说明](#3-已实现接口)）

## 2. 使用说明

#### 创建CJMP应用

CJMP应用的创建参考[创建CJMP应用](./get-start.md)，假设创建一个名为demo的CJMP应用

#### 配置工程

由于测试框架依赖AbilityDelegator，而正常应用启动流程不会使能AbilityDelegator，因此需要额外增加一些启动参数

- Android
  - 需要在EntryEntryAbilityActivity.java文件中添加一个Intent，用于应用启动时使能AbilityDelegator
  ```java
  // android/app/src/main/java/com/example/demo/EntryEntryAbilityActivity.java
  public class EntryEntryAbilityActivity extends StageActivity {
      @Override
      protected void onCreate(Bundle savedInstanceState) {
          Log.e("HiHelloWorld", "EntryEntryAbilityActivity");

          // 配置以下intent
          Intent intent = getIntent();
          if (intent != null) {
              // 启动参数是按照key value输入的，关键是key，value的取值无影响，不为null即可
              intent.putExtra("test", "test");
              intent.putExtra("bundleName", "bundleName");
              intent.putExtra("moduleName", "moduleName");
              intent.putExtra("unittest", "unittest");
              intent.putExtra("timeout", "101");
          }

          setInstanceName("com.example.demo:entry:EntryAbility:");
          super.onCreate(savedInstanceState);

      }
  }
  ```
- iOS
  - 需通过Xcode启动测试
  - `打开Xcode -> Product -> Scheme -> Edit Scheme`
  <img src="image/xcode-screenshot.jpg" alt="Xcode Screenshot" width="720" />
  - `打开Scheme后，点击 Arguments，按顺序输入图示的参数，和android侧一样，value的取值无影响`
  <img src="image/xcode-arguments.jpg" alt="Xcode Arguments" width="720" />
- 如何导入模块

```cangjie
import ohos.ui_test.*
```

- demo演示
  - 实现功能:
    - 测试用例1: 点击屏幕中的button，触发测试用例，滑动列表找到标记为10的文本组件；
      - 录屏效果演示（GitCode 等网页端通常无法内嵌播放视频，可点击下图或链接下载/本地播放）：
        [录屏文件（mp4）](./image/test-video.mp4)
        [![点击查看录屏](./image/test-ui.jpg)](./image/test-video.mp4)
        
    - 测试用例2: 对组件进行截图保存至本地，然后退出到桌面；
      - 截图示例（部分平台不支持在线预览bmp格式，文档内为便于网页预览使用 PNG）：
        [原始 bmp 文件](./image/myList.bmp)
        <img src="image/myList.png" alt="列表组件截图示例" width="360" />
  - ui界面:
  ```cangjie
  // lib/index.cj

  package ohos_app_cangjie_entry

    internal import ohos.base.*
    internal import ohos.component.*
    internal import ohos.router.Router
    internal import ohos.state_manage.SubscriberManager
    internal import ohos.state_manage.ObservedProperty
    internal import ohos.state_manage.LocalStorage
    import ohos.state_macro_manage.Entry
    import ohos.state_macro_manage.Component
    import ohos.state_macro_manage.State

    @Entry
    @Component
    class EntryView {
        var listScroller: ListScroller = ListScroller()
        let arr = Array<Int64>(100, {i => i})

        @State
        var textMsg: String = "nihao"

        @State
        var message: String = "click the button below to run tests"
        @State
        var cnt = 0
        func build() {
            Column() {
                Text(this.message)
                .height(10.percent)
                .width(100.percent)
                .fontSize(20)
                .margin(10)
                .textAlign(TextAlign.Center)

                Column() {
                    Button("Click Me")
                    .width(50.percent)
                    .height(50)
                    .fontSize(20)
                    .width(80.percent)
                    .id("button")
                    .onClick {
                        event => spawn {
                            exclusiveScope {
                                Test_UItest().asTestSuite().runTests()
                            }
                        }
                    }
                }
                .height(10.percent)
                .width(80.percent)
                

                List(space: 100, initialIndex: 0, scroller: this.listScroller, ) {
                    ForEach(this.arr, itemGeneratorFunc: {
                        item: Int64, _: Int64 => ListItem() {
                            Text("${item}")
                                .width(100.percent)
                                .height(40)
                                .fontSize(16)
                                .textAlign(TextAlign.Center)
                                .borderRadius(10)
                                .backgroundColor(0xDCDCDC)
                                .id("listItem${item}")
                        }
                    })
                }
                .id("list")
                .listDirection(Axis.Vertical)
                .edgeEffect(EdgeEffect.Spring)
                .width(100.percent)
                .height(80.percent)
                .scrollBar(BarState.Off)
                .divider(strokeWidth: 2.px, color: Color(0xDCDCDC), startMargin: 10.px, endMargin: 10.px)


            }.height(100.percent)
        }
    }
  ```

  - 测试用例:

  ```cangjie
  // lib/testcase.cj
  package ohos_app_cangjie_entry

  import std.unittest.*
  import std.unittest.common.*
  import std.unittest.testmacro.*
  import ohos.ui_test.Driver
  import ohos.ui_test.UIComponent
  import ohos.ui_test.On
  import ohos.base.BusinessException

  @Test
  public class Test_UItest {
      @TestCase
      func test_scrollsearch() {
          let driver = Driver.create()
          try {
              let component = driver.findComponent(On().id("list"))
              component.click()
              let targetComponent = component.scrollSearch(On().id("listItem10"))
              match (targetComponent) {
                  case Some(target) => AppLog.info("uitest scrollSearch find ${target.getId()}")
                  case _ => AppLog.info("uitest scrollSearch not find")
              }
          } catch (e: BusinessException) {
              AppLog.info("test_FfiFindComponent failed.")
              @Expect(false)
          }   
      }

      @TestCase
      func test_snapshot() {
          let driver = Driver.create()
          try {
          let component = driver.findComponent(On().id("list"))
          @Expect(component.getType(), "List")

          // 截图保存组件，路径 path 需要是“应用可写”的目录；否则可能保存失败。
          // Android 示例（以包名 com.example.demo 为例）：
          //   /data/data/com.example.demo/cache/myList.bmp
          // iOS 示例（写入到应用 Documents 目录（可写）后，再拼接文件名）：
          //   <docPath>/myList.bmp
          component.getSnapshot("/data/data/com.example.uitests/cache/myList.bmp")
          driver.delayMs(3000)
          driver.pressHome()
          } catch (e: BusinessException) {
              AppLog.info("test_FfiFindComponent failed.")
          }   
      }
  }
  ```

## 3. 已实现接口

### 3.1 基础数据类型

- `Point(x: IntNative, y: IntNative)`
  - 功能：表示二维坐标点，常用于点击坐标、组件中心点、屏幕尺寸与密度返回值。
- `Rect(left: IntNative, top: IntNative, right: IntNative, bottom: IntNative)`
  - 功能：表示矩形区域，常用于组件边界、截图区域等位置定义。

### 3.2 UIComponent

- `UIComponent.click(): Unit`
  - 功能：点击当前组件。
- `UIComponent.doubleClick(): Unit`
  - 功能：双击当前组件。
- `UIComponent.longClick(): Unit`
  - 功能：长按当前组件。
- `UIComponent.getId(): String`
  - 功能：获取组件 `id`。
- `UIComponent.getText(): String`
  - 功能：获取组件文本。
- `UIComponent.getType(): String`
  - 功能：获取组件类型。
- `UIComponent.getDescription(): String`
  - 功能：获取组件无障碍描述。
- `UIComponent.dragTo(target: UIComponent): Unit`
  - 功能：拖拽当前组件到目标组件位置。
- `UIComponent.getSnapshot(path: String): Unit`
  - 功能：对组件截图并保存。
- `UIComponent.getBounds(): Rect`
  - 功能：获取组件边界矩形。
- `UIComponent.getBoundsCenter(): Point`
  - 功能：获取组件中心点坐标。
- `UIComponent.isClickable(): Bool`
  - 功能：判断组件是否可点击。
- `UIComponent.isLongClickable(): Bool`
  - 功能：判断组件是否可长按。
- `UIComponent.isScrollable(): Bool`
  - 功能：判断组件是否可滚动。
- `UIComponent.isEnabled(): Bool`
  - 功能：判断组件是否启用。
- `UIComponent.isFocused(): Bool`
  - 功能：判断组件是否聚焦。
- `UIComponent.isSelected(): Bool`
  - 功能：判断组件是否选中。
- `UIComponent.isChecked(): Bool`
  - 功能：判断组件是否勾选。
- `UIComponent.isCheckable(): Bool`
  - 功能：判断组件是否可勾选。
- `UIComponent.inputText(text: String): Unit`
  - 功能：向组件输入文本。
- `UIComponent.clearText(): Unit`
  - 功能：清空组件文本。
- `UIComponent.scrollToTop(speed!: Int64 = 600): Unit`
  - 功能：将组件内容滚动到顶部。
- `UIComponent.scrollToBottom(speed!: Int64 = 600): Unit`
  - 功能：将组件内容滚动到底部。
- `UIComponent.scrollSearch(on: On): ?UIComponent`
  - 功能：在可滚动组件内滚动搜索目标组件。
- `UIComponent.dragTo(target: UIComponent): Unit`
  - 功能：拖拽当前组件到目标组件位置。
- `UIComponent.pinchOut(scale: Float32): Unit`
  - 功能：执行放大手势。
- `UIComponent.pinchIn(scale: Float32): Unit`
  - 功能：执行缩小手势。

### 3.3 Driver

- `Driver.create(): Driver`
  - 功能：创建 Driver 实例，作为 UI 测试主入口。
- `Driver.drag(from: Point, to: Point, speed!: Int32 = 600): Unit`
  - 功能：执行基于起止点的拖拽手势。
- `Driver.delayMs(delayMs: Int32): Unit`
  - 功能：阻塞等待指定毫秒数。
- `Driver.findComponent(on: On): UIComponent`
  - 功能：按条件查找单个组件；找不到会抛异常。
- `Driver.findComponents(on: On): ?Array<UIComponent>`
  - 功能：按条件查找多个组件；无结果返回 `None`。
- `Driver.waitForComponent(on: On, time: Int32): ?UIComponent`
  - 功能：在超时时间内等待组件出现。
- `Driver.waitForIdle(idleTime: Int32, timeout: Int32): Bool`
  - 功能：判断当前界面的所有控件是否已经空闲。
- `Driver.assertComponentExist(on: On): Unit`
  - 功能：断言组件存在，不存在则抛异常。
- `Driver.pressBack(): Unit`
  - 功能：触发系统返回键。
- `Driver.pressHome(): Unit`
  - 功能：触发 Home 行为（回到主屏/后台）。
- `Driver.triggerKey(keyCode: Int32): Unit`
  - 功能：注入单个按键事件。
- `Driver.triggerCombineKeys(key0: Int32, key1: Int32, key2!: Option<Int32> = None): Unit`
  - 功能：注入组合按键事件。
- `Driver.click(x: Int32, y: Int32): Unit`
  - 功能：在屏幕坐标执行单击。
- `Driver.doubleClick(x: Int32, y: Int32): Unit`
  - 功能：在屏幕坐标执行双击。
- `Driver.longClick(x: Int32, y: Int32): Unit`
  - 功能：在屏幕坐标执行长按。
- `Driver.inputText(p: Point, text: String): Unit`
  - 功能：点击指定坐标并输入文本（追加输入）。
- `Driver.swipe(startx: Int32, starty: Int32, endx: Int32, endy: Int32, speed!: Int32 = 600): Unit`
  - 功能：执行滑动手势。
- `Driver.fling(fromP: Point, to: Point, stepLen: Int32, speed: Int32): Unit`
  - 功能：执行基于起止点的快速滑动。
- `Driver.fling(direction: UiDirection, speed: Int32): Unit`
  - 功能：执行按方向的快速滑动。
- `Driver.screenCap(savePath: String): Bool`
  - 功能：全屏截图并保存到指定路径。
- `Driver.screenCapture(savePath: String, rect!: Rect = Rect(0, 0, 0, 0)): Bool`
  - 功能：截图（支持矩形区域）。
- `Driver.setDisplayRotation(rotation: DisplayRotation): Unit`
  - 功能：设置屏幕旋转方向。
- `Driver.getDisplayRotation(): DisplayRotation`
  - 功能：获取当前屏幕旋转方向。
- `Driver.setDisplayRotationEnabled(enabled: Bool): Unit`
  - 功能：开启/关闭自动旋转。
- `Driver.getDisplaySize(): Point`
  - 功能：获取屏幕尺寸。
- `Driver.getDisplayDensity(): Point`
  - 功能：获取屏幕密度相关信息。
- `Driver.injectMultiPointerAction(pointers: PointerMatrix, speed!: Int32 = 600): Bool`
  - 功能：注入多指触控动作矩阵。

### 3.4 On（组件匹配条件）

- `On.init()`
  - 功能：创建查询条件对象。
- `On.text(txt: String, pattern!: MatchPattern = MatchPattern.EQUALS): On`
  - 功能：按文本匹配组件。
- `On.id(id: String): On`
  - 功能：按组件 `id` 匹配。
- `On.onType(tp: String): On`
  - 功能：按组件类型匹配。
- `On.clickable(b!: Bool = true): On`
  - 功能：按是否可点击匹配。
- `On.longClickable(b!: Bool = true): On`
  - 功能：按是否可长按匹配。
- `On.scrollable(b!: Bool = true): On`
  - 功能：按是否可滚动匹配。
- `On.enabled(b!: Bool = true): On`
  - 功能：按是否启用匹配。
- `On.focused(b!: Bool = true): On`
  - 功能：按是否聚焦匹配。
- `On.selected(b!: Bool = true): On`
  - 功能：按是否选中匹配。
- `On.checked(b!: Bool = true): On`
  - 功能：按是否勾选匹配。
- `On.checkable(b!: Bool = true): On`
  - 功能：按是否可勾选匹配。
- `On.isBefore(on: On): On`
  - 功能：按“位于某组件之前”的相对关系匹配。
- `On.isAfter(on: On): On`
  - 功能：按“位于某组件之后”的相对关系匹配。
- `On.within(on: On): On`
  - 功能：按“位于某组件内部”的相对关系匹配。
- `On.description(val: String, pattern!: ?MatchPattern = None): On`
  - 功能：按无障碍描述匹配。

### 3.5 PointerMatrix

- `PointerMatrix.create(fingers: Int32, steps: Int32): PointerMatrix`
  - 功能：创建多指动作矩阵。
- `PointerMatrix.setPoint(finger: Int32, step: Int32, point: Point): Unit`
  - 功能：设置指定手指在指定步骤的坐标点。