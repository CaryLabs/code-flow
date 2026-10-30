---
alwaysApply: true
---

# 代码开发流程（code-flow）

本规则对所有 WorkBuddy 项目生效。凡是涉及**代码编写、重构、修复、迁移、schema/公共契约变更、架构调整**的任务，必须遵循 code-flow 流程，不要用「直接改完就交付」的方式推进。

## 流程真源

仓库：`D:/Workspace/WorkBuddy/code-flow`（fork of `noho/code-is-cheap`）

已安装到用户级 skill 目录 `C:/Users/carys/.workbuddy/skills/`，对所有项目自动可用：

| Skill | 职责 |
| --- | --- |
| `gateflow` | 单个 work unit 的 gated 流程：goal confirmation → plan → implementation/validation → code review → draft PR → final closeout |
| `phaseflow` | 项目分步总控：读取 design_doc + control_doc，按 gate 顺序推进 phase/work unit，裁决 findings，更新 control_doc |
| `planreview` | 对重要契约/架构/迁移/状态机决策做 adversarial plan review |
| `deepreview` | 对当前改动、指定 PR 或全仓做严格深度 code review，产出 `docs/reviews/` artifact |

## 何时用哪个

- **单个可交付单元**（feature / bug fix / refactor / migration / 契约变更）→ 用 `$gateflow`。
- **多阶段项目**，已有设计真源和总控文档 → 用 `$phaseflow design_doc=... control_doc=...`。
- 重要契约、架构、迁移、状态机决策 → 在 implementation 前执行 `$planreview`。
- 需要一轮完整严格代码审核（当前改动 / PR / 全仓）→ 执行 `$deepreview`。

若任务只是纯咨询、纯文档撰写、纯资料检索、数据分析，且不改动代码，不强制走 gate 流程。

## 新项目初始化

新项目开工前先生成骨架，避免目录和真源文档临到用时才补：

```bash
bash D:/Workspace/WorkBuddy/code-flow/scripts/init-code-flow.sh <project-dir> [project-name]
```

会创建 `docs/{plans,reviews,closeouts,implementation,work-units}/`、设计真源 `docs/design.md`、总控真源 `docs/implementation-control.md` 和项目级 `AGENTS.md`。脚本幂等，只补缺失项，不覆盖已有文件。

## 强制约束

1. **先确认目标再动手**：进入实现前，用通俗语言向用户复述目标、非目标、scope boundary、成功信号，得到确认后再推进。目标、验收标准、公共契约、兼容性承诺发生变化时，必须重新确认，不得自行扩大范围。
2. **计划要够用即可**：计划达到能指导正确实现即可，不为假想需求引入框架、抽象或基础设施。简单计划由总控自行核对，不额外派发 plan review。
3. **范围外不顺手改**：只修改完成当前任务所必需的代码。发现无关死代码、坏味道或潜在问题时只做说明，不主动删除或重构。
4. **改动后必须验证**：优先用现有测试、构建、类型检查或最小复现验证。无法验证时明确说明原因并给出建议验证步骤，不在无验证依据的情况下宣称问题已解决。
5. **留可追踪记录**：在 `docs/plans/`、`docs/reviews/`、`docs/closeouts/`、`docs/implementation/` 下留下 artifact。artifact 文件名带本机系统时钟生成的 timestamp（`date +%Y%m%d-%H%M%S`），不要手写或用计数器。
6. **风险动作先确认**：merge、发布、对外发送、删除数据、修改账号与权限、创建或修改外部 issue/PR，必须取得用户明确授权。
7. **不猜**：缺少必要输入、授权或依赖时，报告具体缺项，不要猜测或自行扩大权限。

## Windows 环境约束

本机是 Windows + Git Bash，缺少上游依赖的 `zsh`、`tmux`、`jq`、`rsync`，且 `claude` CLI 未安装。因此：

- **子 Agent 派发通道**：使用 WorkBuddy 原生的 Agent 能力派发（`Agent` 工具指定 `subagent_type`、`mode` 与明确的 `cwd`），不要试图调用上游 `codex-agent-run` / `claude-agent-run`（zsh 脚本，无法在本机执行）。派发时必须显式给出 workspace 绝对路径，子 Agent 不继承当前对话上下文，需要自洽的交接信息。
- **并行派发**：需要两路独立审核时，用两个 `Agent` 调用并行执行，写入互不重叠的文件范围。
- **无 tmux**：不存在 tmux pane 通信协议，不要使用 `tmux-agents`。
- **无 jq**：解析 JSON 优先用 Python（`python3 -c`）或 `gh --jq`；`gh` CLI 已认证可用。
- **时间戳**：用 `date +%Y%m%d-%H%M%S`（Git Bash 可用）。
- **`gh` 已认证**，PR 相关操作直接用 `gh`。
- `codex` CLI 已安装但当前网络代理阻断 chatgpt.com，作为外部运行时不可依赖；不要把它当作可用的派发通道。

## 与上游 skill 的关系

本仓库是 skill 与本规则的唯一真源，用户级目录只是安装目标。更新流程：

```bash
cd D:/Workspace/WorkBuddy/code-flow && git pull
bash scripts/install-workbuddy.sh
```

安装脚本会备份现有 skill 到 `~/.workbuddy/skills/.backup-<日期时间>/`、同步 4 个 skill 并逐字节校验、写入本规则。
只同步 skill 用 `--skills`，只写规则用 `--rules`。

若上游 `sub-agents` / `tmux-agents` 未来提供 Windows 可用的 runner，再评估接入；在此之前用 WorkBuddy 原生 Agent 派发。
