#!/usr/bin/env bash
# sync-upstream.sh — 同步上游(upstream)最新提交到本地 main，并推送到你的 fork(origin)。
# 安全保证：绝不回推上游（upstream 的 push 地址强制为 no_push）。
#
# 用法：
#   ./scripts/sync-upstream.sh            # 同步默认分支 main
#   ./scripts/sync-upstream.sh <branch>   # 同步指定分支
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

upstream_remote="upstream"
default_branch="main"
branch="${1:-$default_branch}"

# 1. 确保 upstream 已配置
if ! git remote get-url "$upstream_remote" >/dev/null 2>&1; then
  echo "错误：未找到上游 remote '$upstream_remote'。" >&2
  echo "请先执行：" >&2
  echo "  git remote add $upstream_remote <原仓库URL>" >&2
  echo "例如：" >&2
  echo "  git remote add $upstream_remote git@github.com:noho/code-is-cheap.git" >&2
  exit 1
fi

# 2. 防误推保护：upstream 的 push 地址强制为 no_push
push_url="$(git remote get-url --push "$upstream_remote" 2>/dev/null || true)"
if [[ "$push_url" != "no_push" ]]; then
  echo "==> 保护：将 $upstream_remote 的 push 地址设为 no_push（杜绝误推原仓库）"
  git remote set-url --push "$upstream_remote" no_push
fi

# 3. 拉取上游
echo "==> 拉取 $upstream_remote ..."
git fetch "$upstream_remote"

# 4. 切换目标分支并合并
echo "==> 切换到 $branch"
git checkout "$branch"

if git merge --ff-only "$upstream_remote/$branch"; then
  echo "==> 快进合并成功（无分叉）"
else
  echo "==> 存在分叉，回退为普通 merge（有冲突请手动解决）"
  git merge "$upstream_remote/$branch"
fi

# 5. 推送到 fork（origin），绝不推 upstream
echo "==> 推送到 fork：origin/$branch"
git push origin "$branch"

echo "完成：$branch 已同步上游并推送至 origin（上游原仓库未受影响）。"
