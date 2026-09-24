# 自定义 Tab Bar 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现自定义底部 Tab Bar，包含 4 个 Tab（聊天、联系人、发现、我的），样式匹配 HTML 原型（荧光绿品牌色 + 黑色背景）

**Architecture:** 在 TelegramCustom 模块中创建 CustomTabBarComponent（基于 ComponentFlow），通过条件编译在 TabBarControllerNode 中切换使用，发现页暂时显示占位页面

**Tech Stack:** Swift, ComponentFlow, AsyncDisplayKit, SF Symbols, Bazel

---

## 文件结构规划

### 新增文件

```
submodules/TelegramCustom/Sources/Features/CustomTabBar/
├── CustomTabBarComponent.swift          # Tab Bar 组件主体（~400 行）
├── CustomTabBarItemView.swift           # 单个 Tab 项视图（~200 行）
└── CustomTabBarBadgeView.swift          # 徽章视图（~100 行）

submodules/TelegramCustom/Sources/Features/DiscoverPlaceholder/
└── DiscoverPlaceholderViewController.swift  # 发现页占位（~150 行）

submodules/TelegramCustom/Resources/Localizations/
├── zh-Hans.lproj/Localizable.strings    # 添加 Tab 相关字符串
├── en.lproj/Localizable.strings
├── ja.lproj/Localizable.strings
└── ko.lproj/Localizable.strings
```

### 修改文件

```
submodules/TelegramCustom/BUILD                      # 添加模块定义
submodules/TelegramCustom/Sources/TelegramCustom.swift  # 导出新模块
submodules/TabBarUI/Sources/TabBarControllerNode.swift  # 集成自定义组件
```

---

## Task 1: 创建徽章视图组件

**Files:**
- Create: `submodules/TelegramCustom/Sources/Features/CustomTabBar/CustomTabBarBadgeView.swift`

- [ ] **Step 1: 创建 CustomTabBarBadgeView 基础结构**

```swift
import Foundation
import UIKit
import Display

final class CustomTabBarBadgeView: UIView {
    private let backgroundView: UIView
    private let textLabel: UILabel

    var badgeText: String? {
        didSet {
            updateContent()
        }
    }

    override init(frame: CGRect) {
        self.backgroundView = UIView()
        self.backgroundView.backgroundColor = UIColor(rgb: 0xEF4444)
        self.backgroundView.layer.cornerRadius = 8.0

        self.textLabel = UILabel()
        self.textLabel.font = .systemFont(ofSize: 9, weight: .bold)
        self.textLabel.textColor = .white
        self.textLabel.textAlignment = .center

        super.init(frame: frame)

        self.addSubview(self.backgroundView)
        self.addSubview(self.textLabel)

        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateContent() {
        guard let text = badgeText, !text.isEmpty else {
            self.isHidden = true
            return
        }

        self.isHidden = false

        // 超过 99 显示 "99+"
        let displayText: String
        if let number = Int(text), number > 99 {
            displayText = "99+"
        } else {
            displayText = text
        }

        self.textLabel.text = displayText
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let text = self.textLabel.text, !text.isEmpty else {
            return
        }

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: 100, height: 16),
            options: .usesLineFragmentOrigin,
            attributes: [.font: self.textLabel.font!],
            context: nil
        ).size

        // 最小宽度 16pt，如果文字更宽则自适应
        let minWidth: CGFloat = 16.0
        let width = max(minWidth, ceil(textSize.width) + 8.0)
        let height: CGFloat = 16.0

        let badgeSize = CGSize(width: width, height: height)
        self.bounds = CGRect(origin: .zero, size: badgeSize)

        self.backgroundView.frame = self.bounds
        self.backgroundView.layer.cornerRadius = height / 2.0

        self.textLabel.frame = self.bounds
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let text = self.textLabel.text, !text.isEmpty else {
            return .zero
        }

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: 100, height: 16),
            options: .usesLineFragmentOrigin,
            attributes: [.font: self.textLabel.font!],
            context: nil
        ).size

        let minWidth: CGFloat = 16.0
        let width = max(minWidth, ceil(textSize.width) + 8.0)
        let height: CGFloat = 16.0

        return CGSize(width: width, height: height)
    }
}
```

- [ ] **Step 2: 验证徽章视图编译**

Run: `./dev/open-xcode.sh`
然后在 Xcode 中 Build（⌘B）
Expected: 编译成功，无错误

- [ ] **Step 3: Commit 徽章视图**

```bash
git add submodules/TelegramCustom/Sources/Features/CustomTabBar/CustomTabBarBadgeView.swift
git commit -m "feat(tabbar): add CustomTabBarBadgeView component

- Red badge background (#EF4444)
- White bold text (9pt)
- Auto-sizing based on text width
- Display '99+' for numbers > 99
- Hide when badge text is empty

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: 创建单个 Tab 项视图

**Files:**
- Create: `submodules/TelegramCustom/Sources/Features/CustomTabBar/CustomTabBarItemView.swift`
- Read: `submodules/TelegramCustom/Sources/Core/Utils/ColorPalette.swift`

- [ ] **Step 1: 创建 CustomTabBarItemView 基础结构**

```swift
import Foundation
import UIKit
import Display
import TelegramCustomCore

final class CustomTabBarItemView: UIView {
    private let iconImageView: UIImageView
    private let titleLabel: UILabel
    private let badgeView: CustomTabBarBadgeView

    private var isSelectedState: Bool = false

    var icon: UIImage? {
        didSet {
            self.iconImageView.image = icon
        }
    }

    var title: String? {
        didSet {
            self.titleLabel.text = title
            self.setNeedsLayout()
        }
    }

    var badgeText: String? {
        didSet {
            self.badgeView.badgeText = badgeText
            self.setNeedsLayout()
        }
    }

    var isSelected: Bool {
        get {
            return self.isSelectedState
        }
        set {
            if self.isSelectedState != newValue {
                self.isSelectedState = newValue
                self.updateAppearance(animated: true)
            }
        }
    }

    override init(frame: CGRect) {
        self.iconImageView = UIImageView()
        self.iconImageView.contentMode = .scaleAspectFit

        self.titleLabel = UILabel()
        self.titleLabel.textAlignment = .center
        self.titleLabel.numberOfLines = 1

        self.badgeView = CustomTabBarBadgeView()

        super.init(frame: frame)

        self.addSubview(self.iconImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.badgeView)

        self.updateAppearance(animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAppearance(animated: Bool) {
        let duration: TimeInterval = animated ? 0.15 : 0

        UIView.animate(withDuration: duration) {
            if self.isSelectedState {
                // 选中状态：荧光绿
                self.iconImageView.tintColor = ColorPalette.brandNeon
                self.titleLabel.textColor = ColorPalette.brandNeon
                self.titleLabel.font = .systemFont(ofSize: 10, weight: .bold)
            } else {
                // 未选中状态：灰色
                self.iconImageView.tintColor = UIColor.white.withAlphaComponent(0.6)
                self.titleLabel.textColor = ColorPalette.textSecondary
                self.titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let bounds = self.bounds
        let iconSize: CGFloat = 28.0
        let spacing: CGFloat = 4.0

        // 图标居中，距离顶部一定距离
        let iconY: CGFloat = 3.0
        let iconFrame = CGRect(
            x: (bounds.width - iconSize) / 2.0,
            y: iconY,
            width: iconSize,
            height: iconSize
        )
        self.iconImageView.frame = iconFrame

        // 文字在图标下方
        let titleY = iconFrame.maxY + spacing
        let titleHeight: CGFloat = 12.0
        let titleFrame = CGRect(
            x: 0,
            y: titleY,
            width: bounds.width,
            height: titleHeight
        )
        self.titleLabel.frame = titleFrame

        // 徽章在图标右上角
        if !self.badgeView.isHidden {
            let badgeSize = self.badgeView.sizeThatFits(bounds.size)
            let badgeFrame = CGRect(
                x: iconFrame.maxX - 4.0,
                y: iconFrame.minY - 4.0,
                width: badgeSize.width,
                height: badgeSize.height
            )
            self.badgeView.frame = badgeFrame
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let iconSize: CGFloat = 28.0
        let spacing: CGFloat = 4.0
        let titleHeight: CGFloat = 12.0
        let topPadding: CGFloat = 3.0
        let bottomPadding: CGFloat = 3.0

        let totalHeight = topPadding + iconSize + spacing + titleHeight + bottomPadding

        return CGSize(width: size.width, height: totalHeight)
    }
}
```

- [ ] **Step 2: 验证 Tab 项视图编译**

Run: `./dev/open-xcode.sh`
然后在 Xcode 中 Build（⌘B）
Expected: 编译成功，无错误

- [ ] **Step 3: Commit Tab 项视图**

```bash
git add submodules/TelegramCustom/Sources/Features/CustomTabBar/CustomTabBarItemView.swift
git commit -m "feat(tabbar): add CustomTabBarItemView component

- Vertical layout: icon (28pt) + text (10pt)
- Selected state: neon green (#CFFF55) bold
- Unselected state: gray (60% alpha) medium
- Badge positioned at icon top-right corner
- Smooth animated state transitions (0.15s)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: 创建 Tab Bar 主组件（第一部分）

**Files:**
- Create: `submodules/TelegramCustom/Sources/Features/CustomTabBar/CustomTabBarComponent.swift`

- [ ] **Step 1: 创建 CustomTabBarComponent 结构定义**

```swift
import Foundation
import UIKit
import Display
import ComponentFlow
import TelegramPresentationData
import TelegramCustomCore

public final class CustomTabBarComponent: Component {
    public final class Item: Equatable {
        public let id: AnyHashable
        public let title: String
        public let iconSystemName: String
        public let badge: String?
        public let action: (Bool) -> Void
        public let doubleTapAction: (() -> Void)?
        public let contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?

        public init(
            id: AnyHashable,
            title: String,
            iconSystemName: String,
            badge: String?,
            action: @escaping (Bool) -> Void,
            doubleTapAction: (() -> Void)?,
            contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?
        ) {
            self.id = id
            self.title = title
            self.iconSystemName = iconSystemName
            self.badge = badge
            self.action = action
            self.doubleTapAction = doubleTapAction
            self.contextAction = contextAction
        }

        public static func ==(lhs: Item, rhs: Item) -> Bool {
            if lhs === rhs {
                return true
            }
            if lhs.id != rhs.id {
                return false
            }
            if lhs.title != rhs.title {
                return false
            }
            if lhs.iconSystemName != rhs.iconSystemName {
                return false
            }
            if lhs.badge != rhs.badge {
                return false
            }
            if (lhs.doubleTapAction == nil) != (rhs.doubleTapAction == nil) {
                return false
            }
            if (lhs.contextAction == nil) != (rhs.contextAction == nil) {
                return false
            }
            return true
        }
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
    ) {
        self.theme = theme
        self.strings = strings
        self.items = items
        self.selectedId = selectedId
        self.outerInsets = outerInsets
    }

    public static func ==(lhs: CustomTabBarComponent, rhs: CustomTabBarComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.items != rhs.items {
            return false
        }
        if lhs.selectedId != rhs.selectedId {
            return false
        }
        if lhs.outerInsets != rhs.outerInsets {
            return false
        }
        return true
    }
}
```

- [ ] **Step 2: 验证组件结构编译**

Run: `./dev/open-xcode.sh`
然后在 Xcode 中 Build（⌘B）
Expected: 编译成功，无错误

- [ ] **Step 3: Commit 组件结构**

```bash
git add submodules/TelegramCustom/Sources/Features/CustomTabBar/CustomTabBarComponent.swift
git commit -m "feat(tabbar): add CustomTabBarComponent structure

- Define Item class with id, title, icon, badge
- Support action, double-tap, context actions
- Implement Equatable for change detection
- Add theme, strings, items, selectedId properties

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: 创建 Tab Bar 主组件（第二部分 - View 实现）

**Files:**
- Modify: `submodules/TelegramCustom/Sources/Features/CustomTabBar/CustomTabBarComponent.swift`

- [ ] **Step 1: 添加 View 类定义**

在 `CustomTabBarComponent.swift` 文件末尾添加：

```swift
public final class View: UIView {
    private let backgroundView: UIView
    private var itemViews: [AnyHashable: CustomTabBarItemView] = [:]

    private var component: CustomTabBarComponent?

    override init(frame: CGRect) {
        self.backgroundView = UIView()
        self.backgroundView.backgroundColor = ColorPalette.surface1

        super.init(frame: frame)

        self.addSubview(self.backgroundView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(component: CustomTabBarComponent, availableSize: CGSize, transition: ComponentTransition) -> CGSize {
        self.component = component

        // 更新背景
        let backgroundFrame = CGRect(origin: .zero, size: availableSize)
        transition.setFrame(view: self.backgroundView, frame: backgroundFrame)

        // 计算 Tab Bar 高度
        let itemHeight: CGFloat = 49.0
        let totalHeight = itemHeight + component.outerInsets.bottom

        // 计算每个 item 的宽度
        let itemWidth = availableSize.width / CGFloat(component.items.count)

        // 更新或创建 item views
        var validIds = Set<AnyHashable>()

        for (index, item) in component.items.enumerated() {
            validIds.insert(item.id)

            let itemView: CustomTabBarItemView
            if let existing = self.itemViews[item.id] {
                itemView = existing
            } else {
                itemView = CustomTabBarItemView()
                self.itemViews[item.id] = itemView
                self.addSubview(itemView)

                // 添加点击手势
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
                itemView.addGestureRecognizer(tapGesture)
                itemView.isUserInteractionEnabled = true
                itemView.tag = index
            }

            // 更新 item 内容
            let icon = UIImage(
                systemName: item.iconSystemName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
            )?.withRenderingMode(.alwaysTemplate)

            itemView.icon = icon
            itemView.title = item.title
            itemView.badgeText = item.badge
            itemView.isSelected = (item.id == component.selectedId)

            // 布局 item
            let itemFrame = CGRect(
                x: CGFloat(index) * itemWidth,
                y: 0,
                width: itemWidth,
                height: itemHeight
            )
            transition.setFrame(view: itemView, frame: itemFrame)
        }

        // 移除不再需要的 views
        var toRemove: [AnyHashable] = []
        for (id, view) in self.itemViews {
            if !validIds.contains(id) {
                view.removeFromSuperview()
                toRemove.append(id)
            }
        }
        for id in toRemove {
            self.itemViews.removeValue(forKey: id)
        }

        return CGSize(width: availableSize.width, height: totalHeight)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let itemView = gesture.view as? CustomTabBarItemView,
              let component = self.component,
              itemView.tag < component.items.count else {
            return
        }

        let item = component.items[itemView.tag]

        // 点击动画
        UIView.animate(withDuration: 0.1, animations: {
            itemView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                itemView.transform = .identity
            }
        }

        // 触发回调
        item.action(false)
    }
}
```

- [ ] **Step 2: 实现 makeView 方法**

在 `CustomTabBarComponent` 类中添加：

```swift
public func makeView() -> View {
    return View(frame: CGRect())
}

public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
    return view.update(component: self, availableSize: availableSize, transition: transition)
}
```

- [ ] **Step 3: 验证完整组件编译**

Run: `./dev/open-xcode.sh`
然后在 Xcode 中 Build（⌘B）
Expected: 编译成功，无错误

- [ ] **Step 4: Commit View 实现**

```bash
git add submodules/TelegramCustom/Sources/Features/CustomTabBar/CustomTabBarComponent.swift
git commit -m "feat(tabbar): implement CustomTabBarComponent.View

- Create/update item views dynamically
- Layout items evenly across width
- Load SF Symbol icons (28pt, regular weight)
- Handle tap gestures with scale animation
- Update selected state based on selectedId
- Background color: ColorPalette.surface1

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: 创建发现页占位 ViewController

**Files:**
- Create: `submodules/TelegramCustom/Sources/Features/DiscoverPlaceholder/DiscoverPlaceholderViewController.swift`

- [ ] **Step 1: 创建 DiscoverPlaceholderViewController**

```swift
import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCustomCore
import SwiftSignalKit

public final class DiscoverPlaceholderViewController: ViewController {
    private let iconImageView: UIImageView
    private let titleLabel: UILabel
    private let subtitleLabel: UILabel

    public init() {
        self.iconImageView = UIImageView()
        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()

        super.init(navigationBarPresentationData: nil)

        self.statusBar.statusBarStyle = .White
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNode.backgroundColor = ColorPalette.backgroundBlack
        self.displayNodeDidLoad()
    }

    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()

        // 配置图标
        if let icon = UIImage(
            systemName: "safari",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 64, weight: .regular)
        )?.withRenderingMode(.alwaysTemplate) {
            self.iconImageView.image = icon
            self.iconImageView.tintColor = ColorPalette.brandNeon
        }
        self.iconImageView.contentMode = .scaleAspectFit

        // 配置标题
        self.titleLabel.text = "discover.placeholder.title".localized
        self.titleLabel.textColor = .white
        self.titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        self.titleLabel.textAlignment = .center

        // 配置副标题
        self.subtitleLabel.text = "discover.placeholder.subtitle".localized
        self.subtitleLabel.textColor = ColorPalette.textSecondary
        self.subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        self.subtitleLabel.textAlignment = .center

        self.displayNode.view.addSubview(self.iconImageView)
        self.displayNode.view.addSubview(self.titleLabel)
        self.displayNode.view.addSubview(self.subtitleLabel)
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        let bounds = CGRect(origin: .zero, size: layout.size)

        // 垂直居中布局
        let iconSize: CGFloat = 64.0
        let spacing: CGFloat = 16.0

        let titleSize = self.titleLabel.sizeThatFits(CGSize(width: layout.size.width - 40, height: 100))
        let subtitleSize = self.subtitleLabel.sizeThatFits(CGSize(width: layout.size.width - 40, height: 100))

        let totalHeight = iconSize + spacing + titleSize.height + 8 + subtitleSize.height
        let startY = (bounds.height - totalHeight) / 2.0

        let iconFrame = CGRect(
            x: (bounds.width - iconSize) / 2.0,
            y: startY,
            width: iconSize,
            height: iconSize
        )

        let titleFrame = CGRect(
            x: 20,
            y: iconFrame.maxY + spacing,
            width: bounds.width - 40,
            height: titleSize.height
        )

        let subtitleFrame = CGRect(
            x: 20,
            y: titleFrame.maxY + 8,
            width: bounds.width - 40,
            height: subtitleSize.height
        )

        transition.updateFrame(view: self.iconImageView, frame: iconFrame)
        transition.updateFrame(view: self.titleLabel, frame: titleFrame)
        transition.updateFrame(view: self.subtitleLabel, frame: subtitleFrame)
    }
}
```

- [ ] **Step 2: 验证占位页编译**

Run: `./dev/open-xcode.sh`
然后在 Xcode 中 Build（⌘B）
Expected: 编译成功，无错误

- [ ] **Step 3: Commit 占位页**

```bash
git add submodules/TelegramCustom/Sources/Features/DiscoverPlaceholder/DiscoverPlaceholderViewController.swift
git commit -m "feat(tabbar): add DiscoverPlaceholderViewController

- Display 'Discover' placeholder page
- Neon green safari icon (64pt)
- Title: 'Discover' (24pt bold white)
- Subtitle: 'Coming Soon' (14pt gray)
- Centered layout on black background

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: 添加多语言字符串

**Files:**
- Modify: `submodules/TelegramCustom/Resources/Localizations/zh-Hans.lproj/Localizable.strings`
- Modify: `submodules/TelegramCustom/Resources/Localizations/en.lproj/Localizable.strings`
- Modify: `submodules/TelegramCustom/Resources/Localizations/ja.lproj/Localizable.strings`
- Modify: `submodules/TelegramCustom/Resources/Localizations/ko.lproj/Localizable.strings`

- [ ] **Step 1: 添加中文字符串**

在 `zh-Hans.lproj/Localizable.strings` 文件末尾添加：

```
/* Tab Bar */
"tabbar.chat.title" = "聊天";
"tabbar.contacts.title" = "联系人";
"tabbar.discover.title" = "发现";
"tabbar.mine.title" = "我的";

/* Discover Placeholder */
"discover.placeholder.title" = "发现";
"discover.placeholder.subtitle" = "即将推出";
```

- [ ] **Step 2: 添加英文字符串**

在 `en.lproj/Localizable.strings` 文件末尾添加：

```
/* Tab Bar */
"tabbar.chat.title" = "Chats";
"tabbar.contacts.title" = "Contacts";
"tabbar.discover.title" = "Discover";
"tabbar.mine.title" = "Me";

/* Discover Placeholder */
"discover.placeholder.title" = "Discover";
"discover.placeholder.subtitle" = "Coming Soon";
```

- [ ] **Step 3: 添加日文字符串**

在 `ja.lproj/Localizable.strings` 文件末尾添加：

```
/* Tab Bar */
"tabbar.chat.title" = "チャット";
"tabbar.contacts.title" = "連絡先";
"tabbar.discover.title" = "発見";
"tabbar.mine.title" = "自分";

/* Discover Placeholder */
"discover.placeholder.title" = "発見";
"discover.placeholder.subtitle" = "近日公開";
```

- [ ] **Step 4: 添加韩文字符串**

在 `ko.lproj/Localizable.strings` 文件末尾添加：

```
/* Tab Bar */
"tabbar.chat.title" = "채팅";
"tabbar.contacts.title" = "연락처";
"tabbar.discover.title" = "발견";
"tabbar.mine.title" = "내 정보";

/* Discover Placeholder */
"discover.placeholder.title" = "발견";
"discover.placeholder.subtitle" = "곧 출시";
```

- [ ] **Step 5: Commit 多语言字符串**

```bash
git add submodules/TelegramCustom/Resources/Localizations/*/Localizable.strings
git commit -m "i18n(tabbar): add tab bar localization strings

- Add 4 tab titles: chat, contacts, discover, mine
- Add discover placeholder: title and subtitle
- Support 4 languages: zh-Hans, en, ja, ko

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: 更新 BUILD 配置

**Files:**
- Modify: `submodules/TelegramCustom/BUILD`
- Modify: `submodules/TelegramCustom/Sources/TelegramCustom.swift`

- [ ] **Step 1: 在 BUILD 中添加 CustomTabBar 模块**

在 `submodules/TelegramCustom/BUILD` 文件中添加（在其他 swift_library 定义之后）：

```python
# ==================== CUSTOM START ====================
# 描述：添加 CustomTabBar 和 DiscoverPlaceholder 模块
# 文件：TelegramCustom/BUILD
# 日期：2026-09-23

swift_library(
    name = "CustomTabBarModule",
    module_name = "CustomTabBar",
    srcs = glob([
        "Sources/Features/CustomTabBar/**/*.swift",
    ]),
    deps = [
        ":TelegramCustomCore",
        "//submodules/Display:Display",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "DiscoverPlaceholderModule",
    module_name = "DiscoverPlaceholder",
    srcs = glob([
        "Sources/Features/DiscoverPlaceholder/**/*.swift",
    ]),
    deps = [
        ":TelegramCustomCore",
        "//submodules/Display:Display",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = ["//visibility:public"],
)
# ==================== CUSTOM END ====================
```

然后找到 `TelegramCustom` 的 `swift_library` 定义，在 `deps` 数组中添加新模块：

```python
swift_library(
    name = "TelegramCustom",
    module_name = "TelegramCustom",
    srcs = ["Sources/TelegramCustom.swift"],
    deps = [
        ":TelegramCustomCore",
        ":SplashScreenModule",
        ":LoginScreenModule",
        ":CustomTabBarModule",           # ← 添加这一行
        ":DiscoverPlaceholderModule",    # ← 添加这一行
    ],
    visibility = ["//visibility:public"],
)
```

- [ ] **Step 2: 在 TelegramCustom.swift 中导出模块**

在 `submodules/TelegramCustom/Sources/TelegramCustom.swift` 文件中添加：

```swift
@_exported import CustomTabBar
@_exported import DiscoverPlaceholder
```

- [ ] **Step 3: 验证 BUILD 配置**

Run: `./dev/open-xcode.sh`
Expected: 工程重新生成成功，无错误

- [ ] **Step 4: Commit BUILD 配置**

```bash
git add submodules/TelegramCustom/BUILD submodules/TelegramCustom/Sources/TelegramCustom.swift
git commit -m "build(tabbar): add CustomTabBar modules to BUILD

- Add CustomTabBarModule swift_library
- Add DiscoverPlaceholderModule swift_library
- Export modules in TelegramCustom.swift
- Configure dependencies: Display, ComponentFlow, AsyncDisplayKit

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: 集成到 TabBarControllerNode（第一部分）

**Files:**
- Modify: `submodules/TabBarUI/Sources/TabBarControllerNode.swift:1-50`

- [ ] **Step 1: 添加条件编译导入**

在 `TabBarControllerNode.swift` 文件顶部的 import 语句之后添加：

```swift
// ==================== CUSTOM START ====================
// 描述：导入 TelegramCustom 模块以使用自定义 Tab Bar
// 文件：TabBarControllerNode.swift
// 日期：2026-09-23
// 注意：同步 upstream 时保留此块
#if ENABLE_WEB3_SPLASH
import TelegramCustom
#endif
// ==================== CUSTOM END ====================
```

- [ ] **Step 2: 验证导入编译**

Run: `./dev/open-xcode.sh`
然后在 Xcode 中 Build（⌘B）
Expected: 编译成功，无错误

- [ ] **Step 3: Commit 导入语句**

```bash
git add submodules/TabBarUI/Sources/TabBarControllerNode.swift
git commit -m "feat(tabbar): add conditional import for TelegramCustom

- Import TelegramCustom under ENABLE_WEB3_SPLASH flag
- Add CUSTOM marker for upstream sync
- Prepare for CustomTabBarComponent integration

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: 集成到 TabBarControllerNode（第二部分 - 转换逻辑）

**Files:**
- Modify: `submodules/TabBarUI/Sources/TabBarControllerNode.swift:195-290`

- [ ] **Step 1: 添加 Tab 项转换辅助方法**

在 `TabBarControllerNode` 类中添加私有方法（在 `updateImpl` 方法之前）：

```swift
// ==================== CUSTOM START ====================
#if ENABLE_WEB3_SPLASH
private func convertToCustomTabBarItems() -> [CustomTabBarComponent.Item] {
    return self.tabBarItems.enumerated().map { index, nodeItem in
        let tabBarItem = nodeItem.item
        let itemId = AnyHashable(ObjectIdentifier(tabBarItem))

        // 根据 tab 位置选择图标
        let iconSystemName: String
        switch index {
        case 0: iconSystemName = "message.fill"          // 聊天
        case 1: iconSystemName = "person.crop.circle"    // 联系人
        case 2: iconSystemName = "safari"                // 发现
        case 3: iconSystemName = "person.fill"           // 我的
        default: iconSystemName = "circle"
        }

        // 根据 tab 位置选择标题
        let title: String
        switch index {
        case 0: title = "tabbar.chat.title".localized
        case 1: title = "tabbar.contacts.title".localized
        case 2: title = "tabbar.discover.title".localized
        case 3: title = "tabbar.mine.title".localized
        default: title = tabBarItem.title ?? ""
        }

        return CustomTabBarComponent.Item(
            id: itemId,
            title: title,
            iconSystemName: iconSystemName,
            badge: tabBarItem.badgeValue,
            action: { [weak self] isLongTap in
                guard let self else { return }
                if let index = self.tabBarItems.firstIndex(where: { AnyHashable(ObjectIdentifier($0.item)) == itemId }) {
                    self.itemSelected(index, isLongTap, [])
                }
            },
            doubleTapAction: self.itemHasDoubleTapAction(index) ? { [weak self] in
                guard let self else { return }
                if let index = self.tabBarItems.firstIndex(where: { AnyHashable(ObjectIdentifier($0.item)) == itemId }) {
                    self.itemDoubleTapped(index)
                }
            } : nil,
            contextAction: { [weak self] gesture, sourceView in
                guard let self else { return }
                if let index = self.tabBarItems.firstIndex(where: { AnyHashable(ObjectIdentifier($0.item)) == itemId }) {
                    self.contextAction(index, sourceView, gesture)
                }
            }
        )
    }
}
#endif
// ==================== CUSTOM END ====================
```

- [ ] **Step 2: 修改 updateImpl 方法使用自定义组件**

找到 `updateImpl` 方法中创建 `TabBarComponent` 的部分（约第 230 行），用条件编译包裹：

```swift
// ==================== CUSTOM START ====================
#if ENABLE_WEB3_SPLASH
let tabBarSize = self.tabBarView.update(
    transition: tabBarTransition,
    component: AnyComponent(CustomTabBarComponent(
        theme: self.theme,
        strings: self.strings,
        items: self.convertToCustomTabBarItems(),
        selectedId: selectedId,
        outerInsets: UIEdgeInsets(top: 0.0, left: sideInset, bottom: tabBarBottomInset, right: sideInset)
    )),
    environment: {},
    containerSize: CGSize(width: params.layout.size.width - sideInset * 2.0, height: 100.0)
)
#else
// ==================== CUSTOM END ====================
let tabBarSize = self.tabBarView.update(
    transition: tabBarTransition,
    component: AnyComponent(TabBarComponent(
        theme: self.theme,
        strings: self.strings,
        items: self.tabBarItems.map { item in
            // ...原有代码保持不变...
        },
        search: self.currentController?.tabBarSearchState.flatMap { tabBarSearchState in
            // ...原有代码保持不变...
        },
        selectedId: selectedId,
        outerInsets: UIEdgeInsets(top: 0.0, left: sideInset, bottom: tabBarBottomInset, right: sideInset)
    )),
    environment: {},
    containerSize: CGSize(width: params.layout.size.width - sideInset * 2.0, height: 100.0)
)
// ==================== CUSTOM START ====================
#endif
// ==================== CUSTOM END ====================
```

- [ ] **Step 3: 验证集成编译**

Run: `./dev/open-xcode.sh`
然后在 Xcode 中 Build（⌘B）
Expected: 编译成功，无错误

- [ ] **Step 4: Commit 集成逻辑**

```bash
git add submodules/TabBarUI/Sources/TabBarControllerNode.swift
git commit -m "feat(tabbar): integrate CustomTabBarComponent into TabBarControllerNode

- Add convertToCustomTabBarItems() helper method
- Map tab indices to SF Symbol icons and localized titles
- Forward action, doubleTap, and context callbacks
- Wrap CustomTabBarComponent with ENABLE_WEB3_SPLASH flag
- Preserve original TabBarComponent as fallback

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: 测试自定义 Tab Bar

**Files:**
- Test: 运行模拟器验证功能

- [ ] **Step 1: 编译并启动模拟器**

```bash
./dev/run-simulator.sh
```

Expected: 编译成功，模拟器启动，显示自定义 Tab Bar

- [ ] **Step 2: 功能测试检查清单**

手动测试以下功能：

**基础显示**
- [ ] Tab Bar 显示在屏幕底部
- [ ] 背景色为黑色 (#0A0A0A)
- [ ] 4 个 Tab 均匀分布
- [ ] 图标和文字垂直排列

**Tab 切换**
- [ ] 点击聊天 Tab，切换到聊天列表页
- [ ] 点击联系人 Tab，切换到联系人页
- [ ] 点击发现 Tab，显示占位页面（"即将推出"）
- [ ] 点击我的 Tab，切换到设置页

**选中状态**
- [ ] 选中的 Tab 显示荧光绿色 (#CFFF55)
- [ ] 未选中的 Tab 显示灰色
- [ ] 选中的文字为粗体（Bold）
- [ ] 未选中的文字为中等（Medium）

**徽章显示**（如果有未读消息）
- [ ] 聊天 Tab 显示未读数徽章
- [ ] 徽章位于图标右上角
- [ ] 徽章背景为红色 (#EF4444)
- [ ] 数字 > 99 显示 "99+"

**交互动画**
- [ ] 点击 Tab 有缩放动画反馈
- [ ] 切换 Tab 有平滑过渡

- [ ] **Step 3: 截图保存（可选）**

如果一切正常，可以截图保存到 `docs/screenshots/` 目录。

- [ ] **Step 4: 创建测试记录**

```bash
git add .
git commit -m "test(tabbar): verify custom tab bar functionality

Tested features:
- [x] 4 tabs displayed correctly (Chats, Contacts, Discover, Settings)
- [x] Tab switching works for all tabs
- [x] Selected state: neon green (#CFFF55) bold
- [x] Unselected state: gray medium
- [x] Badge displays on chat tab (if unread messages exist)
- [x] Discover placeholder shows 'Coming Soon'
- [x] Tap animation feedback works
- [x] Layout adapts to safe area on iPhone

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## 完成检查清单

实现完成后，验证以下所有项：

### 代码质量
- [ ] 所有源码文件添加了 CUSTOM 标记
- [ ] 条件编译语句完整（START 和 END 配对）
- [ ] 没有调试用的 print 语句
- [ ] 没有注释掉的代码
- [ ] 符合项目代码规范

### 功能完整性
- [ ] 4 个 Tab 都能正常点击切换
- [ ] 聊天/联系人/设置页面功能正常
- [ ] 发现页显示占位提示
- [ ] 徽章显示正确（如果有未读）
- [ ] 多语言切换正常

### 视觉还原
- [ ] 选中态荧光绿色 #CFFF55
- [ ] 未选中态灰色
- [ ] 背景色 #0A0A0A
- [ ] 图标尺寸 28pt
- [ ] 文字大小 10pt
- [ ] 间距正确

### 兼容性
- [ ] 不加 flag 时使用原有 Tab Bar
- [ ] 加 flag 时使用自定义 Tab Bar
- [ ] iPhone SE / iPhone 15 Pro Max 都正常
- [ ] 横屏模式正常（iPad）

---

## 后续工作

完成本计划后的扩展方向：

1. **图标替换** - 等设计师提供切图后，替换 SF Symbols
2. **发现页开发** - 实现发现页的实际功能
3. **高级交互** - 长按菜单、双击回顶、滑动切换
4. **动画优化** - 更平滑的切换动画

---

**预计实现时间**: 5-8 小时
**优先级**: P0
**依赖**: 无
