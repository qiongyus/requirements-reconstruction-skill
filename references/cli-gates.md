# agent-spec CLI 门禁细则

本文件展开 SKILL.md「工作流」Step 6（门禁与反向访谈）与 Step 7（交接与验证）：门禁序列本身的存在、反向访谈循环沿用上游、交接前要核对 parity 与 `Test:` 选择器，SKILL.md 已经写清楚，此处不重复；只给每道门**判定内容、诊断长相、失败去向**，CLI 不可用时的等价人工清单，以及交接给下游前必须核对的三点的具体展开。

全部命令与参数已用本机 `agent-spec 1.1.0` 的 `--help` 与真实执行核实，不照抄 README——README 可能滞后于当前版本；诊断示例均为本机用最小示例文件实测所得（非真实重建项目产出，构造用于展示诊断长相），已在正文标注。

## 一、门禁序列

序列本身：

```
agent-spec init --workspace                                                          # 准备，仅首次
agent-spec requirements import --from <候选块文件> --out knowledge/requirements        # 门 1
agent-spec lint-knowledge --knowledge knowledge --gate                               # 门 2
agent-spec requirements graph --knowledge knowledge --format json --gate             # 门 3
agent-spec requirements questions --knowledge knowledge --specs specs --format json  # 门 4（无 --gate，见下）
```

四道门的子命令、顺序与 `--gate` 标志，与 SKILL.md「工作流 Step 6」给出的 `agent-spec requirements import → lint-knowledge --gate → requirements graph --gate → requirements questions` 逐条一致——`--help` 核实未发现 SKILL.md 与 CLI 实测不符之处。`init --workspace` 不在 SKILL.md 门禁清单内：它是进入一个尚无 `knowledge/` 目录的重写仓库时的一次性脚手架，没有通过/失败语义，因此单独列为「准备」，不计入四道门。

以下命令里 `--knowledge knowledge`（各命令默认值均为 `knowledge`）、`--specs specs`（`questions` 默认值即此）、`--out knowledge/requirements`（`import` 默认值即此）三处路径参数当前都等于 CLI 默认值，写出来只是为了锚定路径语义，可以省略；但 `--format json` **不是**默认值（各命令 `--format` 默认为 `text`），是让门 3/门 4 产出机器可读格式的必要参数，不能省略。

### 准备：`agent-spec init --workspace`

- **挡什么**：不挡什么——只创建 `knowledge/{requirements,decisions,proposals,guidance,context}` 与 `.agent-spec/config.yaml` 骨架目录树。唯一要留意的行为：已存在的 workspace 不会被覆盖或报错，只打印一行提示并以 0 退出，所以不能靠它的退出码判断「起草流程是否已经跑过」，它只保证目录骨架存在。
- **诊断长相**：首次成功时逐文件输出 `created knowledge/requirements/README.md` 等约十行；重复执行时输出单行 `workspace already scaffolded (nothing to do)`。两种情况都是退出码 0。
- **失败了回哪一步**：不适用——它是环境前置条件，不是产出质量门。若后续命令的 `--knowledge`/`--out` 默认路径对不上这里建出的目录，回 Step 0 核对是否在重写仓库根目录下执行。

### 门 1：`agent-spec requirements import --from <候选块文件> --out knowledge/requirements`

- **挡什么**：候选块文件的**结构可解析性**——起止 marker（`<!-- agent-spec:requirement id=... -->` 与 `<!-- /agent-spec:requirement -->`）是否配对齐全。它不检查内容质量（措辞、场景是否可观察、九特征），那是门 2 的职责；也不校验 id 是否符合 `REQ-` 前缀约定、不查跨文件重复 id（本机实测：不带 `REQ-` 前缀的 id、以及重复导入同一份候选块文件，均未被 import 拒绝，说明这两类问题它不管，不能指望它替你查）。
- **典型诊断长相**：漏写闭合 marker 时报 `error: requirement block closing marker is missing`，退出码 1；成功时**无 stdout 输出**，只以退出码 0 表示，生成文件落在 `<out>/req-<id 小写>-<title slug>.md`，frontmatter 里 `status: proposed`（治理状态机起点，见门禁外的 `requirements transition`）。
- **失败了回哪一步**：回 Step 5（起草 Candidate Requirement Blocks）核对候选块是否照抄了 marker 格式——不是回证据环节，因为这道门只挑格式，不挑内容。

### 门 2：`agent-spec lint-knowledge --knowledge knowledge --gate`

- **挡什么**：整个 `knowledge/` 语料的内容质量与治理完整性——per-doc 规则（必备小节是否齐全、MUST 条款是否配场景、条款是否单一陈述、scenario 的 Then 是否可观察等）与 governance integrity。诊断分 `[Warning]`/`[Error]` 两级，`--gate` 的语义是「仅当存在 Error 级别发现时以非零退出」（`--help` 原文）——Warning 只汇总展示、不卡门。本机对 `agent-spec` 自身仓库 `knowledge/` 做 dogfood 验证了这条：39 个文档、576 条发现全部是 Warning，`0 errors`，`--gate` 以退出码 0 通过。
- **典型诊断长相**（构造了一个缺 `## Problem` 小节的候选块触发 Error）：
  ```
  knowledge/requirements/req-probe-bad-probe-bad.md: [Error] requirement-required-section — requirement is missing required `## Problem` section
  knowledge/requirements/req-probe-bad-probe-bad.md: [Warning] requirement-must-needs-scenario — MUST requirements should have at least one scenario
  2 docs, 3 findings (1 errors)
  gate: 1 error-level knowledge finding(s)
  ```
  退出码 2。`--knowledge` 指向不存在的目录时也会经同一条诊断通道报出（`knowledge-parse-error — cannot parse knowledge doc: knowledge root does not exist or is not a directory`），是「路径配错」这类环境错误与「内容有缺陷」这类真实发现共用的判定路径，看到 Error 先确认目录本身存在。
- **失败了回哪一步**：视 rule id 决定——`requirement-required-section` 一类结构缺陷回 Step 5（补齐字段，对照候选块模板）；`requirement-must-needs-scenario`、`requirement-weak-then`、`requirement-single-statement` 一类内容缺陷回 Step 3（逐面盘问补场景/拆条款）或 Step 4（三源对照重新核证措辞）。
- **两类预期内的 Warning 噪声，不要当成自己写错**（dogfood 实测，10 个候选块共 28 条 Warning、0 Error）：
  - `requirement-weak-then — scenario Then step is not clearly observable`：该规则的可观察性判据是英文启发式，而本 skill 要求中文写作、模板也背书中文关键词，于是**每一条中文的退出码断言**（`那么 退出码是 0`）都会被报一次——本次 28 条里有 11 条是它。退出码是模板明列的合法可观察断言，这类 Warning 属工具的语言覆盖缺口，不卡门，不必为消除它把场景改写成英文。真正要认真对待的 `requirement-weak-then` 是断言了内部状态的那种（没过测试直译闸门），两者靠读 Warning 引用的那句 Then 文本区分。
  - `requirement-single-statement` / `requirement-compound-clause`：条款里出现两个 MUST（典型是「MUST 写 stdout **且** MUST NOT 写文件」这种 parity 常见的成对断言）就会各报一次。这两条**不是**噪声，与 `requirement-quality.md` 第一节 Singular（一条款一断言，多响应拆条）同向——按它拆条即可消除，dogfood 实测拆条后同一份内容可做到 0 findings。

### 门 3：`agent-spec requirements graph --knowledge knowledge --format json --gate`

- **挡什么**：需求之间 `## Dependencies` 声明的依赖图结构——依赖了不存在的 id（`dangling-dependency`）、循环依赖（`dependency-cycle`）。这是门 2 管不到的一层：单个文档内部字段齐全，不代表跨文档的引用是闭合的。
- **典型诊断长相**（构造悬空依赖与循环依赖两个场景实测）：
  ```
  requirements: 2 nodes, 1 diagnostics, 0 parse errors
  [error] REQ-PROBE-DANGLING dangling-dependency: REQ-PROBE-DANGLING depends on missing requirement REQ-DOES-NOT-EXIST
  ...
  error: requirement graph gate failed
  ```
  循环依赖的诊断码是 `dependency-cycle`，消息形如 `dependency cycle detected: REQ-CYCLE-A -> REQ-CYCLE-B -> REQ-CYCLE-A`。两者都使 `--gate` 以退出码 1 判负。`--format json` 下同样信息落在顶层 `diagnostics` 数组（字段 `code`/`severity`/`requirement_id`/`message`）；`nodes` 数组带出每条需求的 `clauses`（`id`/`keyword`/`text`）；`parse_errors` 数组承载文档级解析失败（例如 `--knowledge` 目录不存在时）。
- **失败了回哪一步**：回 Step 5 核对该需求块 `## Dependencies` 里的 id 有没有抄错；若确认没抄错、只是被依赖的那条需求根本还没起草或没 import，说明 Step 2（行为面清点）漏了对应行为面，要回 Step 2 补，不是回 Step 5。

### 门 4：`agent-spec requirements questions --knowledge knowledge --specs specs --format json`

- **挡什么**：和前两道门性质不同——它没有 `--gate` 语义（`--help` 未列出该标志），本身不产生通过/失败判定；它挡的是「机械诊断转成人工访谈议程」这一步是否被跳过。**空 `knowledge` 目录、乃至完全不存在的 `--knowledge` 路径都不会让它报错**（本机实测：指向不存在路径时输出 `clarification questions: 0`，退出码 0）——不能靠这道命令的退出码判断上游数据是否完整，那是门 2/门 3 的职责。
- **典型诊断长相**：text 格式首行 `clarification questions: N`，随后每行 `<question-id> [<diagnostic_code>] <requirement-id>: <prompt>`；`--format json` 下是对象数组，字段 `id`/`target_id`/`diagnostic_code`/`blocking`/`prompt`/`source`/`options`。
- **失败了回哪一步**：它不失败，只报数。议程非空即回 Step 6 的反向访谈子环节（见第二节）；议程为空也不能直接判定可以进 Step 7 交接——先确认门 2/门 3 确实是绿灯，因为这道门对残缺输入是沉默的。

## 二、反向访谈

沿用上游约定【一手，`agent-spec` 仓库 `skills/agent-spec-intent-compiler/SKILL.md`「Reverse Interview Loop」「Reverse Interview Format」「Answer Integration」三节，约第 100–135 行】，不另立规则——具体问答呈现的措辞要求见上游原文，此处只标出用到哪一段、在哪里截断：

1. **只问 blocking**：只对 `blocking: true` 的条目发起访谈；`blocking: false` 的质量类提示（本机实测遇到的 `requirement-weak-then`、`requirement-compound-clause` 等诊断码在本次样本里均为 `blocking: false`）除非用户明确要做质量清理，否则不主动问。
2. **访谈呈现**：逐条给出需求 id、这个问题由哪条诊断触发、原文问题措辞、source 能引到的原文摘录；只有来源材料本身支持时才给 2–3 个具体选项，并始终保留自由作答路径。
3. **人工确认才回写**：模型自己的推断不算数，只有人工确认后的答案才允许写回。
4. **答案落为条款才消 Open Question**：把确认后的答案转成具体的需求条款、场景步骤、依赖、Source Trace 条目之一并写回需求正文后，才能删除或改写对应的 `## Open Questions` 条目——不能先消条目再补内容。
5. **重跑收敛**：写回后重跑门 2 `lint-knowledge --gate` 与门 4 `requirements questions`（上游原文的 Answer Integration 还包含 `requirements plan --gate`，那一步属于 Task Contract/work-unit 下游阶段，落在本 skill 边界之外——本 skill 不起草 Task Contract，交 `agent-spec-authoring`——因此不在此处重跑）；议程仍有 blocking 条目就继续循环，不带着未消的 blocking 问题进 Step 7 交接。

## 三、降级人工清单（CLI 不可用时）

CLI 不可用（未安装/版本不兼容/环境无法执行二进制）时，四道门各有等价的人工检查动作，但降级后的产出必须在文档头部显式声明**「未过机械门禁」**——这是硬要求，不能省略，防止读者把降级产出误当成已过门的受治理需求。

| 门 | 人工等价检查 |
|---|---|
| 门 1 import | 人工核对候选块文件的 marker 语法（起止 marker 是否配对、`id`/`title`/`tags`/`source` 属性是否齐全）与必备节是否齐全（`## Problem`/`## Requirements`/`## Scenarios`/`## Dependencies`/`## Source Trace`/`## Open Questions`；字段清单见 SKILL.md「产出什么」一节，此处不重复） |
| 门 2 lint-knowledge | 人工过 `references/requirement-quality.md` 的九特征（Necessary/Appropriate/Unambiguous/Complete/Singular/Feasible/Verifiable/Correct/Conforming）逐条款核对 |
| 门 3 graph | 人工画一张依赖表（每条需求一行、`## Dependencies` 列出的 id 一列），核对两件事：**无环**（顺着依赖链条摸，摸回自己算环）、**无 dangling id**（每个被依赖的 id 都能在表里找到对应的行） |
| 门 4 questions | 人工把全部候选块的 `## Open Questions` 条目汇总成一份清单，当反向访谈议程用（等价于门 4 产出的角色，但缺了诊断码/`blocking` 这类结构化字段——降级后应保守处理，把全部 Open Questions 都当 blocking 处理，不擅自筛掉） |

声明格式建议（放在降级产出文档头部）：

```
【未过机械门禁】本产出因 CLI 不可用降级为人工检查，未经 agent-spec lint-knowledge / requirements graph 机械验证。
```

## 四、交接要求（设计 §6 Step 7）

三点，交接前逐条把关，任一项不满足不得交接：

1. **parity 维度必须显式绑定进 scenario，不许只在 prose**：对等重写分流下，命令×输出模式、本地×远程、冷×热、成功×部分失败×硬失败这类 parity 维度组合，必须落在 `## Scenarios` 的 Given/When/Then 步骤里作为可执行的区分条件（例如把「远程 + 部分失败」写成一条独立 scenario 的前提与断言），不能只在 `## Problem` 或条款正文里提一句自然语言描述——prose 里的提及不会被 `lint-knowledge`/`requirements graph` 机械检查到，也不会被后续 `draft-specs` 拿去生成对应的 Task Contract 场景。
2. **`Test:` 选择器在新仓库落地，KLL 场景保持 code-independent**：本 skill 的产出止于 `knowledge/requirements/*.md`，场景本身不绑定任何具体测试名——这是有意的，重写目标代码此时还不存在。真正的 `Test:` 选择器绑定发生在 `requirements draft-specs` 之后，且落地对象是**新仓库**（重写产出的代码库），不是被重建需求的那个源项目。【一手，`agent-spec` README「Requirements Intake And Work Units」draft-specs 用法段】：`draft-specs` 生成的草稿场景选择器以 `pending_` 前缀占位，`agent-spec lifecycle` 会把这类不存在的选择器判为 `fail`；必须由人工在新仓库里把每个 `pending_...` 替换成真实测试名之后，草稿才算可执行，`trace` 的结果才能当验收证据用——这一步在本 skill 边界之外（属于 `draft-specs`/`agent-spec-authoring` 下游职责），本 skill 只保证交接时场景没有提前假造一个测试名。
3. **治理 accept 是人工动作，skill 不代跑**：`agent-spec requirements transition REQ-* --to accepted` 把需求从 `proposed` 推进到 `accepted`——README 给出这条命令时原文标注为 `# human governance action`【一手，README「Requirements Intake And Work Units」代码块】。门禁全绿只代表产出自洽（结构、依赖图、内容质量都过了机械检查），不代表内容已被人工确认为真——门禁通过与 accept 是两件事。本 skill 的自动化到门禁这一步为止，`transition ... --to accepted` 必须由人显式执行，skill 不得自动调用这条命令。
