# Implementation Control: 跨公司模型 Code Review 约束（v2）

本文档是「跨公司模型 code review（v2）」work unit 的实施总控真源（control_doc）。

## 仓库与分支

- 仓库：`CaryLabs/code-flow`（fork 自 `noho/code-is-cheap`，已同步上游）
- 本地路径：`E:/Codex/code-flow`
- 分支：`feat/cross-provider-review-v2`（from `main` @ `2cb3127`）
- design_doc：`docs/design.md`
- control_doc：`docs/implementation-control.md`（本文档）

## Work Unit

- 类型：feature（流程约束增强）
- 名称：cross-provider-review-v2（基于上游 provider 体系的跨公司 review 约束）
- 动机：上游已引入 provider 体系但无跨公司 review 约束，消除自评审偏差，见 `docs/design.md`。

## Model Routing 约定

- `implementation_model`：用户自定义，默认 `ds-flash`（DeepSeek），派发时可按需改。
- `review_model`：每个 review gate 由用户手动选择，须与 implementation 不同公司（归组见 `docs/design.md` 契约表）。

## Implementation Slice

按上游 Gateflow「默认一个 slice」原则，本次改造为一个 slice：同一语义（跨公司 review 约束）在两个 skill 的落地。

### Slice 1 — 跨公司 review 约束

- 文件：`skills/phaseflow/SKILL.md`、`skills/gateflow/SKILL.md`
- 改动：
  - `phaseflow`：在「Agent/provider 选择与派发协议」段落后新增跨公司 review 约束 + provider → 公司归组表；派发 review gate 前校验，违反则停下。
  - `gateflow`：在 `review / fix / re-review` 组（「保留要求的双路并行」附近）新增跨公司派发约束，引用 phaseflow 归组表。
- 验证：`scripts/validate-skills.sh` 通过；人工确认归组表与 `docs/design.md` 契约一致、且未改动 provider 体系与派发协议。
- 非目标：不改 `model-providers.toml`、`profiles/`、`catalog-sources/`、`sub-agents`、`tmux-agents`，不改 Gate Order / Gate State Machine / draft PR / final closeout 等既有逻辑。

## Gate Order（引用 gateflow，v2 版）

```
goal confirmation
-> plan（总控核对；重要决策 plan review）
-> implementation / validation
-> code review（一轮完整 deepreview）
-> [fix -> 受影响面 re-review]
-> ready-to-open-draft-PR
-> 必要提交 / push
-> create draft PR
-> 总控交付核对
-> draft-PR-pass
-> final closeout
```

## 当前 Gate / Next Entry Point

- 当前状态：design_doc 与 control_doc 已就绪，goal confirmation 待确认。
- next entry point：`goal confirmation` → 确认后进入 `plan`（简单计划由总控核对）。

## 验证要求

- 命令：`./scripts/validate-skills.sh`（本机已装 PyYAML 6.0.3，校验器已就位）。
- 预期：全部 skill `Skill is valid!`，exit code 0。

## Artifacts 路径

- plan / 核对记录：可并入 `docs/implementation-control.md` 或 `docs/plans/`。
- code review：`docs/reviews/code-review-<ts>.md`。

## Residual Risks

- 公司归组表以 provider 名称为准；上游新增 provider 时须同步更新 `phaseflow` 归组表（owner：后续 work unit）。
- `hy` 仅 Claude runtime；Codex 侧无 hy，跨公司校验时不影响（仍归腾讯）。
- 本机为单 Agent 环境，跨公司 review gate 的「不同公司」校验需在多 Agent（sub-agents / tmux-agents）环境实际生效。

## Next Entry Point（final closeout 后）

用户 merge 后，从 `main` 拉取；若上游再更新 provider 体系，同步维护归组表。
