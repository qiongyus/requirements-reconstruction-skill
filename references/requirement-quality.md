# 条款质量特征（ISO 29148 §5.2）与 EARS 句式

本文件给需求重建产出的**文本层质量判据**：条款写成什么样才算合格。SKILL.md 已定义的三级标注、证据类别组合（`test+code+doc` / `code-only` / `doc-only`）、parity class 三值（`parity-contractual` / `parity-incidental-relied` / `parity-incidental`）、Modality 映射表、自检清单，此处一律不重复；本文件只做两件 SKILL.md 没做的事：把 29148 的九个个体特征与五个集合特征**逐条翻成重建语境下可执行的检查动作**，以及给出条款文本的句式骨架（EARS）。

## 取材记录与依据分级

| 来源 | 取材方式 | 依据分级 |
|---|---|---|
| ISO/IEC/IEEE 29148:2018(E) 全文 PDF（`books/ISOIECIEEE 29148 ( etc.).pdf`） | Read 工具逐页视读 PDF 页 19–22（文档页 11–14）与 PDF 页 26（文档页 18），引用逐字核对 | 【一手】 |
| 同上，§5.2.4 / §5.2.5 / §5.2.6 部分结论 | `docs/brainstorms/2026-08-01-usecase-reconstruction-feasibility.md` §2.3 已核对，**本次仍从 PDF 逐字复核**（核对记录见该文档） | 【一手】 |
| EARS 五模板与句法骨架 | `curl -sL https://alistairmavin.com/ears/`（2026-08-01 取得成功，30 KB） | 【一手·作者官网】 |
| EARS 原始论文（2009 年首次发表，官网自述） | **未取得原文** | 【无法确证】，见末节 |

**页码约定**：正文引用一律写 29148 自己印在页面上的**文档页码**（例：文档页 12），对应 PDF 第 20 页；两者相差 8。

**核对手段的精确说明**：文档页 11–14 与 18（本文件绝大多数引用的出处）经 Read 工具**逐页视读**核对；末节提到的文档页 32 / 38 两处遗留系统条款只经 PDF 文本抽取核对，未逐页视读——同一份一手 PDF，但核对强度不同，据实注明。

## 一、§5.2.5 个体条款的九个特征

强制性逐字【一手·29148 §5.2.5，文档页 12】：

> Each stakeholder, system and system element requirement shall possess the following characteristics.

是 shall，不是 should。以下九条按标准原序，每条给：**定义句原文短引**（逐字）+ 中文释义 + **重建语境下怎么检查**（可操作动作，与 SKILL.md 自检清单呼应但不复述）。

### 1. Necessary（必要）

> The requirement defines an essential capability, characteristic, constraint and/or quality factor. If it is not included in the set of requirements, a deficiency in capability or characteristic will exist, which cannot be fulfilled by implementing other requirements. The requirement is currently applicable and has not been made obsolete by the passage of time.
> 【一手·29148 §5.2.5，文档页 12】

释义：删掉它就会缺一块能力，且这块能力不能由其他条款蕴含；并且它**当下仍然适用**，没有因时间流逝而作废。

**重建语境下怎么检查**——两个动作：

- **删除测试**：逐条问「把这条 `[REQ-*]` 删掉，重写实现会不会因此丢掉一个调用方能观察到的能力？」丢不掉就说明它被别的条款蕴含了。重建里这类冗余有固定来源：一处代码分支被机械展开成三条断言（判定、日志、返回值各一条），实际只有一条是能力。合并，或降为行为观察附录。
- **基线可达性复核**：「currently applicable」在重建里的落点是 Source Trace 的基线版本——证据取自已废弃路径（deprecated 标记、默认关闭的 feature flag、不可达的 dead code）的断言**不满足 Necessary**。检查动作：对每条 `code-only` 断言，在 `<upstream>@<baseline>` 上确认该代码路径在默认配置下真的可达；确认不了的进 `## Open Questions`，不要写成条款。

### 2. Appropriate（层级恰当）

> The specific intent and amount of detail of the requirement is appropriate to the level of the entity to which it refers (level of abstraction appropriate to the level of entity). This includes avoiding unnecessary constraints on the architecture or design while allowing implementation independence to the extent possible.
> 【一手·29148 §5.2.5，文档页 12】

释义：详略与抽象层级要与它所指的实体相称；不得给架构或设计施加不必要的约束，尽可能保留实现独立性。同一条在语言层还有一句更直白的【一手·29148 §5.2.7，文档页 14】：

> Requirements should state 'what' is needed, not 'how'.

**重建语境下怎么检查**——**划实现名词**：把条款文本里的实现专名（函数名、类名、内部结构体、第三方库名、算法名）全部划掉，看断言是否还成立。划掉后不成立，说明它描述的是「怎么做」而不是「要什么」。这是本 skill 头号失败模式（把偶然当契约）在文本层的具体表现，`code-only` 断言最容易犯——因为它的证据本身就是实现。可执行的收敛判据：**条款主语必须是对外可观察面**（stdout/stderr、退出码、响应体、持久化产物、公开 API 返回值），不能是内部组件。主语一旦是内部组件，这条要么改写成它产生的可观察结果，要么退回支撑证据。

注意这条与对等重写并不冲突：parity 要保留的是**可观察行为**，不是实现手法（golden 测试拆解的前后对照见 `contractual-vs-incidental.md` 第四节）。

### 3. Unambiguous（无歧义）

> The requirement is stated in such a way so that it can be interpreted in only one way. The requirement is stated simply and is easy to understand.
> 【一手·29148 §5.2.5，文档页 12】

释义：只能有一种解读，且叙述简单易懂。

**重建语境下怎么检查**——把 §5.2.7 的禁用词表当 grep 清单跑一遍。该表由 shall 引入【一手·29148 §5.2.7，文档页 14】：

> Vague and general terms shall be avoided.

前八类词面（逐字）：`superlatives (such as 'best', 'most')`；`subjective language (such as 'user friendly', 'easy to use', 'cost effective')`；`vague pronouns (such as 'it', 'this', 'that')`；`ambiguous terms such as adverbs and adjectives (such as 'almost always', 'significant', 'minimal') and ambiguous logical statements (such as 'or', 'and/or')`；`open-ended, non-verifiable terms (such as 'provide support', 'but not limited to', 'as a minimum')`；`comparative phrases (such as 'better than', 'higher quality')`；`loopholes (such as 'if possible', 'as appropriate', 'as applicable')`；`terms that imply totality (such as 'all', 'always', 'never', and 'every')`。

第九类对本 skill 是**直接命中**——`incomplete references (not specifying the reference with its date and version number...)`：引用上游而不钉版本，正是标准点名的歧义来源。所以 Source Trace 必须写成 `<upstream>@<baseline>:<file>:<line>`，缺基线的 trace 条目不只是本 skill 的内部规矩，它同时违反 29148 的 Unambiguous。

### 4. Complete（个体自足）

> The requirement sufficiently describes the necessary capability, characteristic, constraint or quality factor to meet the entity need without needing other information to understand the requirement.
> 【一手·29148 §5.2.5，文档页 12】

释义：不借助其他信息就能理解这条要求（注意：与 §5.2.6 集合层的 Complete 同名不同义，见第二节）。

**重建语境下怎么检查**——**脱上下文朗读**：把条款文本单独摘出来（不带 `## Source Trace`、不带源码），交给没读过源项目的人或另一个 agent，问「这条要求的可观察行为是什么」。答不上来，就是不 Complete。重建里失败的固定形态是**隐含前置条件**：条款只有读过那段源码才知道它其实只在某标志开着、某配置存在、某平台上成立。修法是把前置条件写进条款本身（或 scenario 的 Given），不能靠 trace 的行号让读者自己去补——行号会漂移，前置条件不会自己冒出来。

### 5. Singular（单一）

> The requirement states a single capability, characteristic, constraint or quality factor.
> 【一手·29148 §5.2.5，文档页 12】

NOTE 2 给了豁免边界【一手·同页】：

> Although a single requirement consists of a single function, quality or constraint, it can have multiple conditions under which the requirement is to be met.

释义：一条款一断言；但**多个条件不违反 Singular**，多个能力/响应才违反。

**重建语境下怎么检查**——机械判据由 §5.2.7 NOTE 1 逐字给出【一手·29148 §5.2.7，文档页 14】：

> Consider multiple requirements when encountering terms such as 'or', 'and', or 'and/or'.

即：条款文本里出现 and / or / and/or 连接**两个行为**时，一律拆成两条（连接两个*条件*时不拆——NOTE 2 的豁免）。重建里的固定违反源是**测试直译**：一个测试函数里常有多条 assert，直译时必须一断言一条款，不能把整个测试函数压成一条 MUST。这条与 EARS ruleset 的 `One or many system responses` 存在张力，处置见第三节末。

### 6. Feasible（可行）

> The requirement can be realized within system constraints (e.g., cost, schedule, technical) with acceptable risk.
> 【一手·29148 §5.2.5，文档页 12–13】

释义：能在系统约束（成本、进度、技术）内以可接受的风险实现。

**重建语境下怎么检查**——这一条在重建里**含义反转**【推断，标准未讨论重建场景】：源项目基线上该行为已经被实现过，存在性本身就是可行性证明，所以「能不能做」不再是问题。真正要检查的是**移植可行性**：目标语言/运行时上有没有等价机制。逐条对 `parity-contractual` 条款问一遍——依赖平台特有 syscall？依赖某语言的 GC/终结时机？依赖特定正则引擎或浮点实现的语义？依赖进程模型（fork 语义、信号）？任一命中且目标栈无等价物，这条就不是「照抄即可」，进 `## Open Questions` 记为重写风险，不许默认可行。

### 7. Verifiable（可验证）

> The requirement is structured and worded such that its realization can be proven (verified) to the customer's satisfaction at the level the requirements exists. Verifiability is enhanced when the requirement is measurable.
> 【一手·29148 §5.2.5，文档页 13】

释义：措辞与结构要让「已实现」可以被证明；可度量会增强可验证性。

**重建语境下怎么检查**——**条款必须能落为 scenario**，检查动作是机械的：试着为它写出 Given / When / Then，且 Then 必须是可观察量。写不出可观察的 Then（只能写成「内部状态是 X」）说明它没过 SKILL.md 的测试直译闸门，不得作条款，只能作支撑证据。两条自检可直接机械统计：**每条 MUST 至少绑定一个 scenario；没绑 scenario 的 MUST 视为未过 Verifiable**。重建还有一个正向工程没有的强手段——**探针测试**（SKILL.md「验证：不要停在纸上」第 ③ 项）：挑 `code-only` 断言在基线版本上写测试跑通，这是把 `code-only` 升格为可验证事实的唯一机械手段。

### 8. Correct（忠实于 need）

> The requirement is an accurate representation of the entity need from which it was transformed.
> 【一手·29148 §5.2.5，文档页 13】

释义：条款要准确表述它由之转化而来的那个实体需要（need）。

**重建语境下怎么检查**——**结构上无法满足，必须声明为缺口**。重建的输入是代码、测试、文档，原始 need 不在其中；rationale 不可从代码恢复（SKILL.md 内容项表已把 rationale 与优先级列为不可恢复项）。所以本 skill 把 Correct 降级为一个**可检查的代理**：条款是否忠实于**它的证据**（而不是忠实于那个不可知的 need）。检查动作：逐条回读 `## Source Trace` 指向的 `file:line`，问「条款文字与那几行代码/断言之间的差，是不是纯粹的推断」——差出来的部分必须标【推断】、降 confidence，且不得以 MUST 出场。这是本文件两处结构性不满足之一，一次性声明的写法见第二节。

### 9. Conforming（合模板）

> The individual items conform to an approved standard template and style for writing requirements, when applicable.
> 【一手·29148 §5.2.5，文档页 13】

释义：条款遵循某个**已批准的**标准模板与写作风格——**适用时**（when applicable，是标准自己给的适用条件）。

**重建语境下怎么检查**——本 skill 的「approved standard template」是明确且机械可检的两层：**结构层**是 Candidate Requirement Block 模板（`assets/candidate-block-template.md`）与 `requirements import` 的 marker 格式，检查手段就是门禁本身（`requirements import` 无错 + `lint-knowledge --gate` 通过，见 `cli-gates.md`）；**文本层**是第三节的 EARS 句式。注意一个确证过的否定结论：**29148 全文未出现 "EARS" 字样**（对 PDF 抽取文本做大小写敏感检索，0 命中），标准只要求「有一个已批准的模板」，不指定是哪个。选 EARS 是本 skill 的约定，不是标准指定。

## 二、§5.2.6 集合特征与一致性声明

强制性逐字【一手·29148 §5.2.6，文档页 13】：

> Each set of requirements for a system, software or service shall possess the following characteristics.

同样是 shall。五条，按标准原序。每条只给重建语境下的落点（定义句逐字引用，中文释义从简）。

**Complete（集合完备）**

> The set of requirements stands alone such that it sufficiently describes the necessary capabilities, characteristics, constraints or quality factors to meet entity needs without needing further information. In addition, the set does not contain any To Be Defined (TBD), To Be Specified (TBS), or To Be Resolved (TBR) clauses.

NOTE 2 把话说死了【一手·29148 §5.2.6 NOTE 2，文档页 13】：

> However, the set of requirements cannot be considered complete until all the TBx designated requirements have been resolved.

→ **与本 skill 的【缺口】纪律结构性冲突**：重建产出必然含 `## Open Questions`（TBx 的等价物），且 SKILL.md 明令低置信不确定性不得藏进 prose。所以集合 Complete 在导出时结构上不可能满足。这是第二处结构性不满足。

但同一条下的 NOTE 3 给了一条对重建**有利**的裁剪依据【一手·29148 §5.2.6 NOTE 3，文档页 13】：

> Adapted and open source software frequently have existing functions that are not utilized in the system of interest. For integrated systems, systems of systems and systems containing COTS components, the requirements for the solution of interest can still be 'complete'.

即：源项目里存在但目标系统用不到的功能面，不覆盖它们不影响「solution of interest」这个集合被称为 complete。这给 SKILL.md「规模警戒」要求的**覆盖率与未覆盖行为面声明**提供了标准依据——未覆盖面必须显式列出（否则读者无从判断 scope），但列出之后不必为它们补条款。

**Consistent（一致）**

> The set of requirements contains individual requirements that are unique, do not conflict with or overlap with other requirements in the set, and the units and measurement systems are homogeneous. The terminology used within the set of requirements is consistent, i.e. the same term is used throughout the set to mean the same thing.

重建落点：术语是从源项目里捡来的，同一概念在 CLI 标志、文档措辞、代码内部命名里常是三个词（`--dir` / "工作目录" / `workspacePath`）。**检查动作**：产出里建一张术语对照表，每个概念选定一个词，其余词面列为别名并注明出处；然后 grep 别名，确认条款正文里没有混用。单位同理（字节 vs KiB、秒 vs 毫秒、UTC vs 本地时区）。注意重建特有的处置差别：**单位分歧多半不是文字问题，而是不同代码路径的实际差异**——doc 与 code 说法不同即发现 #1，两条代码路径彼此不同则是实现内部的不一致，两种都要写成待裁事项（进 `## Open Questions`），不要在条款里顺手统一成一个「看起来一致」的单位而把差异抹掉。注意 overlap 的检查法与第一节 Necessary 的删除测试是同一个动作，一次跑完两条都过。

三源冲突**不算**集合 inconsistent：它们是被显式记录的发现（#1/#2），处置见 `evidence-classes.md` 第三节。

**Feasible（集合可行）**

> The complete set of requirements can be realized within entity constraints (e.g., cost, schedule, technical) with acceptable risk.

重建落点：单条可行不等于全集可行。典型自相矛盾是**既要求 golden 逐字节一致、又要求换序列化实现**——两条单看都成立，同时锁死则不可行。检查动作：把全部 `parity-contractual` 条款过一遍，找互斥对。

**Comprehensible（可理解）**

> The set of requirements is written such that it is clear as to what is expected by the entity and its relation to the system of which it is a part.

重建落点：这条支撑 SKILL.md 两条排版硬规则——按行为面聚类成文档（而不是一断言一文件），以及最危险的发现放在前两屏。检查动作：读者只读产出前两屏，能否说出「这个系统对外承诺了什么、哪里最可能被静默破坏」。

**Able to be validated（可确认）**

> It is practicable that satisfaction of the requirement set will lead to the achievement of the entity needs within constraints (e.g., cost, schedule, technical, legal and regulatory compliance).

重建落点：**部分不可满足**，原因与 Correct 同源——entity needs 不可知，无法论证「满足这份集合 ⇒ 满足需要」。可做的替代命题是「满足这份集合 ⇒ 与源项目行为对等」，而它的证据只能来自 SKILL.md 验证一节的上游对照与探针测试，不能靠纸面推理得出。门禁全绿**不构成** Able to be validated 的证据。

### 一致性声明（在候选块导出时一次性给出）

29148 的一致性条款不可能满足：全文合规要求 §5.2.4–5.2.7 条款、Clause 7 信息项与 Clause 9/Annex A 的 required content 全部满足；裁剪合规（tailored conformance）则要求「Obtain input from all parties affected by the tailoring decisions」，逆向重建时这些「各方」不存在（【一手】，核对记录见 `docs/brainstorms/2026-08-01-usecase-reconstruction-feasibility.md` §2.3 (c)(d)）。SKILL.md 的立场与此一致：29148 用作质量判据，不声明一致性。

纪律：**声明一次，放在候选块导出物的头部，不在每个块里重复**。逐块重复既污染 `## Open Questions`（那里只放这个块自己的不确定性），又会让真正的块级缺口被淹没。可复制文本：

```markdown
### 关于 ISO/IEC/IEEE 29148:2018 的一致性

本产出以 29148 §5.2.5 / §5.2.6 作为条款质量判据，**不声明**对该标准的
full conformance 或 tailored conformance。已知的结构性不满足两处：

- §5.2.5 **Correct**（条款准确表述其由之转化而来的 need）——重建的输入是
  代码/测试/文档，原始 need 与 rationale 不可恢复。本产出以「忠实于证据」
  作为可检查的代理，凡超出证据的表述均标【推断】并降 confidence。
- §5.2.6 **Complete**（集合不得含 TBD/TBS/TBR）——重建产出必然含
  `## Open Questions`，等价于 TBx。这是刻意的：把不确定性显式化，
  优于为凑完备而编造。所有 TBx 均已显式列出，无隐藏项。

§5.2.6 **Able to be validated** 仅部分满足：可确认的替代命题是「满足本集合
⇒ 与 <upstream>@<baseline> 行为对等」，其证据为上游对照与探针测试结果
（见本产出「验证」一节），门禁通过不构成该项证据。

覆盖率与未覆盖行为面见「覆盖率声明」一节；未被目标系统使用的源项目功能面
不在本集合范围内（依据 29148 §5.2.6 Complete NOTE 3）。
```

## 三、EARS 句式

取材【一手·作者官网 <https://alistairmavin.com/ears/>，2026-08-01 curl 取得】。句法骨架逐字照录，尖括号占位符与关键词大小写均同原文。

通用骨架与 ruleset：

> `While <optional pre-condition>, when <optional trigger>, the <system name> shall <system response>`

> The EARS ruleset states that a requirement must have: Zero or many preconditions; Zero or one trigger; One system name; One or many system responses.

五个模板，按原文顺序：Ubiquitous / State driven / Event driven / Optional feature / Unwanted behaviour。**官网标题不带连字符**；二次文献与中文材料常写作 State-driven、Event-driven，指同一组模式，本文各级标题一律照官网原文书写。

### Ubiquitous requirements（无关键词，恒常生效）

原文：`Ubiquitous requirements are always active (so there is no EARS keyword)`

> `The <system name> shall <system response>`

重建语境例句（构造示例，非真实项目引用）：

```
The tool shall write all diagnostic messages to stderr.
```

证据：`upstream@v1.4.0:internal/log/log.go:31`（代码）+ README「Logging」小节（文档）；证据类别 `code+doc`；parity: `parity-contractual`。
适用场合：恒真的输出面约定（流分配、编码、退出码取值域）——重建里这类条款最容易被漏写，因为它们在代码里没有对应的 if 分支。

### State driven requirements（关键词 While）

原文：`State driven requirements are active as long as the specified state remains true and are denoted by the keyword While.`

> `While <precondition(s)>, the <system name> shall <system response>`

重建语境例句（构造示例，非真实项目引用）：

```
While the cache directory is not writable, the tool shall recompute results
on every invocation.
```

证据：`upstream@v1.4.0:internal/cache/store.go:57`；证据类别 `code-only`（无文档、无测试）；parity: 走完五步判定后暂标 `parity-incidental`，并在 `## Open Questions` 留一条依赖存疑。
适用场合：**静默契约**（尖锐发现 #3）——持续状态下的降级行为，正是 doc 与 test 都不覆盖、重写后最容易静默破坏的一类。

### Event driven requirements（关键词 When）

原文：`Event driven requirements specify how a system must respond when a triggering event occurs and are denoted by the keyword When.`

> `When <trigger>, the <system name> shall <system response>`

重建语境例句（构造示例，非真实项目引用）：

```
When `--format json` is passed, the tool shall write a single JSON document
to stdout.
```

证据：`upstream@v1.4.0:cmd/export.go:88`（代码）+ `TestExportJSONSingleDocument`（测试锁定）；证据类别 `test+code`；parity: `parity-contractual`。
适用场合：绝大多数从测试直译来的条款落在这一档——测试的 act 阶段就是 trigger。

### Optional feature requirements（关键词 Where）

原文：`Optional feature requirements apply in products or systems that include the specified feature and are denoted by the keyword Where.`

> `Where <feature is included>, the <system name> shall <system response>`

重建语境例句（构造示例，非真实项目引用）：

```
Where the build includes the `remote` feature, the tool shall accept the
`--endpoint` flag.
```

证据：`upstream@v1.4.0:cmd/root.go:120`（build tag 条件编译）；证据类别 `code+doc`；parity: `parity-contractual`。
适用场合：条件编译（build tags、feature flags、`--enable-*`）、可选依赖、平台特有能力。重建里这一档极易被误写成 Ubiquitous——只在某个构建配置下成立的行为若写成恒真条款，重写实现会被迫无条件实现它。

### Unwanted behaviour requirements（关键词 If / Then）

原文：`Unwanted behaviour requirements are used to specify the required system response to undesired situations and are denoted by the keywords If and Then.`

> `If <trigger>, then the <system name> shall <system response>`

重建语境例句（构造示例，非真实项目引用）：

```
If an item fails while `--format json` is active, then the tool shall exit
with code 2 and still write the successfully processed items to stdout.
```

证据：`upstream@v1.4.0:cmd/run.go:212`（与 SKILL.md「证据纪律」示例同一条事实）；证据类别 `test+code`；parity: `parity-contractual`。
适用场合：失败路径——尖锐发现 #6（静默截断/降级）与 #7（错误被吞/压平）产出的条款几乎全落这一档，是重写最易静默破坏的一面。注意该例句连接了两个响应（exit code + stdout 内容），按第一节 Singular 应拆成两条；此处合写只为演示 If/Then 骨架。

### Complex requirements（组合，非第六个模板）

原文：`Requirements that include more than one EARS keyword are called Complex requirements.`

> `While <precondition(s)>, When <trigger>, the <system name> shall <system response>`

对等重写分流展开 parity 维度组合（冷×热、本地×远程、成功×部分失败）时会用到（构造示例，非真实项目引用）：

```
While the cache is warm, when `--refresh` is passed, the tool shall bypass
the cache.
```

### 三条接口纪律

1. **EARS 用在条款层，不用在场景层**。`[REQ-*]` 条款文本用 EARS 骨架；`## Scenarios` 用 Given/When/Then。EARS 的 `When <trigger>` 与 Gherkin 的 `When` 形似而不同层——前者是需求句的从句，后者是可执行步骤，不得原样复制过去当场景步骤，场景需要具体化到可执行的输入与断言。
2. **`shall` 与 MUST 的分歧照实标注**。EARS 全部模板用 `shall`；而 29148 §5.2.4 明确【一手·文档页 11】：`Requirements are mandatory binding provisions and use 'shall'.` 以及 `It is best to avoid using the term 'must', due to potential misinterpretation as a requirement.` 本 skill 产出用 MUST/SHOULD，**依据是 agent-spec/KLL 的既有字段与 marker 格式，不是 29148 的推荐——29148 在这一点上恰恰相反**。照实标注，不伪托标准；这与 SKILL.md 对 Modality 映射表「本 skill 约定，无标准可依」的标注是同一条纪律。
3. **Singular 与 ruleset 的张力取更严一侧**【推断，基于两处一手材料的对读】。EARS ruleset 允许 `One or many system responses`，29148 §5.2.5 Singular 要求 `a single capability, characteristic, constraint or quality factor`。两者不完全对齐时本 skill 取 29148：**一条款一断言**，多响应拆条；EARS 只借句法骨架，不引入它对多响应的宽容度。理由是重建产出要过机械门禁并逐条对照 parity，多响应条款无法被单独判定 parity class。

## 四、无法确证清单

按 Global Constraints，确证不了的据实列出，不以转述冒充引用：

- **EARS 原始论文原文未取得**。官网自述 `The notation was first published in 2009 and has been adopted by many organisations across the world.`【一手·官网自述】，但 2009 年的原始论文（RE'09 会议论文）本次未取得全文。因此：本文件所有 EARS 引用的依据仅为**作者官网当前页面**；论文中可能存在的更细规则（模式选择的判定流程、反例、经验数据）**无法确证**，不得据此推断。
- **EARS 对 modality 分级的立场无法确证**。官网页面只出现 `shall`，未讨论 should/may 或 MUST/SHOULD/MAY 的映射。第三节纪律 2 只陈述了「EARS 用 shall」这一可核对事实，未替 EARS 断言它对分级的态度。
- **29148 不涉及「从既有实现反推需求」的方法**（已核对，是确证的否定结论而非缺口）。全文提到 reverse engineering 仅一处，且只作为迭代成因之一列出，不给方法【一手·29148 §5.3.2，文档页 18】：`reverse engineering of requirements for reasons of regulatory compliance; and`。另有两处涉及既有/遗留系统的条款【一手·29148 §6.3.3.6 文档页 32、§6.4.3.4 文档页 38】，讨论的是**既有需求条目的复用**（两处措辞除主语外逐字相同，主语分别为 `stakeholder` 与 `system/software`：`If [stakeholder | system/software] requirements from existing or legacy systems have been identified as candidates for reuse, they should be analyzed for use based on factors such as applicability, feasibility, availability, quality, cost effectiveness, value and currency.`），前提是那些需求条目已经存在——与本 skill「只有代码、没有需求条目」的处境不是同一件事。故本文件所有「重建语境下怎么检查」均为**本 skill 约定**，标准只提供被检查的特征定义，不提供检查方法。
- **29148 未指定任何具体的需求模板**（已核对：全文无 "EARS" 字样）。§5.2.5 Conforming 只要求存在 `an approved standard template`，模板的选择权在采用方。
