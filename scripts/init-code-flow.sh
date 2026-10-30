#!/usr/bin/env bash
# init-code-flow.sh — 为新项目初始化 code-flow 目录骨架与模板。
#
# 用法：
#   bash init-code-flow.sh <project-dir> [project-name]
#
# 行为：
#   - 创建 docs/ 下的 artifact 目录（plans/reviews/closeouts/implementation/work-units）
#   - 生成 docs/design.md（设计真源模板）
#   - 生成 docs/implementation-control.md（总控真源模板）
#   - 生成 AGENTS.md（项目级 code-flow 约束）
#   - 已有文件一律不覆盖，只补缺失项
set -euo pipefail

target_dir="${1:-}"
project_name="${2:-}"

if [[ -z "$target_dir" ]]; then
  echo "用法: bash init-code-flow.sh <project-dir> [project-name]" >&2
  exit 1
fi

if [[ ! -d "$target_dir" ]]; then
  echo "错误: 目录不存在: $target_dir" >&2
  exit 1
fi

root="$(cd "$target_dir" && pwd)"
if [[ -z "$project_name" ]]; then
  project_name="$(basename "$root")"
fi

echo "==> 初始化 code-flow 骨架: $root (project: $project_name)"

mkdir -p "$root/docs/plans" \
         "$root/docs/reviews" \
         "$root/docs/closeouts" \
         "$root/docs/implementation" \
         "$root/docs/work-units"

created=0

write_if_absent() {
  local path="$1"
  shift
  if [[ -e "$path" ]]; then
    echo "  跳过（已存在）: ${path#$root/}"
    return
  fi
  cat > "$path"
  echo "  创建: ${path#$root/}"
  created=$((created + 1))
}

write_if_absent "$root/docs/design.md" <<EOF
# 设计真源: $project_name

> 本文件是项目的设计真源。Gateflow / Phaseflow 用它裁决目标、边界、架构、契约、非目标和 review finding。
> 随需求演进更新，不要在这里写实现步骤或进度记录。

## 目标

<!-- 这个项目要达成什么。用一句话说清可验证的结果。 -->

## 动机

<!-- 为什么值得做。不做会怎样。 -->

## 非目标

<!-- 明确不做什么，防止范围蔓延。 -->

## 成功信号

<!-- 可验证的完成信号：测试、构建、指标、行为。 -->

## 架构与契约

<!-- 关键模块边界、公共 API / schema / 数据契约、兼容性承诺。 -->

## 约束

<!-- 技术栈、依赖、平台、合规、性能等硬约束。 -->

## 开放问题

<!-- 阻塞性问题写这里；非阻塞项可记为 residual risk。 -->
EOF

write_if_absent "$root/docs/implementation-control.md" <<EOF
# 实施总控: $project_name

> 本文件是总控真源。Phaseflow 用它读取当前 phase/work unit、状态、artifact、commit/PR 信息、
> residual risks 和 next entry point。设计裁决以 \`docs/design.md\` 为准。

## 当前状态

- Phase / Work unit: <!-- 填写 -->
- 类型: <!-- feature | issue | bug fix | 其他 -->
- Current gate: <!-- goal confirmation -->
- Next entry point: <!-- goal confirmation -->

## Phases

| ID | 名称 | 类型 | 状态 | 验收信号 |
| --- | --- | --- | --- | --- |
| 1 | <!-- 填写 --> | feature | pending | <!-- 填写 --> |

## Slice 切分原则

<!--
可留空。留空时不得编造固定 slice 数量或阈值，只按 Gateflow 的 plan / slice gate 要求执行。
填写时，plan 必须说明 slice 数量与切分依据，并说明是否符合此原则。
-->

<!--
### Slice 原则

- 单个 slice 的建议上限：N 个文件 / M 行
- 何时必须拆分：依赖关系、review 风险、验证成本
-->

## Artifacts

<!--
按 gate 记录实际 artifact 路径与版本。文件名带系统时钟 timestamp（date +%Y%m%d-%H%M%S）。
目录约定：docs/plans/、docs/reviews/、docs/implementation/、docs/closeouts/、docs/work-units/
-->

## Residual Risks

<!-- 每项必须有 owner 和 destination；没有 owner 的风险不能关闭 work unit。 -->

| 风险 | Owner | Destination |
| --- | --- | --- |
| <!-- 填写 --> | <!-- 填写 --> | <!-- 填写 --> |

## 交付记录

| Gate | 结果 | Artifact | Commit / PR |
| --- | --- | --- | --- |
| <!-- 填写 --> | <!-- 填写 --> | <!-- 填写 --> | <!-- 填写 --> |
EOF

write_if_absent "$root/AGENTS.md" <<EOF
# $project_name — 项目开发约束

本项目遵循 code-flow 流程。用户级规则 \`~/.workbuddy/rules/code-flow.md\` 已全局生效，本文件只补充项目特有约束。

## 流程入口

- 单个可交付单元：\$gateflow
- 多阶段项目：\$phaseflow design_doc=docs/design.md control_doc=docs/implementation-control.md
- 重要决策审核：\$planreview
- 完整代码审核：\$deepreview

## 项目命令

<!-- 填入构建、测试、类型检查、lint 命令，供 gate 验证使用。 -->

- 安装依赖:
- 构建:
- 测试:
- 类型检查:
- Lint:

## 目录结构

<!-- 简要说明各目录职责。 -->

## 项目特有约定

<!-- 只写与全局规则不同或补充的部分。 -->
EOF

echo ""
echo "==> 完成。新增 $created 个文件。"
echo "    下一步：填写 docs/design.md（设计真源）与 docs/implementation-control.md（总控真源），"
echo "          然后用 \$phaseflow 启动第一个 work unit。"
