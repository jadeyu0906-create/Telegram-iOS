# 发现页（Discover）设计文档

> **创建日期**: 2026-09-24
> **功能范围**: 发现页 Tab（探索生态 + Web3 钱包占位）
> **原型参考**: `web3_telegram_super_app_prototype (1).html` - screen-discover

---

## 一、需求概述

### 1.1 目标

实现发现页 Tab，替换当前的 `DiscoverPlaceholderViewController` 占位页。顶部是 Segmented Control（钱包 | 探索生态），探索生态内容 1:1 还原原型，Web3 钱包子页面留白（后续开发）。

### 1.2 功能范围

| 模块 | 内容 | 状态 |
|------|------|------|
| 顶部 Segmented Control | 钱包 / 探索生态 切换 | ✅ 本次实现 |
| 探索生态 - Hero Banner | 轮播（3 张，内容相同） | ✅ 本次实现 |
| 探索生态 - 核心工具 | 3 宫格（Web3 会议、VPN、u多担保） | ✅ 本次实现 |
| 探索生态 - 热门 DApp | 列表（Uniswap、OpenSea） | ✅ 本次实现 |
| Web3 钱包 | 留白占位 | ⏳ 后续开发 |
| 点击行为 | 轻提示「即将推出」 | ✅ 本次实现 |
| 多语言 | 中英日韩 | ✅ 本次实现 |

### 1.3 设计原则

- **1:1 还原原型** - 颜色、字号、间距、圆角精确到 hex/pt
- **数据模型可替换** - Model 层独立，后续从 mock 数据换成接口数据
- **放 TelegramCustom 独立模块** - 符合 DEVELOP.md 规范
- **条件编译隔离** - 修改官方源码用 `#if ENABLE_WEB3_SPLASH`

---

## 二、技术方案

**方案 A：SwiftUI 实现**（已选定）

与现有 SplashScreen、LoginScreen 风格一致。SwiftUI 的 `TabView`、`LazyVGrid`、`VStack` 天然适合轮播/宫格/列表。

### 2.1 文件结构

```
submodules/TelegramCustom/Sources/Features/Discover/
├── Models/
│   └── DiscoverModels.swift              # Banner/Tool/DApp 数据模型（struct + Codable）
├── ViewModels/
│   └── DiscoverViewModel.swift           # ObservableObject，mock 数据（后续换接口）
└── Views/
    ├── DiscoverScreenView.swift          # 主容器（Segmented Control + 内容切换）
    ├── DiscoverExploreView.swift         # 探索生态内容
    ├── DiscoverWalletPlaceholderView.swift  # 钱包留白
    └── Components/
        ├── HeroBannerCarousel.swift      # Banner 轮播（3 张自动轮播）
        ├── ToolGridView.swift            # 核心工具 3 宫格
        └── DAppListView.swift            # DApp 列表
```

### 2.2 数据模型（为接口替换设计）

```swift
struct DiscoverBanner: Identifiable, Codable {
    let id: String
    let tag: String          // "超级生态推广"
    let title: String        // "Sui & ETH 跨链 Gasless 交易节"
    let subtitle: String     // "无感知签名，平台补贴 100% 链上 Gas 费"
    let actionTitle: String  // "立即参与 →"
}

struct DiscoverTool: Identifiable, Codable {
    let id: String
    let iconSystemName: String   // SF Symbol 名
    let title: String
    let subtitle: String
    let subtitleIsAccent: Bool   // 副标题是否荧光绿（VPN 是，其余不是）
}

struct DiscoverDApp: Identifiable, Codable {
    let id: String
    let logoText: String     // "UNI" / "OS"
    let logoColorToken: String  // "pink" / "blue"
    let title: String
    let subtitle: String
    let actionTitle: String  // "调用"
}
```

**关键点**：Model 是纯 `struct` + `Codable`，ViewModel 返回写死的 mock 数据。后续换成接口时，只需改 ViewModel 的数据来源（mock 数组 → 网络请求），Model 和 View 完全不动。

---

## 三、精确视觉规格（1:1 还原）

### 3.1 颜色

| 用途 | Hex | 说明 |
|------|-----|------|
| brand | `#CFFF55` | 荧光绿（选中态、图标、强调） |
| brandDark | `#A3CC3B` | 荧光绿深色 |
| bg | `#000000` | 页面背景 |
| surface1 | `#0A0A0A` | 卡片背景 |
| surface2 | `#151515` | Segmented 背景、图标底、按钮底 |
| borderClr | `#292929` | 边框 |
| txtMain | `#FFFFFF` | 主文字 |
| txtSub | `#A1A1A1` | 次要文字 |
| txtMuted | `#666666` | 弱化文字 |

这些颜色已在 `ColorPalette` 中定义（brandNeon、backgroundBlack、surface1、surface2、borderClr、textPrimary、textSecondary、textMuted），缺少的补充。

### 3.2 Segmented Control（顶部）

| 属性 | 值 |
|------|-----|
| 容器背景 | `#151515` |
| 容器圆角 | 12pt |
| 容器边框 | `#292929` 1px |
| 容器宽度 | 256pt |
| 容器内边距 | 4pt |
| 选中按钮背景 | `#CFFF55` |
| 选中按钮文字 | 黑色 |
| 未选中文字 | `#A1A1A1` |
| 按钮圆角 | 8pt |
| 按钮上下内边距 | 6pt |
| 字体 | 12pt 粗体 |
| 图标 | wallet / compass（SF Symbols） |
| 外层 | 16pt 左右 padding，12pt 上下，底部 1px 分割线 `#292929` |

### 3.3 Hero Banner（轮播，高 144pt）

| 属性 | 值 |
|------|-----|
| 高度 | 144pt |
| 背景 | 左→右渐变 `#022C22` → `#151515` → `#000000` |
| 圆角 | 16pt |
| 边框 | `#CFFF55` 30% 透明 |
| 内边距 | 16pt |
| tag 徽章背景 | `#CFFF55` 20% 透明 |
| tag 徽章边框 | `#CFFF55` 40% 透明 |
| tag 文字 | `#CFFF55` 10pt 粗体 |
| 标题 | 白色 16pt 特粗体 |
| 副标题 | `#A1A1A1` 12pt |
| 按钮 | `#CFFF55` 背景 + 黑字，12pt 粗体，12pt 圆角，12pt/6pt 内边距 |
| 圆点指示器 | 8pt 圆点，选中荧光绿 / 未选中白 30% |

轮播：3 张（内容相同），`TabView` + `Timer` 自动轮播（每 3 秒），手动滑动暂停。

### 3.4 核心工具（3 宫格）

| 属性 | 值 |
|------|-----|
| 区块标题 | `#A1A1A1` 12pt 粗体，大写，字间距加宽 |
| 标题下边距 | 10pt |
| 卡片背景 | `#0A0A0A` |
| 卡片圆角 | 16pt |
| 卡片边框 | `#292929` 1px |
| 卡片内边距 | 12pt |
| 宫格列数 | 3 列 |
| 宫格间距 | 12pt |
| 图标容器 | 40pt 方，12pt 圆角，`#151515` 背景 |
| 图标 | 荧光绿 18pt SF Symbols |
| 工具名 | 白色 12pt 粗体 |
| 描述 | `#666666` 10pt（VPN 描述荧光绿） |

工具图标映射：
- Web3 会议：`video.fill`
- 安全 VPN：`shield.lefthalf.filled`
- u多担保：`checkmark.shield.fill`（图标右上角带荧光绿脉冲圆点）

### 3.5 热门 DApp（列表）

| 属性 | 值 |
|------|-----|
| 区块标题 | 同工具标题样式 |
| 卡片背景 | `#0A0A0A` |
| 卡片圆角 | 16pt |
| 卡片边框 | `#292929` 1px |
| 卡片内边距 | 12pt |
| 卡片间距 | 8pt |
| logo | 40pt 方，12pt 圆角，14pt 特粗体文字 |
| logo 颜色 | UNI 粉色 / OS 蓝色 |
| 名称 | 白色 12pt 粗体 |
| 描述 | `#A1A1A1` 10pt |
| 调用按钮 | `#151515` 背景 + `#292929` 边框，8pt 圆角，10pt 粗体，`#A1A1A1` 文字 |

### 3.6 钱包留白

黑色背景 + 居中「即将推出」提示（wallet 图标荧光绿 + 标题 + 副标题）。

### 3.7 点击反馈

所有卡片点击 → 轻提示 toast「即将推出」（居中，2.5 秒消失）。

---

## 四、组件设计

### 4.1 DiscoverScreenView（主容器）

```swift
struct DiscoverScreenView: View {
    @StateObject var viewModel = DiscoverViewModel()
    @State var selectedTab: DiscoverTab = .explore

    var body: some View {
        VStack(spacing: 0) {
            segmentedControl          // 顶部切换
            content                   // 探索生态 或 钱包留白
        }
        .background(ColorPalette.backgroundBlack)
    }
}

enum DiscoverTab {
    case wallet      // 钱包（留白）
    case explore     // 探索生态
}
```

### 4.2 HeroBannerCarousel（轮播）

- `TabView` + `selection` 绑定
- `Timer.publish` 每 3 秒自动切换（手动滑动时重置 timer）
- 底部圆点指示器（`HStack` 的 3 个 Circle）

### 4.3 ToolGridView / DAppListView

- `LazyVGrid(columns: 3)` / `VStack`
- 数据从 `viewModel.tools` / `viewModel.dApps` 读取
- 点击触发 `viewModel.showToast("即将推出")`

### 4.4 DiscoverViewModel

```swift
class DiscoverViewModel: ObservableObject {
    @Published var banners: [DiscoverBanner] = []
    @Published var tools: [DiscoverTool] = []
    @Published var dApps: [DiscoverDApp] = []

    init() {
        loadMockData()   // 后续换成 loadFromAPI()
    }
}
```

---

## 五、多语言

新增字符串（zh-Hans / en / ja / ko）：

```
discover.tab.wallet = "Web3 钱包" / "Web3 Wallet" / "Web3 ウォレット" / "Web3 지갑"
discover.tab.explore = "探索生态" / "Explore" / "エコシステム探索" / "생태계 탐색"
discover.banner.tag = "超级生态推广" / "Super Ecosystem Promo" / "スーパーエコシステムプロモ" / "슈퍼 생태계 프로모션"
discover.banner.title = "Sui & ETH 跨链 Gasless 交易节" / "Sui & ETH Cross-chain Gasless Trading Festival" / "Sui & ETH クロスチェーン Gasless 取引フェス" / "Sui & ETH 크로스체인 가스리스 트레이딩 페스티벌"
discover.banner.subtitle = "无感知签名，平台补贴 100% 链上 Gas 费" / "Seamless signing, platform covers 100% on-chain gas fees" / "シームレス署名、プラットフォームがオンチェーンガス代100%負担" / "원활한 서명, 플랫폼이 온체인 가스비 100% 지원"
discover.banner.action = "立即参与 →" / "Join Now →" / "今すぐ参加 →" / "지금 참여 →"
discover.tools.section = "核心工具能力" / "Core Tools" / "コアツール" / "핵심 도구"
discover.tool.meeting = "Web3 会议" / "Web3 Meeting" / "Web3 会議" / "Web3 회의"
discover.tool.meeting.desc = "高清/可控录制" / "HD/Controllable Recording" / "高画質/制御可能な録画" / "고화질/제어 가능한 녹화"
discover.tool.vpn = "安全 VPN" / "Secure VPN" / "セキュア VPN" / "보안 VPN"
discover.tool.vpn.desc = "剩余 8.5 GB" / "8.5 GB Remaining" / "残り 8.5 GB" / "8.5 GB 남음"
discover.tool.escrow = "u多担保" / "u-Duo Escrow" / "u多保証" / "u다오 보증"
discover.tool.escrow.desc = "多签/防骗查验" / "Multi-sig/Anti-fraud" / "マルチシグ/詐欺防止検証" / "멀티시그/사기 방지 검증"
discover.dapp.section = "热门 Web3 DApp" / "Hot Web3 DApps" / "人気 Web3 DApp" / "인기 Web3 DApp"
discover.dapp.uniswap.desc = "去中心化 Swap 交易所" / "Decentralized Swap Exchange" / "分散型 Swap 取引所" / "탈중앙화 스왑 거래소"
discover.dapp.opensea.desc = "NFT 交易与收藏品市场" / "NFT Marketplace" / "NFT マーケットプレイス" / "NFT 마켓플레이스"
discover.dapp.action = "调用" / "Open" / "開く" / "열기"
discover.comingSoon = "即将推出" / "Coming Soon" / "近日公開" / "곧 출시"
```

---

## 六、集成方式

替换 `TelegramRootController.swift` 中的 `DiscoverPlaceholderViewController`：

```swift
// 当前（占位）
let discoverController = DiscoverPlaceholderViewController(navigationBarPresentationData: nil)

// 改为（SwiftUI 发现页）
let discoverView = DiscoverScreenView()
let discoverController = DiscoverViewController(rootView: discoverView)
```

其中 `DiscoverViewController` 是 UIKit 容器（继承 Display `ViewController`），内部用 `UIHostingController` 包裹 `DiscoverScreenView`。

**条件编译**：整个集成用 `#if ENABLE_WEB3_SPLASH` 包裹，保持 upstream 兼容。

---

## 七、测试清单

- [ ] 发现页 Tab 显示 Segmented Control（钱包 | 探索生态）
- [ ] 默认选中「探索生态」
- [ ] Banner 轮播 3 张自动切换 + 圆点指示器
- [ ] 核心工具 3 宫格显示（图标 + 名称 + 描述）
- [ ] 热门 DApp 列表显示（logo + 名称 + 调用按钮）
- [ ] 点击卡片弹「即将推出」轻提示
- [ ] 切到「钱包」显示留白占位
- [ ] 多语言切换正常（中英日韩）
- [ ] 视觉 1:1（颜色/字号/间距/圆角精确）
- [ ] 不加 flag 时兼容 upstream

---

**设计完成日期**: 2026-09-24
**预计实现时间**: 半天
**优先级**: P1（发现页核心功能）
