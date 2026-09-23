# 自定义 Tab Bar 设计文档

> **创建日期**: 2026-09-23
> **功能范围**: 底部导航栏（Tab Bar）UI 定制
> **原型参考**: `web3_telegram_super_app_prototype (1).html`

---

## 一、需求概述

### 1.1 目标

实现完全自定义的底部 Tab Bar，样式与 HTML 原型保持一致（荧光绿品牌色 + 黑色背景），支持 4 个 Tab 切换。

### 1.2 Tab 配置

| Tab 名称 | 对应页面 | 图标（临时） | 说明 |
|---------|---------|------------|------|
| 聊天 | 现有聊天列表 (chats) | `message.fill` | 保留现有功能 |
| 联系人 | 现有联系人页 (contacts) | `person.crop.circle` | 保留现有功能 |
| 发现 | 占位页面（新增） | `safari` | 显示"即将推出" |
| 我的 | 现有设置页 (settings) | `person.fill` | 保留现有功能 |

### 1.3 设计原则

- **最小化对 Upstream 的修改** - 所有自定义代码放在 `TelegramCustom` 模块
- **条件编译隔离** - 使用 `#if ENABLE_WEB3_SPLASH` 包裹所有改动
- **保留现有逻辑** - 不修改页面切换、状态管理等核心逻辑
- **便于后续扩展** - 图标支持替换，占位页易于替换为实际功能

---

## 二、视觉设计规范

### 2.1 颜色配置

```swift
// 使用 TelegramCustomCore 中的 ColorPalette

// 选中状态
- 图标颜色: ColorPalette.brandNeon (#CFFF55)
- 文字颜色: ColorPalette.brandNeon (#CFFF55)
- 字体粗细: Bold

// 未选中状态
- 图标颜色: #A1A1A1 (60% 透明度白色)
- 文字颜色: ColorPalette.textSecondary (#999999)
- 字体粗细: Medium

// 背景
- Tab Bar 背景: ColorPalette.surface1 (#0A0A0A)
- 页面背景: ColorPalette.backgroundBlack (#000000)

// 徽章（红点）
- 背景色: #EF4444 (红色)
- 文字颜色: 白色
- 字体: Bold, 9pt
```

### 2.2 布局规范

```
Tab Bar 高度: 49pt (不含安全区域) + 底部安全区域

单个 Tab 项布局（垂直排列）:
┌─────────────┐
│   [图标]     │  ← 28×28pt，居中
│   ↓ 4pt     │
│  [文字]      │  ← 10pt 字体
└─────────────┘

图标尺寸: 28×28pt (SF Symbols large)
图标与文字间距: 4pt
文字字体: 10pt (选中 Bold / 未选中 Medium)

徽章位置: 图标右上角 (-4pt, -4pt)
徽章尺寸: 最小 16×16pt，根据数字宽度自适应
```

### 2.3 交互效果

- **点击反馈**: 0.15s 缩放动画 (0.95 → 1.0)
- **切换动画**: 0.3s spring 动画
- **选中状态**: 荧光绿色 + 图标/文字同时变色
- **徽章显示**: 数字 > 99 显示 "99+"

---

## 三、技术架构

### 3.1 模块结构

```
submodules/TelegramCustom/Sources/Features/CustomTabBar/
├── CustomTabBarComponent.swift          # 自定义 Tab Bar 组件
├── CustomTabBarItemView.swift           # 单个 Tab 项视图
├── DiscoverPlaceholderViewController.swift  # 发现页占位
└── BUILD                                # Bazel 构建配置
```

### 3.2 核心组件设计

#### CustomTabBarComponent

基于 ComponentFlow 框架实现，接口与 `TabBarComponent` 兼容。

```swift
public final class CustomTabBarComponent: Component {
    public struct Item: Equatable {
        let id: AnyHashable
        let title: String
        let icon: UIImage           // SF Symbol 图标
        let selectedIcon: UIImage   // 选中态图标（同一个，只改颜色）
        let badge: String?          // 徽章文字
        let action: (Bool) -> Void  // 点击回调（参数：是否长按）
        let doubleTapAction: (() -> Void)?
        let contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?
    }

    public let theme: PresentationTheme
    public let strings: PresentationStrings
    public let items: [Item]
    public let selectedId: AnyHashable?
    public let outerInsets: UIEdgeInsets

    public init(
        theme: PresentationTheme,
        strings: PresentationStrings,
        items: [Item],
        selectedId: AnyHashable?,
        outerInsets: UIEdgeInsets
    )
}
```

#### CustomTabBarItemView

单个 Tab 项的 UI 实现。

```swift
final class CustomTabBarItemView: UIView {
    private let iconImageView: UIImageView
    private let titleLabel: UILabel
    private let badgeView: BadgeView

    var isSelected: Bool { didSet { updateAppearance() } }

    func configure(
        title: String,
        icon: UIImage,
        badge: String?,
        isSelected: Bool
    )

    private func updateAppearance() {
        if isSelected {
            iconImageView.tintColor = ColorPalette.brandNeon
            titleLabel.textColor = ColorPalette.brandNeon
            titleLabel.font = .systemFont(ofSize: 10, weight: .bold)
        } else {
            iconImageView.tintColor = UIColor.white.withAlphaComponent(0.6)
            titleLabel.textColor = ColorPalette.textSecondary
            titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        }
    }
}
```

### 3.3 集成方式

#### 修改 TabBarControllerNode

在 `submodules/TabBarUI/Sources/TabBarControllerNode.swift` 中添加条件编译：

```swift
// ==================== CUSTOM START ====================
// 描述：集成自定义 Tab Bar 组件
// 文件：TabBarControllerNode.swift
// 日期：2026-09-23
#if ENABLE_WEB3_SPLASH
import TelegramCustom
#endif
// ==================== CUSTOM END ====================

private func updateImpl(params: Params, transition: ComponentTransition) -> CGFloat {
    // ...现有代码...

    // ==================== CUSTOM START ====================
    #if ENABLE_WEB3_SPLASH
    let tabBarSize = self.tabBarView.update(
        transition: tabBarTransition,
        component: AnyComponent(CustomTabBarComponent(
            theme: self.theme,
            strings: self.strings,
            items: self.tabBarItems.map { item in
                // 转换为 CustomTabBarComponent.Item
            },
            selectedId: selectedId,
            outerInsets: UIEdgeInsets(top: 0.0, left: sideInset, bottom: tabBarBottomInset, right: sideInset)
        )),
        environment: {},
        containerSize: CGSize(width: params.layout.size.width - sideInset * 2.0, height: 100.0)
    )
    #else
    // 原有 TabBarComponent 逻辑
    let tabBarSize = self.tabBarView.update(
        transition: tabBarTransition,
        component: AnyComponent(TabBarComponent(
            // ...现有参数...
        )),
        environment: {},
        containerSize: CGSize(width: params.layout.size.width - sideInset * 2.0, height: 100.0)
    )
    #endif
    // ==================== CUSTOM END ====================
}
```

### 3.4 图标资源管理

#### 临时方案（SF Symbols）

```swift
enum CustomTabBarIcon {
    case chat
    case contacts
    case discover
    case mine

    var systemName: String {
        switch self {
        case .chat: return "message.fill"
        case .contacts: return "person.crop.circle"
        case .discover: return "safari"
        case .mine: return "person.fill"
        }
    }

    var image: UIImage {
        return UIImage(systemName: systemName)!
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .regular))
    }
}
```

#### 后续切图替换方案

1. 准备资源文件（PDF 矢量图）：
   ```
   submodules/TelegramCustom/Resources/Assets/TabBarIcons.xcassets/
   ├── tab_chat.imageset/
   │   └── tab_chat.pdf
   ├── tab_contacts.imageset/
   │   └── tab_contacts.pdf
   ├── tab_discover.imageset/
   │   └── tab_discover.pdf
   └── tab_mine.imageset/
       └── tab_mine.pdf
   ```

2. 修改加载逻辑：
   ```swift
   var image: UIImage {
       // 优先使用自定义图标
       if let customIcon = UIImage(named: "tab_\(rawValue)", in: Bundle(for: BundleToken.self), compatibleWith: nil) {
           return customIcon
       }
       // 降级到 SF Symbols
       return UIImage(systemName: systemName)!
   }
   ```

---

## 四、发现页占位实现

### 4.1 DiscoverPlaceholderViewController

```swift
// submodules/TelegramCustom/Sources/Features/DiscoverPlaceholder/

import UIKit
import Display

public final class DiscoverPlaceholderViewController: ViewController {
    private let placeholderView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override public func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNode.backgroundColor = ColorPalette.backgroundBlack

        setupUI()
    }

    private func setupUI() {
        // 居中显示
        // 图标：safari 指南针，荧光绿色，64×64pt
        // 标题："发现"，白色，24pt Bold
        // 副标题："即将推出"，灰色，14pt Regular
    }
}
```

### 4.2 集成到 TabBarController

在设置 Tab Bar controllers 时，插入占位页：

```swift
// AppDelegate.swift 或其他初始化位置

#if ENABLE_WEB3_SPLASH
let discoverController = DiscoverPlaceholderViewController()
discoverController.tabBarItem.title = strings.Discover_Title  // "发现"
#endif

let controllers = [
    chatListController,
    contactsController,
    #if ENABLE_WEB3_SPLASH
    discoverController,
    #endif
    settingsController
]

tabBarController.setControllers(controllers, selectedIndex: 0)
```

---

## 五、国际化支持

### 5.1 多语言字符串

```swift
// submodules/TelegramCustom/Resources/Localizations/zh-Hans.lproj/Localizable.strings
"tabbar.chat.title" = "聊天";
"tabbar.contacts.title" = "联系人";
"tabbar.discover.title" = "发现";
"tabbar.mine.title" = "我的";
"discover.placeholder.title" = "发现";
"discover.placeholder.subtitle" = "即将推出";

// en.lproj/Localizable.strings
"tabbar.chat.title" = "Chats";
"tabbar.contacts.title" = "Contacts";
"tabbar.discover.title" = "Discover";
"tabbar.mine.title" = "Me";
"discover.placeholder.title" = "Discover";
"discover.placeholder.subtitle" = "Coming Soon";
```

### 5.2 使用方式

```swift
titleLabel.text = "tabbar.chat.title".localized
```

---

## 六、BUILD 配置

### 6.1 TelegramCustom/BUILD

```python
# ==================== CUSTOM START ====================
# 描述：添加 CustomTabBar 模块
# 文件：TelegramCustom/BUILD
# 日期：2026-09-23

swift_library(
    name = "CustomTabBarModule",
    module_name = "CustomTabBar",
    srcs = glob([
        "Sources/Features/CustomTabBar/**/*.swift",
        "Sources/Features/DiscoverPlaceholder/**/*.swift",
    ]),
    deps = [
        ":TelegramCustomCore",
        "//submodules/Display:Display",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
    data = glob(["Resources/Assets/TabBarIcons.xcassets/**/*"]),
    visibility = ["//visibility:public"],
)

# 在 TelegramCustom 统一导出中添加依赖
swift_library(
    name = "TelegramCustom",
    module_name = "TelegramCustom",
    srcs = ["Sources/TelegramCustom.swift"],
    deps = [
        ":TelegramCustomCore",
        ":SplashScreenModule",
        ":LoginScreenModule",
        ":CustomTabBarModule",  # ← 新增
    ],
    visibility = ["//visibility:public"],
)
# ==================== CUSTOM END ====================
```

### 6.2 TelegramCustom.swift 导出

```swift
// submodules/TelegramCustom/Sources/TelegramCustom.swift

@_exported import TelegramCustomCore
@_exported import SplashScreen
@_exported import LoginScreen
@_exported import CustomTabBar  // ← 新增
```

### 6.3 条件编译标志

已有配置（无需修改）：
- `Telegram/BUILD` 中已定义 `enableWeb3Splash` flag
- `build-system/bchat-configuration.json` 中已配置

---

## 七、实现步骤

### Phase 1: 基础组件（2-3 小时）

1. 创建 `CustomTabBarComponent.swift`
   - 定义 Item 数据结构
   - 实现 Component 协议
   - 处理布局逻辑

2. 创建 `CustomTabBarItemView.swift`
   - 实现图标 + 文字布局
   - 实现选中/未选中状态切换
   - 实现徽章显示

3. 创建 `DiscoverPlaceholderViewController.swift`
   - 简单的居中提示页面

### Phase 2: 集成到 TabBarControllerNode（1-2 小时）

1. 修改 `TabBarControllerNode.swift`
   - 添加条件编译导入
   - 在 `updateImpl` 中切换组件
   - 添加 CUSTOM 标记

2. 修改 controllers 初始化
   - 插入 DiscoverPlaceholderViewController
   - 配置 tabBarItem 属性

### Phase 3: 多语言与资源（1 小时）

1. 添加多语言字符串
2. 配置 SF Symbols 图标
3. 预留自定义图标加载逻辑

### Phase 4: 测试与调试（1-2 小时）

1. 模拟器运行测试
2. 验证切换逻辑
3. 验证徽章显示
4. 验证多语言

---

## 八、测试检查清单

### 功能测试

- [ ] 4 个 Tab 都能正常点击切换
- [ ] 聊天 Tab 显示未读数徽章
- [ ] 选中态颜色正确（荧光绿 #CFFF55）
- [ ] 未选中态颜色正确（灰色）
- [ ] 发现页显示占位提示
- [ ] 切换到聊天/联系人/设置页面功能正常

### 视觉测试

- [ ] Tab Bar 高度正确（49pt + 安全区域）
- [ ] 图标尺寸正确（28×28pt）
- [ ] 文字大小正确（10pt）
- [ ] 间距正确（图标与文字间距 4pt）
- [ ] 背景色正确（#0A0A0A）
- [ ] 徽章位置和样式正确

### 兼容性测试

- [ ] 不加 `--//Telegram:enableWeb3Splash` 时使用原有 Tab Bar
- [ ] 加 `--//Telegram:enableWeb3Splash` 时使用自定义 Tab Bar
- [ ] 多语言切换正常（中文/英文）
- [ ] iPhone SE / iPhone 15 Pro Max 适配正常
- [ ] 横屏模式显示正常（iPad）

### 代码质量

- [ ] 所有修改都有 CUSTOM 标记
- [ ] 条件编译语句完整
- [ ] 没有调试 print 语句
- [ ] 符合项目代码规范

---

## 九、后续扩展

### 9.1 切图替换

等设计师提供切图后：
1. 准备 PDF 矢量图或 @1x/@2x/@3x PNG
2. 放入 `Resources/Assets/TabBarIcons.xcassets/`
3. 修改图标加载逻辑（见 3.4 节）
4. 删除 SF Symbols 降级代码

### 9.2 发现页功能开发

替换 `DiscoverPlaceholderViewController` 为实际功能页面：
1. 创建新的 `DiscoverViewController`
2. 在 controllers 初始化时替换
3. 删除占位页代码

### 9.3 高级交互

- 长按 Tab 显示快捷操作菜单
- 双击 Tab 回到顶部
- 滑动切换 Tab（可选）
- Tab Bar 隐藏/显示动画

---

## 十、风险与注意事项

### 10.1 潜在风险

1. **Bazel 增量编译缓存问题**
   - 现象：修改 UI 代码后重新编译，但样式没变化
   - 解决：修改明显属性测试（如临时改成红色）
   - 极端情况：清理缓存 `rm -rf ~/telegram-bazel-cache/*`

2. **条件编译遗漏**
   - 确保所有自定义代码都在 `#if ENABLE_WEB3_SPLASH` 内
   - 检查 START/END 标记配对完整

3. **图标加载失败**
   - SF Symbols 在 iOS 13+ 才可用
   - 需要处理降级逻辑

### 10.2 开发注意事项

1. **不要修改页面逻辑**
   - 只修改 Tab Bar UI，不改页面功能
   - 保持现有 ViewController 不变

2. **保持与 upstream 兼容**
   - 所有改动添加 CUSTOM 标记
   - 定期测试不加 flag 的情况

3. **徽章数字来源**
   - 聊天未读数由 `chatListController` 管理
   - 不要在 Tab Bar 中硬编码数字

---

## 十一、参考资料

- 原型文件：`web3_telegram_super_app_prototype (1).html`
- 开发指南：`DEVELOPMENT.md`
- 颜色规范：`submodules/TelegramCustom/Sources/Core/Utils/ColorPalette.swift`
- 布局常量：`submodules/TelegramCustom/Sources/Core/Constants/LayoutConstants.swift`
- 已完成功能：`INTEGRATION_COMPLETE.md`

---

**设计完成日期**: 2026-09-23
**预计实现时间**: 5-8 小时
**优先级**: P0（阻塞发现页开发）
