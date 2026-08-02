---
name: requirements-reconstruction
description: 从既有开源项目/代码库的源码、测试与文档重建结构化需求（agent-spec KLL Candidate Requirement Blocks），测试/代码/文档三源对照，每条断言附证据与置信度，缺口显式声明而不是编造；经 agent-spec 确定性门禁与人工治理后，作为重写工作的受治理真相层。当用户要对等重写/移植/换语言重实现一个既有项目、要从源码提炼需求或「重建 spec」、要做行为对等（parity）分析、要给既有系统补需求文档、问「这个项目到底承诺了什么行为」「重写时哪些行为必须保留」时，都应当使用本 skill——即使用户没说出「需求重建」「KLL」「agent-spec」这些词。不适用于：为尚不存在的系统做正向需求分析（用 agent-spec-intent-compiler）；重建架构描述（用 architecture-reconstruction）；重建用例模型（用 usecase-reconstruction）。
---

# 需求重建（Requirements Reconstruction）

## 这件事的本质

代码里没有「需求」这个现成的东西，只有**行为证据**，且三类证据源回答的问题不同：

| 证据源 | 回答的问题 | 认知地位 |
|---|---|---|
| 测试 | 被**有意锁定**的行为 | 最接近「意图」的证据——有人特意写下了断言 |
| 代码 | **实际**行为 | 含大量没人有意选择的偶然行为 |
| 文档 | **宣称**的行为 | 对外承诺，但可能已漂移 |

需求重建 = 三源对照 + 认知地位标注。**三源两两冲突不是噪声，是一等发现**（见「尖锐发现清单」）。

产出不是给人读的分析报告，而是机器可导入的受治理需求：Candidate Requirement Blocks 进 agent-spec 的 KLL 层，过确定性门禁、经人工治理 accept 之后，才成为重写工作的真相层。所以每条断言都要经得起机械检查，不能只在 prose 里说得通。

**不做什么**：

- 不为尚不存在的系统做正向需求分析——走 `agent-spec-intent-compiler` 的 PRD 正向路径
- 不重建架构描述——走 `architecture-reconstruction`
- 不重建用例模型——走 `usecase-reconstruction`

也不起草 Task Contract（交给 `requirements draft-specs` + `agent-spec-authoring`，本 skill 只规定交接要求），不承诺产出即合规的 ISO 29148 SRS（29148 用作质量判据，不声明一致性）。

**协同（可选，非依赖）**：三个重建型 skill 相互独立，只共享证据层。重写大项目的典型顺序是先跑 `architecture-reconstruction` 摸清结构、决定切分；`usecase-reconstruction` 的用例清单可作本 skill 需求文档的聚类参考，其尖锐发现 #1（宣称但不存在）/ #2（存在但无人知晓）可直接并入三源对照，不必重复取证；取证脚本三者可共享。

## 三个最危险失败模式

1. **把偶然当契约（过度规格化）**：把实现事故写成 MUST——枚举顺序、错误消息措辞、未文档化格式细节、乃至 bug。后果是重写被无意义约束绑死，甚至把 bug 复制进新实现。Hyrum's Law 是现实修正：偶然行为可能确实有人依赖，处置不是删掉，而是标明「偶然 + 依赖证据」，不许伪装成设计意图。
2. **漏掉静默契约（欠规格化）**：调用方实际依赖、但 doc 没写 test 没锁的行为——默认值、退出码、错误时的部分输出、顺序稳定性。重写后静默破坏、无红灯。这是对等重写最大的风险源，也是本 skill 相对 `agent-spec discover --from-codebase` 的核心增量。
3. **编造意图**：rationale 原理上不可恢复。`## Problem` 一节最易犯——从条款反着编动机。没有出处就写【缺口】。

**前两个是一对对偶：必须同时防两个方向，只防一个会把产出推向另一个。** 落到动作上：每要写下一条 MUST，先问「有谁有意锁定过它」；每觉得「这个面盘完了」，先问「调用方能观察到、却没人写下来的还剩什么」。

## 证据纪律

沿用三级标注，且必须落到 Candidate Requirement Block 的既有字段——标注不是文风，是字段落点：

- 【事实】→ 写进 `## Source Trace` 的 `file:line` 条目；是 `confidence: high` 的唯一凭据
- 【推断】→ `confidence: medium/low` + 推理链（写进 `## Problem` 或对应 trace 条目）
- 【缺口】→ 写进 `## Open Questions`（intake 契约原文：低置信不确定性不得藏进 prose）

```markdown
【事实】`--format json` 下部分失败以退出码 2 表示，stdout 仍输出已成功的条目
        （`upstream@v1.4.0:cmd/run.go:212`；证据类别 test+code）

【推断】列表输出按名称排序是有意契约，不是 map 迭代顺序的偶然结果
        （依据：输出前显式调用 `sort.Strings`，且 golden 测试锁定该顺序；
         confidence: medium；证据类别 test+code，doc 未提）

【缺口】超过 1000 条时静默截断的动机未知
        （已查：README、CHANGELOG、该行 blame 指向的 PR，均无讨论；
         处置：进 ## Open Questions，重写是否复刻由人裁）
```

本 skill 特有的第四维：**每条需求标注证据类别组合**——`test+code+doc` / `code-only` / `doc-only` 这类写法，直接决定重写风险等级。三源一致最硬；`doc-only` 可能已漂移；`code-only` 可能是偶然行为。落地为 Source Trace 条目的来源前缀，机械可统计；`confidence` 由该组合推导，判据见 `references/evidence-classes.md`。

**Source Trace 钉版本**：证据指向的是源项目（外部仓库），条目格式统一为 `<upstream>@<baseline>:<file>:<line>`。基线在 Step 0 钉死，全部证据引用同一基线。这是硬要求不是建议——parity 对照必须可复现，基线混用会让整份产出失去可核验性。

八类证据源各自的陷阱、置信度判据、三源冲突处理，见 `references/evidence-classes.md`。

## 契约还是偶然（对等重写分流激活）

对等重写分流下，**每条行为断言都要标 parity class**，落地为 KLL tags（不破坏 `requirements import`）。重设计分流不激活此分类，产出中不应出现 parity tags。

| class | 判据 |
|---|---|
| `parity-contractual` | 文档承诺，或测试锁定，或 semver 公开面语义内 |
| `parity-incidental-relied` | 偶然，但有依赖证据（下游 issue、生态用法、兼容性讨论） |
| `parity-incidental` | 偶然，且无依赖证据 |

**测试直译判据（场景层的粒度闸门）**：测试是最强证据，但不是所有测试都能直译成 scenario——KLL scenario 描述可观察行为，而单元测试常断言内部状态。每条要直译的测试先过这道闸门：

| 测试断言的对象 | 处置 |
|---|---|
| stdout/stderr、退出码、响应体、持久化的外部可见效果、返回值的公开语义（黑盒可观察） | 可直译为 scenario |
| 内部状态、私有字段、调用次数与中间结果（白盒） | 不得直译，只能作条款的支撑证据 |
| golden / 快照测试 | 先过上表 parity 分类再决定是否进场景——它们最容易把偶然细节锁成「契约」 |

分类判据细则、Hyrum 处置、golden 测试陷阱，见 `references/contractual-vs-incidental.md`。

## 尖锐发现清单

条目完备是下限，价值在尖锐发现。本 skill 聚焦**三源冲突与契约缺口**，逐类扫过，不要凭印象归类：

| # | 发现类型 | 判定方式 | 重写中的处置 |
|---|---|---|---|
| 1 | 文档承诺未实现 / 与实现相反 | doc 说 X，代码 `file:line` 做 Y | 进 Open Question：以哪边为准？（人定，不代答） |
| 2 | 测试与文档矛盾 | 断言与承诺不一致 | 同上——两个「契约」冲突必须人裁 |
| 3 | 静默契约 | 无 doc 无 test，但对外可观察且合理预期会被依赖（默认值、退出码、顺序稳定性） | 按 parity class 分类后进条款或行为观察附录 |
| 4 | 测试锁死的偶然行为 | golden/快照测试固化了格式细节等偶然行为 | 标 `parity-incidental*`，防止重写时被误当验收标准 |
| 5 | 未读取的入参 / 静默忽略的配置 | 调用方能传的参数与实际解析对照，差集即是 | 决定重写要不要复刻这个「坑」：进 Open Question |
| 6 | 静默截断 / 降级 | 硬编码上限，超限不报错、给基于截断数据的答案 | 必须显式写进条款（MUST 行为或 MUST NOT），不许漏 |
| 7 | 错误被吞 / 压平 | 部分失败表现为成功或统一错误码 | 同上；对等重写时这是最易静默破坏的面 |

两条硬规则：

- **每条发现必须写明「谁会因此做出错误判断」**——没有这句，它只是一个代码观察，不是需求发现。
- **发现清单放在读者最先看到的位置**（分析材料的前两屏），并被相应 requirement 的 `## Source Trace` / `## Open Questions` 引用。自检：读者只读前两屏，能否看到那条最可能让重写静默破坏的事实？不能就重排。

逐面盘问用的完整问题集见 `references/behavior-surface-checklist.md`。

## 产出什么：内容项与可恢复性

内容项 = Candidate Requirement Block 的必备字段（依据 agent-spec intake 契约，机械执行）。逐项按「从证据的可恢复性」处理，不要对不可恢复项硬凑内容：

| 内容项 | 可恢复性 | 处理 |
|---|---|---|
| `## Requirements` 条款 | 高——测试断言几乎可直译，代码行为点可陈述 | 核心产出；modality 按映射表 |
| `## Scenarios` | **最高**——测试就是现成场景（过测试直译闸门） | discover 骨架可作种子；非测试来源场景从行为面矩阵补 |
| `## Problem` | 部分——README motivation、CHANGELOG、issue | 常为【缺口】，禁止反向编造 |
| `## Dependencies` | 部分——特性依赖可从代码结构推 | 标【推断】 |
| `source excerpt` / `## Source Trace` | 完全——这就是证据本身 | 钉基线版本（见「证据纪律」） |
| `confidence` | 由证据类别组合机械推导 | 判据见 `references/evidence-classes.md` |
| `## Open Questions` | —— | 承载全部不确定与三源冲突 |
| 优先级 | 不可恢复 | 不伪造；代码投入只是间接证据 |
| rationale | 不可恢复 | 同 architecture-reconstruction 6.10 结论 |

**Modality 映射表**（**本 skill 约定，无标准可依**：正向需求工程不存在「重建时 MUST/SHOULD/MAY 怎么定」这个问题，29148 不回答它。照实标注，不要伪托标准）：

| 证据情形 | modality |
|---|---|
| 测试锁定 或 文档承诺 | MUST |
| 文档建议性措辞（should / recommended） | SHOULD |
| `parity-incidental-relied` | 治理时人定（skill 给判据不代答）：升 MUST 或记 SHOULD |
| `parity-incidental` | 不写成条款，记入行为观察附录 |

**聚类约定**：按行为面聚类成 requirement 文档（一个行为面一个文档，内含多条 `[REQ-*]` 条款），不是一断言一文件。`usecase-reconstruction` 的用例清单存在时可作聚类参考。

块模板（与 `requirements import` 的 marker 格式兼容，带中文指导注释）在 `assets/candidate-block-template.md`，复制填写。

## 工作流

### Step 0 — 定重写语义【唯一值得打断用户的问题】

先问清分流，再动手取证：

- **对等重写** — 激活 parity 分类与 parity 维度展开
- **重设计** — 侧重 Problem 与需求层，场景允许重写；不出现 parity tags
- **只补 spec 文档** — 不激活 parity 分类，产出止于受治理的需求文档本身

同时钉死两件事：**范围**（整项目还是子系统）、**parity 基线版本**（tag 或 commit，全部证据引用它）。用户没说清就问——分流或基线定错，后面全部白做。若用户明确要求不打断，默认「对等重写 + 整项目」，并在产出头显式声明这个假设。

### Step 1 — 证据清点

先跑脚本，不要凭目录名猜：

```bash
bash <本 skill 目录>/scripts/inventory_behavior_evidence.sh <源项目 repo 根目录>
```

（脚本路径相对**本 skill 目录**，不是相对当前工作目录——取证通常在重写仓库里进行，两者不是同一个目录。）

它清点 8 类行为证据源：分层测试（unit/integration/e2e/golden/快照）、可执行示例、API schema（openapi/proto/jsonschema）、CLI help/man、用户文档、CHANGELOG、上游兼容套件、issue/讨论区（依赖证据）。**关键是它报告哪些不存在**——据此决定哪些结论根本没有依据可给。浅克隆会让 git 与历史类证据说谎，脚本会检测并提示；命中就在产出里标注历史截断。

各证据源的已知陷阱见 `references/evidence-classes.md`。

### Step 2 — 行为面清点（机械清单）

列出**对外产生结果的路径**：CLI 命令×标志、API 端点、库公共 API、配置项、环境变量、文件格式（读与写）、退出码、stdout/stderr 语义。每条行为面记录三源覆盖情况，填进**行为面×证据源矩阵**（模板 `assets/behavior-surface-matrix.md`）——这是核心中间产物，后续一切断言的地基。

对等重写分流在此展开 parity 维度组合：命令×输出模式、本地×远程、冷×热、成功×部分失败×硬失败。

清单项与易漏面见 `references/behavior-surface-checklist.md`。

### Step 3 — 逐面盘问

对矩阵每一行过一遍「静默正确性」问题集的行为版：未读取的参数、静默截断、反直觉默认值、错误吞没、部分失败表现、顺序稳定性、并发语义、时区/locale/编码假设。每条发现产出一条行为断言候选，并归入七类发现之一。

### Step 4 — 三源对照

doc vs code vs test 逐面对照，冲突单列成漂移发现（发现 #1 / #2）。`usecase-reconstruction` 已跑过的项目，其发现 #1/#2 直接并入。

### Step 5 — 起草 Candidate Requirement Blocks

按内容项表 + modality 映射 + parity tags + confidence 判据逐块起草。`agent-spec discover --from-codebase` 的机械骨架（每个测试名一个占位 scenario，无 AI）可作场景种子，过测试直译闸门后细化。

产出分两类落盘：**分析材料**（行为面矩阵、发现清单）进重写仓库 `docs/`；**候选需求块**落为重写仓库 `docs/` 下的候选块文件，作为 `requirements import --from` 的输入。约定路径（模板的 `source` 属性与门 1 的 `--from` 都指向它们，别处不再重复给。`docs/reconstruction/` 是三个重建 skill 的共用约定根，各占一个子目录：本 skill 落 `requirements/`、`architecture-reconstruction` 落 `architecture/`、`usecase-reconstruction` 落 `use-cases/`。若重建对象是源仓库内的子项目/子目录，在约定根后插一级目标标识：`docs/reconstruction/<target-slug>/requirements/…`，`<target-slug>` 取目标相对源仓库根的路径、`/` 换成 `-`，如 `packages/core` → `packages-core`；整仓重建不加这一级）：

| 产出 | 约定路径 |
|---|---|
| 行为面×证据源矩阵 | `docs/reconstruction/requirements/behavior-surface-matrix.md` |
| 发现清单（含行为观察附录） | `docs/reconstruction/requirements/findings.md` |
| 候选块文件 | `docs/reconstruction/requirements/candidate-blocks.md` |

**发现清单的必备结构**（无独立模板，照此四段写）：① 头部三行——源项目、基线、分流，外加一句「只读前两屏也要看到的 N 条」指向最危险的发现；② 七类逐条展开，每条给 doc/code/test 各自出处、探针结果（有则给）、**「谁会因此做出错误判断」**、处置去向；③ **逐类扫描的否定结论**——某类零命中要写明「已扫过、零命中及其理由」，不能靠沉默让读者以为是遗漏；④ **行为观察附录**——`parity-incidental` 的行为按 Modality 映射表不写成条款，全部落在这一节，用 EARS 句式写成「观察到什么」，**不进 KLL、不参与门禁、不参与重写验收**。

### Step 6 — 门禁与反向访谈

按序跑门禁，任一步不过就回去补，不要带着红灯往下走：

```
agent-spec requirements import → lint-knowledge --gate → requirements graph --gate → requirements questions
```

反向访谈循环沿用 `agent-spec-intent-compiler` 的既有 loop：只问 blocking 问题、人工确认才回写、答案落为条款/场景/trace 之后才消 Open Question。**人工治理 accept 之后需求才成为真相层**——gate 通过不等于 accept。

CLI 不可用时显式声明降级，等价的人工检查清单见 `references/cli-gates.md`。

### Step 7 — 交接与验证

交接前逐条把关这两项要求：对等重写时 **parity 维度必须已显式绑定进 scenario**，不许只留在 prose 里；contract 的 `Test:` 选择器在**新仓库**落地——KLL 场景是 code-independent 的，选择器绑定发生在 `draft-specs` 之后。交接细则见 `references/cli-gates.md`。

然后按「验证：不要停在纸上」做验证，别停在门禁绿灯上。

### Step 8 — 自检

逐条核对下节「自检」清单。任一项不过就回到对应 Step 补证据——不要用含糊措辞把不过的项掩盖过去。

## 产出分级与规模纪律

先估规模再决定形态：

| 档位 | 触发 | 产出 |
|---|---|---|
| **速览** | 只想评估「能不能重写、代价多大」 | 行为面×证据源矩阵 + 尖锐发现清单，不进 KLL |
| **标准** | 子系统级重写 | 矩阵 + 发现清单 + Candidate Requirement Blocks + 门禁通过 |
| **完整** | 整项目对等重写 | 标准档 + 探针测试验证 + 上游对照差异报告 |

**规模警戒（硬规则）**：大型项目上行为面遗漏是系统性的。标准档以上必须分行为面/分模块推进，并强制声明覆盖率与未覆盖行为面——不允许笼统宣称「重建了需求」。

## 自检

- [ ] 每条实质断言归入【事实】/【推断】/【缺口】之一
- [ ] 所有【事实】有 `<upstream>@<baseline>:<file>:<line>`，基线全篇一致
- [ ] 每条需求标注了证据类别组合；confidence 与之相符
- [ ] `## Problem` 无编造动机——每个动机陈述有出处或标【缺口】
- [ ] modality 全部过映射表；没有 code-only 偶然行为被写成 MUST
- [ ] 对等重写分流：parity class 三值都出现过判定（不是全标 contractual）；parity 维度组合已展开进场景
- [ ] 重设计分流：未出现 parity tags
- [ ] 七类发现逐类扫过，每条写明谁会做出错误判断
- [ ] 三源冲突全部进了 Open Questions 或发现清单，没有被择一掩盖
- [ ] 直译场景全部过了测试直译闸门（无内部状态断言混入）
- [ ] `requirements import` 无错、`lint-knowledge --gate` 与 `requirements graph --gate` 通过（或已声明 CLI 降级）
- [ ] 覆盖率与未覆盖行为面已声明
- [ ] 最危险的发现出现在分析材料前两屏

## 验证：不要停在纸上

门禁绿灯只证明产出自洽，不证明它描述的是那个项目。三个验证手段，按成本递增，能做几个做几个：

1. **上游对照**：上游测试套件能跑就跑，拿重建的需求逐条对照跑出的差异。对不上的地方要么是断言错了，要么是撞见了没被锁定的行为——两种都值钱。
2. **问维护者**：把关键推断整理成**具体问题**（不是「架构是怎样的」这种大问题）去 issue/discussion 问。这是消掉【推断】最快的手段。
3. **探针测试**：挑 N 条 `code-only` 断言，在源项目的基线版本上写测试验证，跑通即断言为真。这是把 `code-only` 升格为可验证事实的唯一机械手段。

完整档必须做到 ① 与 ③——上游对照差异报告与探针测试验证是它相对标准档的全部增量。

## 参考资料

需要更深内容时按需读取，不要一次性全读：

- `references/evidence-classes.md` — 8 类行为证据源、各自陷阱、置信度判据、三源冲突处理
- `references/behavior-surface-checklist.md` — 行为面清单 + 逐面盘问问题集（行为版静默正确性问题）
- `references/contractual-vs-incidental.md` — parity 分类判据、modality 映射表、Hyrum 处置、golden 测试陷阱
- `references/requirement-quality.md` — ISO 29148 §5.2 条款质量特征 + EARS 句式，依据逐条标注【一手】/【二手】，确证不了的标「无法确证」
- `references/cli-gates.md` — agent-spec CLI 门禁序列、降级人工清单、draft-specs 交接要求

模板：`assets/behavior-surface-matrix.md`（行为面×证据源矩阵）、`assets/candidate-block-template.md`（Candidate Requirement Block）。脚本：`scripts/inventory_behavior_evidence.sh`（Step 1 证据清点）。

若当前项目存在实践规范库（常见路径 `standards/01-requirements/`，或 CLAUDE.md 中声明的 `$STD`），一并检索并在产出中标注其条目 ID，使结论可回溯到项目自己的规范依据。不存在则静默跳过——本 skill 自身完备，不依赖它。
