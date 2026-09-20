#!/usr/bin/env bash
# 编译 Telegram 并安装、启动到 iOS 模拟器
#
# 用法:
#   ./dev/run-simulator.sh            # 编译 + 安装 + 启动
#   ./dev/run-simulator.sh --no-build # 跳过编译，直接用上次产物安装启动
#
# 前置: 已生成过配置（build-system/bchat-configuration.json）且子模块已初始化。

set -euo pipefail

# ===== 可配置项 =====
BUNDLE_ID="${BUNDLE_ID:-live.bchat.origin}"   # 与 bchat-configuration.json 的 bundle_id 一致
SIM_NAME="${SIM_NAME:-iPhone 17}"             # 优先使用的模拟器名称
SIM_UUID="${SIM_UUID:-}"                      # 留空则自动查找/创建

# ===== 定位仓库根目录 =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# ===== 编译 =====
if [[ "${1:-}" != "--no-build" ]]; then
    # 自动定位 Make.py 下载的 bazel 二进制
    BAZEL="$(ls build-input/bazel-*-darwin-arm64 2>/dev/null | head -1)"
    if [[ -z "$BAZEL" ]]; then
        echo "错误: 找不到 bazel 二进制（build-input/bazel-*-darwin-arm64）。请先跑一次 generateProject 下载 bazel。" >&2
        exit 1
    fi

    echo "==> 编译 Telegram (debug_sim_arm64, 免签名)..."
    "$BAZEL" build Telegram/Telegram \
        --define=buildNumber=1 \
        --disk_cache="$HOME/telegram-bazel-cache" \
        -c dbg \
        --ios_multi_cpus=sim_arm64 \
        --watchos_cpus=arm64_32 \
        '--@build_bazel_rules_swift//swift:copt=-j' \
        '--@build_bazel_rules_swift//swift:copt=13' \
        --//Telegram:disableExtensions \
        --//Telegram:disableProvisioningProfiles
else
    echo "==> 跳过编译（--no-build）"
fi

# ===== 找到 .app 产物 =====
APP="$(find -L bazel-out -maxdepth 12 -name 'Telegram.app' -type d 2>/dev/null | head -1)"
if [[ -z "$APP" ]] || [[ ! -x "$APP/Telegram" ]]; then
    echo "错误: 找不到构建产物 Telegram.app（$APP）" >&2
    exit 1
fi
echo "==> 产物: $APP"

# ===== 定位模拟器 =====
if [[ -z "$SIM_UUID" ]]; then
    # 优先用已 boot 的，否则找第一个指定名称的可用设备
    SIM_UUID="$(xcrun simctl list devices booted 2>/dev/null | grep -oE '[0-9A-F-]{36}' | head -1)"
    if [[ -z "$SIM_UUID" ]]; then
        SIM_UUID="$(xcrun simctl list devices available 2>/dev/null | grep -E "$SIM_NAME" | grep -oE '[0-9A-F-]{36}' | head -1)"
    fi
    if [[ -z "$SIM_UUID" ]]; then
        echo "错误: 找不到可用的 iPhone 模拟器（名称: $SIM_NAME）" >&2
        exit 1
    fi
fi
echo "==> 模拟器: $SIM_UUID"

# ===== 启动模拟器 =====
xcrun simctl boot "$SIM_UUID" 2>/dev/null || true
open -a Simulator 2>/dev/null || true

# ===== 安装 =====
echo "==> 安装 $BUNDLE_ID ..."
xcrun simctl install "$SIM_UUID" "$APP"

# ===== 启动 =====
echo "==> 启动 $BUNDLE_ID ..."
xcrun simctl launch "$SIM_UUID" "$BUNDLE_ID"

echo "==> 完成"
