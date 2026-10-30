# Design: 跨公司模型 Code Review 约束（v2）

本文档是「跨公司模型 code review」在**上游新架构（provider 体系）**上的设计真源（design_doc），用于裁决目标、边界、契约、非目标和 review finding。

## 背景与动机

上游（noho/code-is-cheap）已把多 Agent 编排重构为 provider 体系：

- `codex-agent/model-providers.toml`：共享 provider registry（deepseek / glm / kimi / mimo / qwen / local…）。
- `codex-agent/profiles/*`：各 provider 的 profile 配置（含 gpt-6-astra / gpt-6-sol / gpt-6-luna 等订阅型 provider）。
- `codex-agent/catalog-sources/*.json`：官方模型目录。
- `skills/sub-agents`：runner 派发的 Providers 表。

provider 命名本身已隐含公司（deepseek=深度求索、glm=智谱、kimi=月之暗面、mimo=小米、qwen=阿里、hy=腾讯混元、gpt-6-*=OpenAI）。

但 review gate 的派发**没有「review 与 implementation 不同公司」的约束**：phaseflow 第 131 行只规定「用户指定 provider 就按用户指定，未指定时按 gate 选择」，gateflow 第 174 行只要求「保留双路并行、每位 reviewer 独立审查」，均未禁止 review 落回与 implementation 同一家公司的模型，仍存在自评审偏差。

## 目标

1. 在 review gate 派发固化硬约束：review 所用 provider 的公司必须与 implementation 所用 provider 的公司不同。
2. 提供 provider → 公司归组的明确依据，供总控在派发时校验。

## 非目标（本轮不做）

- 不改变 provider 体系本身：不改 `model-providers.toml`、`profiles/`、`catalog-sources/`、`shim-routes.json`。
- 不改变 `sub-agents` / `tmux-agents` 的派发协议（tmux vs runner 选择）。
- 不写死默认 provider，不自动选择 review provider，不引入 provider 权重/评分/多路投票。
- 不引入新配置格式，不新增 skill。

## Scope Boundary

仅改 2 个 `SKILL.md`：

| 文件 | 改动 |
| --- | --- |
| `skills/phaseflow/SKILL.md` | 在「Agent/provider 选择」处新增跨公司 review 约束 + provider→公司归组 |
| `skills/gateflow/SKILL.md` | 在 review / fix / re-review 组新增跨公司派发约束 |

## 架构决策

### D1：公司归组按 provider 名称归组

provider 命名已隐含公司，故不新增配置文件，直接用「名称 → 公司」归组表（见下契约）。同公司的多档 provider（如 `glm` 与 `glm-flash`）视为同公司。

### D2：约束落在两个编排层

- `phaseflow`（总控派发）：review gate 派发前校验跨公司，违反则停下让用户改选。
- `gateflow`（review 规则）：review / fix / re-review 组写入同一约束，单 work unit 场景同样生效。

### D3：implementation 用户自定义 + review 手动选择 + 跨公司校验

- implementation / plan 的 provider 由用户指定（`control_doc` 记录，或派发时指定）。
- review 的 provider 由用户在每个 review gate 手动选择；总控校验其公司与 implementation 不同，相同则停下。

## 契约：provider → 公司 归组

| 公司 | provider |
| --- | --- |
| DeepSeek（深度求索） | `deepseek`、`ds-flash` |
| 智谱（Zhipu） | `glm`、`glm-flash`、`glm_flash` |
| 月之暗面（Moonshot） | `kimi` |
| 小米（MiMo） | `mimo`、`mimo-fast`、`mimo-flash`、`mimo_fast`、`mimo_flash` |
| 阿里（Alibaba） | `qwen` |
| 腾讯（Tencent） | `hy`（hunyuan，仅 Claude runtime） |
| OpenAI | `gpt-6-astra`、`gpt-6-sol`、`gpt-6-luna` 及各自 `-x` / `-max` 档、`business` |
| 本地（Local） | `local`、`local_llama` |

同公司多档 provider（如 `glm` 与 `glm-flash`、`mimo` 与 `mimo-fast`）不得互相评审。若上游新增 provider，须同步更新本表（见 Residual Risk）。

## 成功信号

1. `phaseflow` 含 provider → 公司归组与跨公司 review 硬约束，派发前校验顺序明确。
2. `gateflow` 的 review / fix / re-review 组含跨公司约束。
3. 两个 `SKILL.md` 通过 `scripts/validate-skills.sh` 校验。
4. review 派发时，总控能据归组表列出「与 implementation 不同公司」的可选 provider。
