#!/usr/bin/env bash
# 从 Telegram 官方源码库拉取最新代码，合并到本地，并（可选）推送到你自己的 fork
#
# 用法:
#   ./dev/sync-upstream.sh          # fetch + merge + 同步子模块，不推送
#   ./dev/sync-upstream.sh --push   # 完成后自动 git push origin master
#
# 前置: 已配置 upstream remote（指向官方）:
#   git remote add upstream https://github.com/TelegramMessenger/Telegram-iOS.git
#
# 说明: 本脚本不修改 .gitmodules；rlottie/tgcalls 两个相对 URL 子模块通过
#       .git/config 的本地覆盖指向官方绝对地址（fork 特有坑，见 dev/README.md）。

set -euo pipefail

UPSTREAM="${UPSTREAM:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
LOCAL_BRANCH="${LOCAL_BRANCH:-master}"

# 定位仓库根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# 0. 前置检查
[[ -d .git ]] || { echo "错误: 请在 Telegram-iOS 仓库根目录运行"; exit 1; }
git remote get-url "$UPSTREAM" >/dev/null 2>&1 || {
    echo "错误: 没有 remote '$UPSTREAM'，先执行:"
    echo "  git remote add upstream https://github.com/TelegramMessenger/Telegram-iOS.git"
    exit 1
}

# 1. 确保工作区干净（否则 merge 会乱）
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "错误: 工作区有未提交的改动，请先 commit 或 stash。"
    exit 1
fi

# 2. 拉官方最新（只更新 remote 引用，不动你的代码）
echo "==> git fetch $UPSTREAM ..."
git fetch "$UPSTREAM"

# 3. 切到本地主分支并合并
git checkout "$LOCAL_BRANCH"
echo "==> 合并 $UPSTREAM/$UPSTREAM_BRANCH 到 $LOCAL_BRANCH ..."
if ! git merge "$UPSTREAM/$UPSTREAM_BRANCH" --no-edit; then
    echo ""
    echo "!! 合并冲突，请手动解决后依次执行:"
    echo "     git add <冲突文件>"
    echo "     git merge --continue"
    echo "     git submodule update --init --recursive"
    exit 1
fi

# 4. 修复相对 URL 子模块：官方用相对 URL（如 ../rlottie.git），fork 会解析到你的
#    命名空间而 404。为所有相对 URL 子模块设置指向官方绝对地址的 .git/config 覆盖。
echo "==> 修复相对 URL 子模块 ..."
upstream_url="$(git remote get-url "$UPSTREAM")"
base_url="$(echo "$upstream_url" | sed 's#\(.*\)/[^/]*$#\1#')"
while IFS= read -r line; do
    path="${line%% *}"
    url="${line#* }"
    if [[ "$url" == ../* ]]; then
        abs_url="${base_url}/${url#../}"
        git config "submodule.${path}.url" "$abs_url"
        echo "    ${path} → ${abs_url}"
    fi
done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.url$' | sed 's/^submodule\.\(.*\)\.url /\1 /')

# 5. 同步子模块：拉官方新增的 + 检出官方记录的 commit（对齐指针漂移）
echo "==> git submodule update --init --recursive ..."
git submodule update --init --recursive

# 6. 检查是否有未初始化/异常的子模块（'-' 开头 = 未初始化，可能是新增的没 clone 成功）
echo "==> 检查子模块状态 ..."
git submodule status 2>/dev/null | grep '^-' && echo "    ↑ 有未初始化子模块，请检查上面的相对 URL 修复是否覆盖到它们" || true

# 7. 推送（默认不推）
if [[ "${1:-}" = "--push" ]]; then
    echo "==> git push origin $LOCAL_BRANCH ..."
    git push origin "$LOCAL_BRANCH"
else
    echo ""
    echo "==> 完成。确认无误后手动推送:"
    echo "     git push origin $LOCAL_BRANCH"
fi
