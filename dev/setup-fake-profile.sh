#!/usr/bin/env bash
# 生成一个「假」provisioning profile 放进 Xcode，让 rules_xcodeproj 的「真机版分析」能通过。
#
# 背景: Xcode 里 ⌘R 时，rules_xcodeproj 会同时分析真机版和模拟器版两个 target，
#       真机版分析要求有 provisioning profile（签名）。模拟器实际运行不需要真签名，
#       而且 Bazel 分析阶段只解析 profile 的 plist、不验证签名，所以造一个匹配
#       bundle_id/team_id 的假 profile 就能骗过真机版分析，让 Xcode ⌘R + 断点都能用。
#
# 用法:
#   ./dev/setup-fake-profile.sh
#
# 前置: build-system/fake-codesigning/ 里有 SelfSigned.p12（官方自带的假签名材料）。
#       本脚本会从中导出证书/私钥，生成匹配当前配置的假 profile。

set -euo pipefail

# ===== 可配置项 =====
BUNDLE_ID="${BUNDLE_ID:-live.bchat.origin}"
TEAM_ID="${TEAM_ID:-GJR676HK27}"
PROFILE_NAME="iOS Team Provisioning Profile: ${BUNDLE_ID}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FAKE_DIR="$REPO_ROOT/build-system/fake-codesigning"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 1. 从官方 fake-codesigning 的 p12 导出证书和私钥（openssl 3 需要 -legacy 读 RC2 加密的 p12）
echo "==> 导出签名证书/私钥 ..."
openssl pkcs12 -in "$FAKE_DIR/certs/SelfSigned.p12" -clcerts -nokeys \
    -out "$WORK/cert.pem" -passin pass: -legacy 2>/dev/null
openssl pkcs12 -in "$FAKE_DIR/certs/SelfSigned.p12" -nocerts \
    -out "$WORK/key.pem" -nodes -passin pass: -legacy 2>/dev/null

# 2. 解出官方假 profile 的 plist，改成我们的 bundle_id/team_id
echo "==> 生成匹配 ${TEAM_ID}.${BUNDLE_ID} 的假 profile plist ..."
openssl smime -inform der -verify -noverify -in "$FAKE_DIR/profiles/Telegram.mobileprovision" \
    -out "$WORK/base.plist" 2>/dev/null

python3 - "$WORK/base.plist" "$WORK/new.plist" "$BUNDLE_ID" "$TEAM_ID" "$PROFILE_NAME" <<'PY'
import plistlib, sys, uuid, datetime

src, dst, bundle_id, team_id, profile_name = sys.argv[1:6]
with open(src, 'rb') as f:
    d = plistlib.load(f)

d['Name'] = profile_name
d['AppIDName'] = bundle_id.split('.')[-1].capitalize()
d['ApplicationIdentifierPrefix'] = [team_id]
d['TeamIdentifier'] = [team_id]
d['TeamName'] = profile_name
d['UUID'] = str(uuid.uuid4()).upper()
d['ExpirationDate'] = datetime.datetime(2030, 1, 1, tzinfo=datetime.timezone.utc)
d['TimeToLive'] = 3650

ent = d['Entitlements']
ent['application-identifier'] = f'{team_id}.{bundle_id}'
# 替换所有残留的官方 bundle_id
OLD = 'ph.telegra.Telegraph'
for k, v in ent.items():
    if isinstance(v, str):
        ent[k] = v.replace(OLD, bundle_id)
    elif isinstance(v, list):
        ent[k] = [x.replace(OLD, bundle_id) if isinstance(x, str) else x for x in v]

with open(dst, 'wb') as f:
    plistlib.dump(d, f)
print(f"  -> Name={d['Name']}, app-id={ent['application-identifier']}, UUID={d['UUID']}")
PY

# 3. 签名成 .mobileprovision
echo "==> 签名生成 .mobileprovision ..."
openssl cms -sign -in "$WORK/new.plist" -signer "$WORK/cert.pem" -inkey "$WORK/key.pem" \
    -outform der -out "$WORK/profile.mobileprovision" -binary -nodetach 2>/dev/null

# 4. 安装到 Xcode 的两个 provisioning profiles 目录
UUID="$(python3 -c "import plistlib,sys; d=plistlib.load(open('$WORK/new.plist','rb')); print(d['UUID'])")"
SYSTEM_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
USER_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$SYSTEM_DIR" "$USER_DIR"
cp "$WORK/profile.mobileprovision" "$SYSTEM_DIR/$UUID.mobileprovision"
cp "$WORK/profile.mobileprovision" "$USER_DIR/$UUID.mobileprovision"

echo "==> 完成。假 profile 已安装为 $UUID.mobileprovision"
echo "    现在可以在 Xcode 里 ⌘R 了（真机版分析会用这个假 profile 通过）。"
