# Candidate Requirement Block 模板

本模板与 `agent-spec requirements import` 的 marker 格式兼容，复制「填好的完整示例块」或「空骨架块」后按需替换占位内容。使用前请通读以下使用说明，它们是本模板与门禁（`references/cli-gates.md`）之间的接口约定，不是可选的风格建议。

## 使用说明

- **marker**：块必须以起始 marker 开头、以结束 marker 收尾——具体语法见下方「填好的完整示例块」的首行与末行，起始 marker 携带 `id`/`title`/`tags`/`source` 四个属性；两个 marker 缺一即被门 1（`requirements import`）判为结构不可解析（此说明本身刻意不重复贴出完整 marker 语法，防止本文件里出现第二处可被机械抽取工具误认作独立块起点的文本）。
- **id 命名**：`REQ-<行为面>-<断言>`，全大写、连字符分隔，例如 `REQ-FETCH-JSON-MODE`。同一行为面下的多条断言用不同的 `<断言>` 段区分，不要用序号占位。
- **tags**：至少携带一个行为面类别标签（如 `cli`）；对等重写分流下必须再携带 parity class 标签之一：`parity-contractual` / `parity-incidental-relied` / `parity-incidental`（与 `SKILL.md`「契约还是偶然」一节三值逐字一致）。重设计分流不激活 parity 分类，不出现 parity 标签。
- **source**：指向本次重建的行为面×证据源矩阵文件（通常是 `docs/reconstruction/behavior-surface-matrix.md`），不是指向上游仓库——上游出处走 `## Source Trace`。
- **必备节，缺一不可**：`## Problem` / `## Requirements` / `## Scenarios` / `## Dependencies` / `## Source Trace` / `## Open Questions`，顺序与下方示例一致。门 2（`lint-knowledge --gate`）对缺失必备节判 Error。
- **`## Requirements` 条款**：`[REQ-<id 同上>] <EARS 句式条款>`，modality（MUST/SHOULD/MAY）按 `SKILL.md`「Modality 映射表」推导，不凭手感选。
- **`## Scenarios`**：`场景:` 起头一行给场景名，步骤用中文关键词`假设`/`当`/`那么`/`并且`（Given/When/Then/And 语义，本机 `agent-spec requirements graph` 实测可正确解析这组中文关键词，见下方示例）；断言必须是可观察行为（stdout/stderr/退出码/持久化外部效果），不得断言内部状态。对等重写分流下，parity 维度组合（命令×输出模式、本地×远程、冷×热、成功×部分失败×硬失败）要落进具体场景的前提与断言里，不能只在 `## Problem` 里提一句自然语言描述（见 `references/cli-gates.md`「交接要求」第 1 点）。
- **confidence 的字段落点**：`confidence: high|medium|low` 写在 `## Source Trace` 节的**末行**，不单独占一个 `##` 小节——`requirements import` 只按 marker 与既定的六个必备节解析结构，独立的 `## Confidence` 小节不在其识别范围内，会被判为结构外内容。confidence 取值按 `references/evidence-classes.md`「证据类别组合与 confidence 推导表」机械查表，不凭手感在 medium/high 之间挑一个更好看的值。
- **`## Source Trace` 条目格式**：`<upstream>@<baseline>:<file>:<line>`，前缀带三级标注（【事实】/【推断】/【缺口】）与证据类别组合（`test+code+doc` / `test+code` / `code+doc` / `code-only` / `doc-only` 等，写法与 `evidence-classes.md` 逐字一致）。
- **`None.`**：仅在该节确实无内容时使用（例如某条需求确无依赖、确无未决问题）；只要有一条真实内容，就不得用 `None.` 顶替。

## 填好的完整示例块

以下示例块已实测通过本机 `agent-spec 1.1.0` 的 `requirements import` + `lint-knowledge --gate` + `requirements graph --gate`（三条命令见 `references/cli-gates.md`「门禁序列」），可直接照此格式复制填写：

```md
<!-- agent-spec:requirement id=REQ-FETCH-JSON-MODE title="fetch --json 输出契约" tags=cli,parity-contractual source=docs/reconstruction/behavior-surface-matrix.md -->
## Problem

上游 CLI 的 `--json` 模式被文档承诺且有 e2e 测试锁定，属对等重写必须保留的输出契约。
动机出处【事实】：upstream@v1.2.0:README.md:120「machine-readable output for scripting」。

## Requirements

[REQ-FETCH-JSON-MODE] When `--json` is supplied, the fetch command MUST write only a JSON document to stdout and MUST route diagnostics to stderr.

## Scenarios

场景: json 模式 stdout 仅含 JSON
  假设 一个可用的远端源
  当 用户运行 `fetch --json`
  那么 stdout 是单个合法 JSON 文档
  并且 诊断信息只出现在 stderr

## Dependencies

None.

## Source Trace

- 【事实】[test+code+doc] upstream@v1.2.0:tests/e2e/fetch.rs:88 断言 stdout 可解析为 JSON
- 【事实】[doc] upstream@v1.2.0:README.md:118-124 承诺 machine-readable 输出
- 【事实】[code] upstream@v1.2.0:src/cmd/fetch.rs:41 serde_json::to_writer(stdout)
- confidence: high（test+code+doc 三源一致）

## Open Questions

None.
<!-- /agent-spec:requirement -->
```

## 空骨架块

起止两行的 marker 语法与上方示例块完全一致，只需替换 `id`/`title`/`tags`/`source` 四个属性值（此处不重复贴出这两行，理由同「使用说明」的 marker 条）；下列骨架只展示六个必备节的占位内容，复制时把上方示例块的起止两行接到骨架前后：

```md
## Problem

<这条需求要解决/锁定什么；动机陈述必须附出处，无出处写【缺口】>

## Requirements

[REQ-<行为面>-<断言>] <EARS 句式条款，modality 按 SKILL.md 映射表推导>

## Scenarios

场景: <场景名>
  假设 <前置条件>
  当 <触发动作>
  那么 <可观察断言>
  并且 <可选附加断言>

## Dependencies

<依赖的其他 REQ id 列表，或 None.>

## Source Trace

- 【事实|推断|缺口】[<证据类别组合>] <upstream>@<baseline>:<file>:<line> <断言内容>
- confidence: <high|medium|low>（<推导依据，按 evidence-classes.md 组合表>）

## Open Questions

<未决问题列表，或 None.>
```
