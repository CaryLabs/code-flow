#!/usr/bin/env bash
# install-workbuddy.sh — 在 Windows/Git Bash 上把本仓库的 skill 与全局规则安装到 WorkBuddy。
#
# 与上游 install.sh 的分工：
#   上游 install.sh 面向 macOS，安装 Codex/Claude Code 的 skill、zsh launcher 和 launchd 服务。
#   本脚本面向 WorkBuddy 桌面端，只安装 WorkBuddy 实际读取的两处：
#     - 用户级 skill:  $WORKBUDDY_SKILLS_DIR （默认 ~/.workbuddy/skills）
#     - 用户级规则:    $WORKBUDDY_RULES_DIR  （默认 ~/.workbuddy/rules）
#
# 用法:
#   bash scripts/install-workbuddy.sh            # 安装 skill + 规则
#   bash scripts/install-workbuddy.sh --skills   # 只同步 skill
#   bash scripts/install-workbuddy.sh --rules    # 只写规则
#
# 说明:
#   - 本仓库是 skill 真源；用户级目录只是安装目标，不在用户目录直接编辑。
#   - 同步前会备份现有 skill 到 ~/.workbuddy/skills/.backup-<日期>/。
#   - 规则文件带 alwaysApply: true，对所有 WorkBuddy 项目生效。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

skills_dir="${WORKBUDDY_SKILLS_DIR:-$HOME/.workbuddy/skills}"
rules_dir="${WORKBUDDY_RULES_DIR:-$HOME/.workbuddy/rules}"
rule_file="$rules_dir/code-flow.md"
backup_dir="$skills_dir/.backup-$(date +%Y%m%d-%H%M%S)"

# 只有纯 Markdown 指令的 skill 才能在 Windows 通用；依赖 zsh/tmux 的不在此列。
portable_skills=(deepreview gateflow phaseflow planreview)

install_skills=true
install_rules=true
case "${1:-}" in
  --skills) install_rules=false; shift ;;
  --rules) install_skills=false; shift ;;
  --help|-h)
    echo 'Usage: bash scripts/install-workbuddy.sh [--skills|--rules]'
    echo 'Installs code-flow skills and the global rule into the WorkBuddy user config dir.'
    exit 0 ;;
esac
[[ $# == 0 ]] || { echo "install-workbuddy.sh: unknown arguments: $*" >&2; exit 1; }

echo "==> repo:      $repo_root"
echo "==> skills dir: $skills_dir"
echo "==> rules dir:  $rules_dir"

# --- 1. 同步 skill -----------------------------------------------------------
if [[ "$install_skills" == true ]]; then
  mkdir -p "$skills_dir"

  # 备份现有同名 skill（仅在存在时备份，避免产生空备份目录）
  existing=()
  for s in "${portable_skills[@]}"; do
    [[ -d "$skills_dir/$s" ]] && existing+=("$s")
  done
  if [[ ${#existing[@]} -gt 0 ]]; then
    mkdir -p "$backup_dir"
    for s in "${existing[@]}"; do
      cp -r "$skills_dir/$s" "$backup_dir/$s"
      echo "    备份: $s -> $backup_dir/$s"
    done
  fi

  for s in "${portable_skills[@]}"; do
    src="$repo_root/skills/$s"
    [[ -d "$src" ]] || { echo "    跳过（仓库中不存在）: $s" >&2; continue; }
    # 先删后拷：目标存在时 cp -r 会嵌套成 dst/src/，留下旧顶层文件。
    rm -rf "${skills_dir:?}/$s"
    cp -r "$src" "$skills_dir/$s"
    # 逐字节校验，确保安装结果与真源一致
    if diff -r "$skills_dir/$s" "$src" >/dev/null 2>&1; then
      echo "    ✓ 已同步: $s"
    else
      echo "    ✗ 校验失败: $s" >&2
      exit 1
    fi
  done

  if [[ ${#existing[@]} -gt 0 ]]; then
    echo "==> 旧版本备份于: $backup_dir"
  fi
fi

# --- 2. 写全局规则 -----------------------------------------------------------
if [[ "$install_rules" == true ]]; then
  mkdir -p "$rules_dir"
  src_rule="$repo_root/scripts/code-flow-rule.md"
  if [[ -f "$src_rule" ]]; then
    # 把模板占位符替换为当前机器的仓库路径，规则模板本身不保存机器相关路径。
    rule_root="$repo_root"
    if command -v cygpath >/dev/null 2>&1; then
      rule_root="$(cygpath -m "$repo_root")"
    fi
    escaped_rule_root="$(printf '%s' "$rule_root" | sed 's/[&|]/\\&/g')"
    sed "s|{{CODE_FLOW_ROOT}}|$escaped_rule_root|g" "$src_rule" > "$rule_file"
    if grep -Fq '{{CODE_FLOW_ROOT}}' "$rule_file" || ! grep -Fq "$rule_root" "$rule_file"; then
      echo "    ✗ 规则渲染失败: 未正确写入当前仓库路径" >&2
      exit 1
    fi
    echo "==> ✓ 规则已安装: $rule_file"
  else
    echo "    ✗ 规则模板不存在: $src_rule" >&2
    exit 1
  fi
fi

echo ""
echo "==> 完成。"
echo "    生效方式：WorkBuddy 启动新会话时自动加载。"
echo "    验证：设置 > 技能 / 规则，或在会话中询问 code-flow 规则是否已加载。"
