# 二开工具与工作流

这是本仓库（你的 Telegram-iOS fork）的二开工具目录，包含编译运行、同步官方的脚本，以及二开工作流说明。

> **先回答最关键的问题：二开要不要新建工作文件夹？**
>
> **不要。** 二开不靠文件夹隔离。Telegram-iOS 的目录结构是固定的，二开就是直接改现有源码文件。单人开发**直接在 `master` 上改**即可，不需要 feature 分支。
>
> 本 `dev/` 目录只是放工具脚本的地方，跟二开代码隔离无关。它属于你自己的 fork（官方仓库没有这个目录），提交到 fork 即可，同步官方时不会冲突。

---

## 仓库关系（fork + upstream）

```
官方 TelegramMessenger/Telegram-iOS  ──(upstream remote)──►  你的 fork jadeyu0906-create/Telegram-iOS
                                                              └─ (origin remote) 本地 clone 在这里开发
```

- `origin` = 你自己的 GitHub fork（二开的库，随便 push）
- `upstream` = 官方仓库（只读，只 fetch + merge）

## 二开工作流（单人简化版）

你的 `master` = 官方代码 + 你的二开改动。**直接在 `master` 上开发**，不搞 feature 分支。

### 1. 平时改代码

```sh
# ...改代码...

git add -A
git commit -m "描述你的改动"
git push origin master
```

### 2. 定期拉官方更新并整合（几天一次）

```sh
./dev/sync-upstream.sh --push
```

内部做的事：`fetch upstream` → `merge upstream/master`（**这就是"把最新代码整合"**）→ 同步子模块 → 推送到你的 fork。

关于 merge 冲突：

- 你改的地方 ≠ 官方改的地方 → git 自动合并，无感（绝大多数情况）
- 你和官方改了同一处 → git 停下提示冲突，手动选保留哪边即可

### 3. 编译并跑模拟器

```sh
./dev/run-simulator.sh            # 编译 + 安装 + 启动
./dev/run-simulator.sh --no-build # 跳过编译，直接用上次产物重装启动
```

改完代码后直接跑 `./dev/run-simulator.sh`，增量编译会快很多。

---

## 脚本说明

| 脚本 | 作用 |
|------|------|
| `dev/run-simulator.sh` | 编译 `debug_sim_arm64`（免签名）+ 装进 iPhone 模拟器 + 启动 |
| `dev/sync-upstream.sh` | 从官方 `upstream` fetch + merge + 同步子模块，可选推送 |
| `dev/setup-fake-profile.sh` | 生成假 provisioning profile 放进 Xcode，让 Xcode ⌘R + 断点调试可用 |

两个脚本都可从仓库任意子目录运行（内部会自动定位到仓库根目录）。

---

## 一次性初始化（新机器 / 重新 clone 时）

首次 clone 你的 fork 后，除了官方 README 的步骤，还有几个 fork 特有的坑要处理：

```sh
# 1. 子模块相对 URL 修复（fork 特有，官方 rlottie/tgcalls 用相对 URL 会解析到你的 fork 而 404）
git config submodule.submodules/rlottie/rlottie.url https://github.com/TelegramMessenger/rlottie.git
git config submodule.submodules/TgVoipWebrtc/tgcalls.url https://github.com/TelegramMessenger/tgcalls.git
git submodule update --init --recursive

# 2. 配置（api_id/api_hash 在 my.telegram.org 申请，team_id 是你 Apple 开发者账号的）
#    复制一份 build-system/bchat-configuration.json，填入你自己的值

# 3. 生成 Xcode 工程（首次会下载 Bazel）
python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir "$HOME/telegram-bazel-cache" generateProject \
  --configurationPath build-system/bchat-configuration.json \
  --xcodeManagedCodesigning

# 4. 首次跑模拟器需要的两个大件（一次即可，之后不用再下）
#    - iOS 模拟器 runtime：xcodebuild -downloadPlatform iOS
#    - Metal Toolchain：    xcodebuild -downloadComponent MetalToolchain

# 5. 生成假 profile（让 Xcode ⌘R + 断点调试可用；不登录付费开发者账号也能跑）
./dev/setup-fake-profile.sh
```

> 注意：Xcode 版本要求见 `versions.json`（当前 Xcode 26.2，Bazel 8.4.2）。版本不符用 `--overrideXcodeVersion` 跳过检查。
>
> 命令行 `Make.py build` 会构建 extensions 而需要真实签名；二开跑模拟器用 `run-simulator.sh`（等价于 `Make.py build` 的底层命令 + 禁用 extensions/签名的 flag），不需要任何签名证书。

---

## 为什么跑模拟器要禁用 extensions 和签名

官方 `Make.py build` 默认构建 Widget/Share/NotificationService 等 app extensions，这些需要 provisioning profile（开发者用私有签名仓库）。二开没有签名仓库，所以用两个 flag 绕过：

- `--//Telegram:disableExtensions` —— 不构建 extensions
- `--//Telegram:disableProvisioningProfiles` —— 模拟器不需要签名

这两个 flag 已写死在 `run-simulator.sh` 里。**只在模拟器上有效**；要出真机包 / App Store 包，仍需 Apple 开发者账号 + 签名配置。

## Xcode ⌘R 调试与假 profile

命令行（`run-simulator.sh`）只构建模拟器版，所以能免签名跑。但 **Xcode 里 ⌘R** 走的是 `rules_xcodeproj` 集成，它会**同时分析真机版和模拟器版**两个 target —— 真机版分析强制要求有 provisioning profile（签名），而你的机器没登录付费开发者账号、没有签名证书，所以 ⌘R 报错。

`setup-fake-profile.sh` 就是解决这个：造一个 `application-identifier = <team_id>.<bundle_id>` 的假 profile 放进 Xcode 的 profile 目录。模拟器实际运行不需要真签名，且 Bazel 分析阶段只解析 profile 的 plist、不验证签名，所以假 profile 能让真机版分析通过 → **Xcode ⌘R + 断点调试都能用**。

> 假 profile 只骗过「分析」这一步；它不能用于真机安装/发布。要出真机包仍需真实开发者账号 + 证书。
