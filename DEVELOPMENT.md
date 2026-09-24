# Telegram iOS 二开开发指南

> 本文档整合了 Telegram iOS 源码二开的完整工作流、TelegramCustom 模块说明、编译调试技巧，以及实践中总结的开发规范与注意事项。

---

## 📋 目录

1. [快速开始](#快速开始)
2. [仓库结构与工作流](#仓库结构与工作流)
3. [TelegramCustom 模块说明](#telegramcustom-模块说明)
4. [编译与调试](#编译与调试)
5. [开发规范与注意事项](#开发规范与注意事项)
6. [常见问题](#常见问题)

---

## 快速开始

### 前置要求

- macOS with Xcode (版本见 `versions.json`，当前 Xcode 16.2)
- Python 3
- Apple Developer Account (可选，仅真机/发布需要)

### 一次性初始化

首次 clone 你的 fork 后：

```bash
# 1. Clone 仓库（包含子模块）
git clone --recursive -j8 https://github.com/你的用户名/Telegram-iOS.git
cd Telegram-iOS

# 2. 修复子模块 URL（fork 特有问题）
git config submodule.submodules/rlottie/rlottie.url https://github.com/TelegramMessenger/rlottie.git
git config submodule.submodules/TgVoipWebrtc/tgcalls.url https://github.com/TelegramMessenger/tgcalls.git
git submodule update --init --recursive

# 3. 配置 API credentials
# 在 https://my.telegram.org 申请 api_id 和 api_hash
# 复制 build-system/template_minimal_development_configuration.json 到 build-system/bchat-configuration.json
# 填入你的 api_id、api_hash、bundle_id、team_id

# 4. 生成 Xcode 工程并打开
./dev/open-xcode.sh

# 5. 生成假 provisioning profile（让 Xcode 调试可用）
./dev/setup-fake-profile.sh

# 6. 首次运行模拟器
./dev/run-simulator.sh
```

---

## 仓库结构与工作流

### Fork 关系

```
官方 TelegramMessenger/Telegram-iOS ──(upstream)──► 你的 fork
                                                    └─ (origin) 本地开发
```

- `origin`: 你自己的 GitHub fork（可随意 push）
- `upstream`: 官方仓库（只读，仅 fetch + merge）

### 二开工作流（单人简化版）

**核心原则**: 直接在 `master` 分支开发，不创建 feature 分支。

#### 1. 日常开发

```bash
# 修改代码...
git add -A
git commit -m "描述你的改动"
git push origin master
```

#### 2. 同步官方更新（定期执行）

```bash
./dev/sync-upstream.sh --push
```

内部流程：`fetch upstream` → `merge upstream/master` → 同步子模块 → 推送到 fork

**关于冲突**：
- 你改的地方 ≠ 官方改的地方 → 自动合并（99%情况）
- 你和官方改了同一处 → Git 提示冲突，手动解决

#### 3. 编译运行

```bash
# 完整编译 + 安装 + 启动模拟器
./dev/run-simulator.sh

# 跳过编译，直接用上次产物
./dev/run-simulator.sh --no-build
```

---

## TelegramCustom 模块说明

### 目录结构

```
submodules/TelegramCustom/
├── BUILD                                   # Bazel 构建配置
├── Sources/
│   ├── Core/                              # 核心工具类（全局共享）
│   │   ├── Utils/
│   │   │   ├── ColorPalette.swift        # 统一色板
│   │   │   └── LocalizationManager.swift # 多语言管理
│   │   ├── Constants/
│   │   │   ├── AppConstants.swift        # 应用常量
│   │   │   └── LayoutConstants.swift     # 布局常量
│   │   └── Components/                    # 全局通用组件
│   │       ├── Badges/                    # 徽章组件
│   │       └── Backgrounds/               # 背景效果组件
│   │
│   └── Features/                          # 功能模块（按业务划分）
│       ├── SplashScreen/                  # A01 开屏广告页
│       │   ├── Views/
│       │   │   ├── SplashScreenView.swift
│       │   │   └── SplashLogoSectionView.swift
│       │   └── ViewModels/
│       │       └── SplashViewModel.swift
│       │
│       └── LoginScreen/                   # A02 登录页
│           ├── ViewModels/
│           │   └── LoginViewModel.swift
│           └── Views/
│               ├── LoginScreenView.swift
│               └── Components/
│                   ├── LogoView.swift
│                   ├── TitleSectionView.swift
│                   ├── TelegramLoginButton.swift
│                   ├── QuickAccessButton.swift
│                   └── LegalTextView.swift
│
└── Resources/
    └── Localizations/                     # 多语言文件
        ├── zh-Hans.lproj/Localizable.strings
        ├── en.lproj/Localizable.strings
        ├── ja.lproj/Localizable.strings
        └── ko.lproj/Localizable.strings
```

### 已实现功能

#### 1. 开屏广告页（SplashScreen）

- ✅ 1:1 还原 HTML 原型设计
- ✅ 荧光绿品牌色 + 发光效果
- ✅ 3 秒倒计时自动跳转
- ✅ 支持中英日韩 4 种语言
- ✅ 纯 SwiftUI 原生实现（零第三方依赖）

#### 2. 登录页（LoginScreen）

- **位置**: 闪屏后、Telegram 原生登录前
- **组件**:
  - `LoginViewModel`: 登录页视图模型
  - `LogoView`: Logo 容器（80×80pt，荧光绿发光）
  - `TitleSectionView`: 标题与副标题区域
  - `TelegramLoginButton`: Telegram 蓝色登录按钮
  - `QuickAccessButton`: 一键免密按钮（边框样式）
  - `LegalTextView`: 法律条款文案
  - `LoginScreenView`: 主容器视图
- **编译标志**: 需要 `--//Telegram:enableWeb3Splash`

#### 3. 核心工具

**统一色板（ColorPalette）**
```swift
ColorPalette.brandNeon        // 荧光绿 #CFFF55
ColorPalette.textPrimary      // 主文本（白色）
ColorPalette.textSecondary    // 次要文本（60% 透明度）
```

**多语言管理（LocalizationManager）**
```swift
"splash.slogan.main".localized               // 简单本地化
"splash.skip.format".localized(with: 3)      // 带参数
```

**布局常量（LayoutConstants）**
```swift
LayoutConstants.spacingMD          // 16pt
LayoutConstants.cornerRadiusLG     // 16pt
LayoutConstants.buttonHeightMD     // 44pt
```

### 集成到主 App

在 `submodules/TelegramUI/Sources/AppDelegate.swift` 中：

```swift
#if ENABLE_WEB3_SPLASH
import TelegramCustom
import SwiftUI
#endif

// 在 application(_:didFinishLaunchingWithOptions:) 中
#if ENABLE_WEB3_SPLASH
if #available(iOS 14.0, *) {
    DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }

        let splashView = SplashScreenView { [weak self] in
            DispatchQueue.main.async {
                self?.showLoginScreen()
            }
        }

        let splashController = UIHostingController(rootView: splashView)
        let splashWindow = UIWindow(frame: UIScreen.main.bounds)
        splashWindow.windowLevel = .alert + 1
        splashWindow.rootViewController = splashController
        splashWindow.makeKeyAndVisible()
        self.splashWindow = splashWindow
    }
}
#endif
```

### 添加新功能模块

```bash
# 示例：添加 Web3 钱包模块
mkdir -p submodules/TelegramCustom/Sources/Features/Web3Wallet/{Views,ViewModels,Services}

# 在 submodules/TelegramCustom/BUILD 添加
swift_library(
    name = "Web3WalletModule",
    srcs = glob(["Sources/Features/Web3Wallet/**/*.swift"]),
    module_name = "Web3Wallet",
    deps = [":TelegramCustomCore"],
    visibility = ["//visibility:public"],
)

# 在 TelegramCustom 统一导出中添加依赖
swift_library(
    name = "TelegramCustom",
    deps = [
        # ...existing deps...
        ":Web3WalletModule",
    ],
)
```

---

## 编译与调试

### 工具脚本

| 脚本 | 作用 |
|------|------|
| `dev/run-simulator.sh` | 编译 debug_sim_arm64（免签名）+ 安装到模拟器 + 启动 |
| `dev/sync-upstream.sh` | 从官方 upstream fetch + merge + 同步子模块，可选推送 |
| `dev/setup-fake-profile.sh` | 生成假 provisioning profile，让 Xcode ⌘R + 断点调试可用 |
| `dev/open-xcode.sh` | 打开生成的 Xcode 工程（在 `Telegram_xcodeproj/` 目录） |
| `dev/debug-simulator.sh` | 在已启动的模拟器中调试应用（附加调试器） |

### 为什么模拟器要禁用 extensions

官方 `Make.py build` 会构建 Widget/Share/NotificationService 等扩展，需要签名。二开通过以下标志绕过：

- `--//Telegram:disableExtensions` - 不构建扩展
- `--//Telegram:disableProvisioningProfiles` - 模拟器免签名
- `--//Telegram:enableWeb3Splash` - 启用自定义模块

这些标志已内置在 `dev/run-simulator.sh` 中。

### Xcode 调试

命令行编译是免签名的，但 **Xcode ⌘R** 会同时分析真机和模拟器 target，真机 target 要求 provisioning profile。

**解决方案**: 运行 `./dev/setup-fake-profile.sh` 生成假 profile 放进 Xcode。Bazel 只解析 plist 不验证签名，所以能通过分析阶段 → Xcode ⌘R + 断点调试都能用。

> ⚠️ 假 profile 不能用于真机安装/发布，仅用于模拟器调试。

---

## 开发规范与注意事项

### 1. 代码编译与缓存

#### ⚠️ Bazel 增量编译缓存问题

**现象**: 修改 SwiftUI 代码后重新编译，但模拟器中看到的界面没有变化。

**原因**: Bazel 的增量编译机制会缓存编译产物。某些情况下，即使源码改变，Bazel 可能认为不需要重新编译，导致使用旧的 `.o` 文件。

**解决方案**:

1. **强制触发重新编译** - 修改一个明显的属性（如背景颜色、文字内容）来"刺激"编译系统识别变化：
   ```swift
   // 临时改成明显的颜色测试
   Color.red  // 改完验证后再改回 ColorPalette.backgroundBlack
   ```

2. **清理缓存重新编译**（极端情况）:
   ```bash
   rm -rf ~/telegram-bazel-cache/*
   ./dev/run-simulator.sh
   ```

3. **验证编译时间戳**:
   ```bash
   ls -la bazel-bin/submodules/TelegramCustom/LoginScreenModule_objs/Sources/Features/LoginScreen/Views/LoginScreenView.swift.o
   ```
   检查时间戳是否更新。

**最佳实践**:
- 每次改 UI 后，先改一个明显的测试属性（颜色/文字）验证生效
- 确认生效后再恢复正确的值
- 避免连续多次只改 padding 等不明显的数值

### 2. 条件编译与 BUILD 配置

#### ⚠️ 条件编译标志必须在所有相关模块配置

**现象**: 代码中使用 `#if ENABLE_WEB3_SPLASH` 但功能未生效，改动的代码没有被编译。

**原因**: 条件编译需要在**两个地方**同时配置：
1. **编译宏定义** (`copts` 中添加 `-DENABLE_WEB3_SPLASH`)
2. **模块依赖** (添加 TelegramCustom 依赖)

**错误示例** - 只修改代码，不修改 BUILD：
```swift
// TabBarControllerNode.swift
#if ENABLE_WEB3_SPLASH
import TelegramCustom  // ← 编译时这段代码被跳过，因为宏未定义
#endif
```

**正确做法** - 必须同时修改 BUILD 文件：

```python
# submodules/TabBarUI/BUILD
swift_library(
    name = "TabBarUI",
    copts = [
        "-warnings-as-errors",
    ] + select({
        "//Telegram:enableWeb3SplashSetting": ["-DENABLE_WEB3_SPLASH"],  # ← 1. 定义编译宏
        "//conditions:default": [],
    }),
    deps = [
        "//submodules/Display",
        # ...其他依赖...
    ] + select({
        "//Telegram:enableWeb3SplashSetting": ["//submodules/TelegramCustom:TelegramCustom"],  # ← 2. 添加依赖
        "//conditions:default": [],
    }),
)
```

**检查清单**:
- [ ] 在使用条件编译的模块 BUILD 文件中添加 `copts` 编译宏
- [ ] 在使用条件编译的模块 BUILD 文件中添加 TelegramCustom 依赖
- [ ] 构建脚本中传递 `--//Telegram:enableWeb3Splash` flag
- [ ] 验证编译日志中该模块被重新编译（不是 action cache hit）

**验证方法**:
```bash
# 编译后检查模块是否重新编译
./dev/run-simulator.sh 2>&1 | grep "Compiling.*TabBarUI"
# 应该看到类似输出：
# [1,744 / 1,762] Compiling Swift module //submodules/TabBarUI:TabBarUI
```

### 3. 模块依赖与导出

#### ⚠️ Module 导出必须使用 @_exported

**问题**: 在 `TelegramCustom.swift` 中 `import LoginScreen` 但外部无法访问 `LoginScreenView`。

**原因**: Swift 模块默认不会自动导出子模块的公开符号。

**正确做法**:
```swift
// submodules/TelegramCustom/Sources/TelegramCustom.swift
@_exported import TelegramCustomCore
@_exported import SplashScreen
@_exported import LoginScreen  // ← 必须使用 @_exported
```

这样外部 `import TelegramCustom` 时才能直接访问 `LoginScreenView`。

#### ⚠️ BUILD 文件中的模块依赖

**结构**:
```python
# TelegramCustomCore - 核心工具（最底层，无依赖）
swift_library(
    name = "TelegramCustomCore",
    module_name = "TelegramCustomCore",
    srcs = glob(["Sources/Core/**/*.swift"]),
)

# LoginScreenModule - 功能模块（依赖 Core）
swift_library(
    name = "LoginScreenModule",
    module_name = "LoginScreen",
    srcs = glob(["Sources/Features/LoginScreen/**/*.swift"]),
    deps = [":TelegramCustomCore"],  # ← 依赖核心模块
)

# TelegramCustom - 统一导出（聚合所有模块）
swift_library(
    name = "TelegramCustom",
    module_name = "TelegramCustom",
    srcs = ["Sources/TelegramCustom.swift"],
    deps = [
        ":TelegramCustomCore",
        ":SplashScreenModule",
        ":LoginScreenModule",  # ← 包含所有子模块
    ],
)
```

**依赖规则**:
- 功能模块只依赖 `TelegramCustomCore`
- 统一导出模块 `TelegramCustom` 聚合所有子模块
- 外部只需 `import TelegramCustom` 即可访问所有功能

### 3. 条件编译与标志

#### ⚠️ 编译标志必须正确传递

**问题**: 代码中使用 `#if ENABLE_WEB3_SPLASH` 但功能未生效。

**原因**: Bazel 构建时未传递 `--//Telegram:enableWeb3Splash` 标志，导致条件编译块被排除。

**检查 BUILD 配置**:
```python
# Telegram/BUILD
bool_flag(
    name = "enableWeb3Splash",
    build_setting_default = False,  # 默认关闭
)

config_setting(
    name = "enableWeb3SplashSetting",
    flag_values = {
        ":enableWeb3Splash": "True",
    },
)
```

**检查构建脚本**:
```bash
# dev/run-simulator.sh 必须包含
bazel build Telegram/Telegram \
    --//Telegram:disableExtensions \
    --//Telegram:disableProvisioningProfiles \
    --//Telegram:enableWeb3Splash  # ← 必须显式启用
```

**使用条件依赖**:
```python
# TelegramUI/BUILD
swift_library(
    name = "TelegramUI",
    deps = [
        # ...other deps...
    ] + select({
        "//Telegram:enableWeb3SplashSetting": ["//submodules/TelegramCustom:TelegramCustom"],
        "//conditions:default": [],
    }),
)
```

### 4. 资源文件与本地化

#### ⚠️ Bundle 查找问题

**问题**: 本地化字符串显示为键名（如 "login.title"）而不是实际文本。

**原因**: `Bundle.main` 在模块化架构中可能找不到资源文件。

**正确做法**:
```swift
// LocalizationManager.swift
public enum LocalizationManager {
    private static var resourceBundle: Bundle = {
        // 使用当前模块的 bundle
        return Bundle(for: BundleToken.self)
    }()

    public static func string(forKey key: String, comment: String = "") -> String {
        return NSLocalizedString(key, tableName: "Localizable",
                                bundle: resourceBundle, comment: comment)
    }
}

// 标记类用于获取模块 bundle
private final class BundleToken {}
```

**BUILD 配置**:
```python
swift_library(
    name = "LoginScreenModule",
    srcs = glob(["Sources/Features/LoginScreen/**/*.swift"]),
    deps = [":TelegramCustomCore"],
    data = glob(["Resources/Localizations/**/*.strings"]),  # 包含资源文件
)
```

### 5. SwiftUI 布局与安全区域

#### ⚠️ 安全区域影响 padding 计算

**问题**: 修改 `.padding(.top, 120)` 但 Logo 位置没有变化。

**原因**: 如果父容器使用 `.ignoresSafeArea()`，所有内容从屏幕顶部（0,0）开始，padding 从状态栏上边缘计算。

**解决方案**:
```swift
// ❌ 错误：背景忽略安全区域，内容也跟着从顶部开始
ZStack {
    ColorPalette.backgroundBlack.ignoresSafeArea()
    VStack {
        // padding 从屏幕顶部（包括状态栏）开始计算
    }
    .padding(.top, 60)  // 实际上 Logo 会被状态栏遮挡
}

// ✅ 正确：只让背景忽略安全区域，内容尊重安全区域
ZStack {
    ColorPalette.backgroundBlack.ignoresSafeArea()  // 背景铺满
    VStack {
        // padding 从安全区域顶部（状态栏下方）开始计算
    }
    .padding(.top, 60)  // 60pt 是从状态栏下方算起
}
```

**最佳实践**:
- 背景色/图片使用 `.ignoresSafeArea()` 铺满屏幕
- 内容容器不要使用 `.ignoresSafeArea()`，让系统自动处理安全区域
- 这样 padding 值才符合直觉（从状态栏/导航栏下方开始）

### 6. Git 提交规范

#### 提交消息格式

```
<type>(<scope>): <subject>

<body>
```

**Type 类型**:
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `build`: 构建系统或外部依赖
- `chore`: 其他杂项

**Scope 范围**:
- `splash`: 开屏页
- `login`: 登录页
- `i18n`: 国际化
- `ui`: UI 组件
- `build`: 构建配置
- `app`: 应用集成

**示例**:
```bash
feat(login): add LoginScreenView main container
fix(i18n): use module bundle for localization resources
fix(ui): respect safe area for proper logo positioning
docs: update development guide with cache issues
```

#### 避免提交调试代码

- ❌ 不要提交 `print()` 调试日志
- ❌ 不要提交测试用的临时颜色/文字
- ❌ 不要提交注释掉的代码块

**工作流**:
1. 开发时随意添加调试代码
2. 功能完成后清理所有调试代码
3. 确认后再 commit

### 7. 源码改动标记规范（重要）

#### ⚠️ 核心原则：最小化对 Upstream 源码的修改

本项目基于 Telegram 官方源码，需要定期同步 upstream 更新。为了减少合并冲突，遵循以下原则：

**1. 优先使用独立模块**

- ✅ **推荐**: 所有自定义功能放在 `submodules/TelegramCustom/` 中
- ✅ 这个目录是我们自己创建的，upstream 永远不会有冲突
- ✅ **TelegramCustom 目录内的文件不需要 CUSTOM 标记**（因为整个目录都是自定义的）
- ❌ **避免**: 直接修改 `submodules/TelegramUI/` 等官方模块的大量文件

**2. 必须修改 Telegram 官方源码时，使用明确标记**

**何时需要 CUSTOM 标记：**
- 修改 `submodules/TelegramUI/`、`submodules/TelegramCore/`、`submodules/TabBarUI/` 等 **Telegram 官方模块**
- 修改 `Telegram/BUILD`、主 `BUILD` 文件等配置文件
- 修改 `AppDelegate.swift` 等入口文件

**何时不需要 CUSTOM 标记：**
- `submodules/TelegramCustom/` 目录下的所有文件（整个目录都是自定义的）
- `docs/`、`dev/` 等我们自己创建的目录
- 新增的配置文件（如 `build-system/bchat-configuration.json`）

当必须修改官方源码文件（如 `AppDelegate.swift`、`TabBarControllerNode.swift`）时，使用标准标记：

```swift
// ==================== CUSTOM START ====================
// 描述：集成 Web3 开屏页与登录页
// 文件：AppDelegate.swift
// 日期：2026-09-23
// 注意：同步 upstream 时保留此块
#if ENABLE_WEB3_SPLASH
import TelegramCustom
import SwiftUI
#endif

// ... 自定义代码 ...

// ==================== CUSTOM END ====================
```

**标记规范**:
- 使用 `// ==================== CUSTOM START ====================`
- 说明改动目的、文件名、日期
- 使用 `// ==================== CUSTOM END ====================` 结束
- 尽可能使用条件编译 `#if ENABLE_WEB3_SPLASH` 包裹
- 在标记中注明"同步 upstream 时保留此块"

**3. 最小化改动范围**

```swift
// ❌ 错误：大段修改，难以合并
func application(...) {
    // 500 行代码全部重写
}

// ✅ 正确：只在必要位置插入，使用条件编译
func application(...) {
    // 官方代码保持不变
    // ...

    // ==================== CUSTOM START ====================
    #if ENABLE_WEB3_SPLASH
    if #available(iOS 14.0, *) {
        DispatchQueue.main.async { [weak self] in
            self?.showSplashScreen()
        }
    }
    #endif
    // ==================== CUSTOM END ====================

    // 官方代码继续
    // ...
}
```

**4. 记录所有改动文件**

在 `INTEGRATION_COMPLETE.md` 中维护改动清单：

```markdown
## 改动的官方文件

| 文件 | 改动内容 | 行号 | 标记 |
|------|---------|------|------|
| `submodules/TelegramUI/Sources/AppDelegate.swift` | 添加 SplashScreen 集成 | 36-38, 1700-1760 | ✅ |
| `Telegram/BUILD` | 添加 enableWeb3Splash 标志 | 90-107 | ✅ |
```

**5. 解决冲突时的策略**

当 `git merge upstream/master` 产生冲突：

```bash
# 1. 查看冲突文件
git status

# 2. 对于标记清晰的文件，优先保留我们的改动
# 打开冲突文件，查找 CUSTOM START/END 标记
# 保留标记内的代码，其他部分采用 upstream 版本

# 3. 测试编译
./dev/run-simulator.sh

# 4. 提交合并
git add .
git commit -m "chore: merge upstream, preserve custom integrations"
```

**6. 定期检查改动**

每次同步 upstream 后：

```bash
# 查看所有包含 CUSTOM 标记的文件
grep -r "CUSTOM START" --include="*.swift" submodules/

# 确认标记完整性
grep -c "CUSTOM START" submodules/TelegramUI/Sources/AppDelegate.swift
grep -c "CUSTOM END" submodules/TelegramUI/Sources/AppDelegate.swift
# 两个数字应该相等
```

### 8. 文件组织规范

#### ⚠️ 文件必须放在正确的目录

**问题**: 文件被放在错误的位置（如 `TelegramCustomCore/Sources/Views/` 而不是 `TelegramCustom/Sources/Features/LoginScreen/Views/`）。

**影响**:
- BUILD 文件的 glob 匹配失败
- 模块依赖混乱
- 代码难以维护

**正确结构**:
```
TelegramCustom/
├── Sources/
│   ├── Core/                    # ← 只放核心工具类
│   │   ├── Utils/               # 工具：ColorPalette, LocalizationManager
│   │   ├── Constants/           # 常量：AppConstants, LayoutConstants
│   │   └── Components/          # 全局通用组件
│   │
│   └── Features/                # ← 业务功能模块
│       ├── SplashScreen/
│       │   ├── Views/
│       │   └── ViewModels/
│       └── LoginScreen/
│           ├── Views/
│           │   ├── LoginScreenView.swift      # 主视图
│           │   └── Components/                # 该页面专用组件
│           │       ├── LogoView.swift
│           │       └── TitleSectionView.swift
│           └── ViewModels/
│               └── LoginViewModel.swift
```

**原则**:
- 核心工具放 `Core/`
- 业务功能放 `Features/<FeatureName>/`
- 每个功能独立成模块，包含自己的 Views、ViewModels、Services
- 功能内的 Components 放在 `Features/<FeatureName>/Views/Components/`

### 9. 代码审查清单

提交前检查：

- [ ] 所有调试 `print()` 已删除
- [ ] 测试用的临时颜色/文字已恢复
- [ ] 文件在正确的目录结构中
- [ ] BUILD 文件包含新增的模块/文件
- [ ] 条件编译标志正确（`#if ENABLE_WEB3_SPLASH`）
- [ ] 模块导出使用 `@_exported`
- [ ] 本地化字符串键名统一（如 `login.title`）
- [ ] 布局尊重安全区域
- [ ] 提交消息符合规范
- [ ] **源码改动已添加 CUSTOM 标记**
- [ ] **改动已记录到 INTEGRATION_COMPLETE.md**

---

## 常见问题

### Q1: Xcode stuck at "build-request.json not updated yet"

**解决**: 取消当前构建，重新开始一次构建。

### Q2: "Telegram_xcodeproj: no such package" 错误

**原因**: 系统重启后自动生成的 Xcode 工程失效。

**解决**: 重新运行工程生成命令：
```bash
python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir "$HOME/telegram-bazel-cache" generateProject \
  --configurationPath build-system/bchat-configuration.json \
  --xcodeManagedCodesigning
```

### Q3: 子模块 404 错误

**原因**: Fork 后 `.gitmodules` 中的相对 URL 会指向你的 fork，但 `rlottie` 和 `tgcalls` 在你的 fork 中不存在。

**解决**:
```bash
git config submodule.submodules/rlottie/rlottie.url https://github.com/TelegramMessenger/rlottie.git
git config submodule.submodules/TgVoipWebrtc/tgcalls.url https://github.com/TelegramMessenger/tgcalls.git
git submodule update --init --recursive
```

### Q4: 模拟器看不到改动

参考 [开发规范 § 1. 代码编译与缓存](#1-代码编译与缓存)。

### Q5: 本地化字符串显示键名

参考 [开发规范 § 4. 资源文件与本地化](#4-资源文件与本地化)。

### Q6: Xcode ⌘R 报签名错误

**解决**: 运行 `./dev/setup-fake-profile.sh` 生成假 profile。

### Q7: 真机安装失败

模拟器免签名配置不支持真机。真机/发布需要：
1. Apple Developer Account（付费）
2. 真实的 provisioning profile
3. 使用 `Make.py build` 而不是 `run-simulator.sh`

---

## 依赖与许可

### TelegramCustom 模块依赖

- ✅ SwiftUI（iOS 13+，系统自带）
- ✅ Foundation（系统自带）
- ❌ 零第三方依赖

### 许可与发布要求

根据 Telegram 官方要求，开发者需要：

1. [获取自己的 api_id](https://core.telegram.org/api/obtaining_api_id)
2. **不要**使用 "Telegram" 名称（或明确标注为非官方）
3. **不要**使用官方 Logo（蓝色圆圈中的白色纸飞机）
4. 遵守[安全指南](https://core.telegram.org/mtproto/security_guidelines)，保护用户数据和隐私
5. **必须**开源你的代码以遵守许可证

---

## 后续扩展建议

1. **Web3 钱包**: `Sources/Features/Web3Wallet/`
2. **NFT 画廊**: `Sources/Features/NFTGallery/`
3. **通用组件库**: `Sources/Core/Components/`
4. **自定义动画**: `Sources/Core/Modifiers/`

---

**最后更新**: 2026-09-23
