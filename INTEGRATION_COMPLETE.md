# Web3 开屏广告页集成完成

## ✅ 已完成的改动

### 1. 创建独立模块（零冲突）
```
submodules/TelegramCustom/          # 新增独立模块
├── BUILD                            # Bazel 配置
├── README.md                        # 使用文档
├── Sources/
│   ├── Core/                        # 工具类
│   │   ├── Utils/
│   │   │   ├── ColorPalette.swift          # 统一色板
│   │   │   └── LocalizationManager.swift   # 多语言管理
│   │   └── Constants/
│   │       ├── AppConstants.swift
│   │       └── LayoutConstants.swift
│   └── Features/
│       └── SplashScreen/
│           ├── Views/SplashScreenView.swift      # 开屏页视图
│           └── ViewModels/SplashViewModel.swift  # 倒计时逻辑
└── Resources/
    └── Localizations/              # 中英日韩 4 语言
        ├── en.lproj/Localizable.strings
        ├── zh-Hans.lproj/
        ├── ja.lproj/
        └── ko.lproj/
```

### 2. 修改的文件（3 个文件，条件编译包裹）

#### ① `Telegram/BUILD`
- 添加 `enableWeb3Splash` flag 定义
- 在主 target 的 frameworks 里条件添加 TelegramCustom

#### ② `submodules/TelegramUI/BUILD`
- copts 添加 `-DENABLE_WEB3_SPLASH` 编译标志（条件）
- deps 添加 TelegramCustom 依赖（条件）

#### ③ `submodules/TelegramUI/Sources/AppDelegate.swift`
- import 区域添加条件导入（5 行）
- 类属性添加 `splashWindow`（3 行）
- `didFinishLaunchingWithOptions` 末尾添加开屏逻辑（28 行）

---

## 🚀 如何使用

### 启用开屏页（构建时）

```bash
# 方式 1：命令行 flag
bazel build //Telegram:Telegram --//Telegram:enableWeb3Splash=true

# 方式 2：在 .bazelrc 永久启用（推荐）
echo "build --//Telegram:enableWeb3Splash=true" >> .bazelrc
bazel build //Telegram:Telegram
```

### 禁用开屏页（upstream 兼容模式）

```bash
# 默认不加 flag，完全兼容 upstream
bazel build //Telegram:Telegram
```

---

## 🎨 功能特性

| 功能 | 实现 |
|------|------|
| **1:1 还原设计** | 荧光绿品牌色 + 发光效果 + 黑色背景 |
| **多语言** | 中英日韩 4 语言，自动跟随系统 |
| **倒计时** | 3 秒自动跳转，右上角「跳过」按钮 |
| **零依赖** | 纯 SwiftUI 原生，无第三方库 |
| **模块化** | 完全独立，不影响 upstream |

---

## 🔄 与 Upstream 同步

```bash
# 拉取官方更新
git fetch upstream
git merge upstream/master

# 只有 3 个文件可能有冲突（都是条件编译包裹）
# - Telegram/BUILD（添加了 flag 定义）
# - submodules/TelegramUI/BUILD（copts + deps）
# - submodules/TelegramUI/Sources/AppDelegate.swift（3 处条件编译）

# 冲突解决：保留 #if ENABLE_WEB3_SPLASH 包裹的代码即可
```

---

## 📝 技术细节

### 开屏页显示流程

1. App 启动 → `AppDelegate.didFinishLaunchingWithOptions`
2. 创建主窗口（原有逻辑）
3. **条件编译**：如果启用 Web3 Splash，在主窗口上层显示开屏页
4. 3 秒倒计时 → 移除开屏窗口 → 显示主窗口
5. 继续原有启动流程（登录/主界面）

### 条件编译工作原理

```swift
#if ENABLE_WEB3_SPLASH
// 只在启用 flag 时编译这段代码
import TelegramCustom
// ...
#endif
```

当不加 `--//Telegram:enableWeb3Splash=true` 时：
- 这些代码不会被编译
- 不依赖 TelegramCustom 模块
- 完全兼容 upstream

---

## ➕ 后续扩展

### 添加新功能模块（如 Web3 钱包）

```bash
# 1. 创建目录
mkdir -p submodules/TelegramCustom/Sources/Features/Web3Wallet/{Views,ViewModels}

# 2. 创建视图
cat > submodules/TelegramCustom/Sources/Features/Web3Wallet/Views/WalletView.swift << 'EOF'
import SwiftUI

public struct WalletView: View {
    public var body: some View {
        ZStack {
            ColorPalette.backgroundDark.ignoresSafeArea()
            Text("wallet.title".localized)
        }
    }
}
EOF

# 3. 添加多语言
echo '"wallet.title" = "My Wallet";' >> submodules/TelegramCustom/Resources/Localizations/en.lproj/Localizable.strings

# 4. 在 BUILD 添加模块（无需修改 upstream 文件）
```

### 修改颜色/布局

所有设计参数都在工具类里，统一修改：
- **颜色**：`submodules/TelegramCustom/Sources/Core/Utils/ColorPalette.swift`
- **布局**：`submodules/TelegramCustom/Sources/Core/Constants/LayoutConstants.swift`
- **文案**：`submodules/TelegramCustom/Resources/Localizations/*/Localizable.strings`

---

## ⚠️ 注意事项

1. **首次构建需要启用 flag**：
   ```bash
   bazel build //Telegram:Telegram --//Telegram:enableWeb3Splash=true
   ```

2. **清理缓存**（如果修改了 .strings 文件但没生效）：
   ```bash
   bazel clean
   ```

3. **Xcode 26.2 + VPN TUN 模式**（模拟器网络问题已解决方案）：
   - 开启 mihomo/Clash 的 TUN 模式（增强模式）
   - 这样模拟器里的 app 也能走 VPN

4. **构建完成后测试**：
   - 启动 app → 看到荧光绿开屏页 → 3 秒倒计时 → 跳转主界面
   - 如果没看到开屏页，检查 `--//Telegram:enableWeb3Splash=true` flag 是否启用

---

## 📊 改动统计

| 项目 | 数量 |
|------|------|
| 新增文件 | 12 个（TelegramCustom 模块） |
| 修改文件 | 3 个（条件编译） |
| Swift 代码 | 6 个文件 |
| 多语言文件 | 4 个（中英日韩） |
| upstream 冲突风险 | 极低（条件编译隔离） |

---

**作者**: Jade
**完成日期**: 2026-09-21
**状态**: ✅ 已完成，可构建测试
