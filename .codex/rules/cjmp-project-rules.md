---
description: CJMP 应用工程创建及代码目录结构
alwaysApply: true
enabled: true
updatedAt: 2026-03-05T10:56:01.235Z
provider: 
---

# 应用工程结构介绍

## 生成代码目录结构说明
任何功能目录仅允许在cjmp工程的lib目录下建立一级目录,即在项目根目录中存在二级目录,如:在telegram_cjmp/lib目录下建立network目录,存放相关功能,但是和network相关功能不允许在network下再建立子包, 必须在同级的lib/network目录下新建目录放置代码文件。
- 正确示例：
```cangjie
.
├── lib
│   └── network
│   │   └── tcp.cj
│   │   └── connection.cj
│   └── udp
│   │   └── udp.cj
│   │   └── connection.cj
│   ├── ability_mainability_entry.cj
│   ├── ability_stage.cj
│   ├── cjpm.toml
│   ├── index.cj
│   ├── main_ability.cj
│   └── module_entry_entry.cj
```
- 错误示例
```cangjie
.
├── lib
│   └── network
│   │   ├── tcp.cj
│   │   ├── connection.cj
│   │   ├── udp
│   │   │   ├── udp.cj
│   │   │   ├── connection.cj
│   ├── ability_mainability_entry.cj
│   ├── ability_stage.cj
│   ├── cjpm.toml
│   ├── index.cj
│   ├── main_ability.cj
│   └── module_entry_entry.cj
```

## CJMP 工程构建运行
### 构建 CJMP 工程

首先运行
```bash
source $CANGJIE_IOS_HOME/envsetup.sh
```

#### 验证或构建 app 类型工程
同样可以
```cangjie
  keels build apk/ios/hap # 根据不同设备使用不同的命令，android设备对应apk，ios设备对应ios，harmonyos设备对应hap
```

### 运行 CJMP 工程
```cangjie
  keels run # 根据上一步构建的产物，运行对应的设备，不需要参数
```

### 编译cangjie源代码
通过本地 $CJMP_SDK_HOME/cjmp-tools-third_party 目录下的 cangjie-android/bin/cjc 或者 cangjie-ios/bin/cjc 编译 cangjie 源代码