# 使用说明：requirements-reconstruction × agent-spec 全链路

本文面向使用者（人），讲清两件事：怎么触发并配合本 skill 完成需求重建；重建产出如何接入 agent-spec 管线，一路走到可验证的 Task Contract。方法本身（证据纪律、parity 分类、七类发现）见 `SKILL.md`，此处不重复。

全部命令均以本机 `agent-spec 1.1.0` 的 `--help` 与实测核实。

## 0. 全链路一图

```
源项目（上游仓库，钉死基线版本）
   │
   ▼  阶段 A：需求重建（本 skill，Step 0–8）
docs/reconstruction/requirements/   （docs/reconstruction/ 为三个重建 skill 共用根）
   ├── behavior-surface-matrix.md   行为面×证据源矩阵
   ├── findings.md                  尖锐发现清单（三源冲突、静默契约…）
   └── candidate-blocks.md          Candidate Requirement Blocks
   │
   ▼  阶段 B：确定性门禁（agent-spec CLI，四道门）
knowledge/requirements/*.md（status: proposed）
   │
   ▼  阶段 C：反向访谈 + 人工治理（人的动作）
knowledge/requirements/*.md（status: accepted）＝ 重写的真相层
   │
   ▼  阶段 D：下游管线（agent-spec 既有能力，不属本 skill）
work_units.json → specs/generated/*.spec.md（Task Contract 草稿）
   → 人工把 pending_ 测试选择器绑到新仓库真实测试
   → agent-spec lifecycle / trace 作验收证据
```

角色分工一句话：**本 skill 负责阶段 A，并把阶段 B 跑绿；阶段 C 的裁决与阶段 D 的起草属于人与 agent-spec 既有管线，skill 只保证交接物合格。**

## 1. 前置条件

- `agent-spec` CLI 可执行（`agent-spec --version` ≥ 1.1.0）。不可用也能走，见 §7 降级。
- 本 skill 已安装（`~/.claude/skills/requirements-reconstruction` 可解析）。
- 一个**重写仓库**（新代码库，产出落在这里）与**源项目检出**（被重建的上游仓库，完整克隆——浅克隆会让 git 历史类证据说谎，脚本会检测并提示）。

## 2. 快速开始

在重写仓库里开一个新会话，用自然语言说清意图即可，skill 会自动命中，例如：

> 我想用 Rust 对等重写 `<源项目路径>` 这个项目，先把它的行为需求重建出来。

agent 接管后你只需要参与四个点（详见 §6）：**Step 0 分流答复、三源冲突裁决、blocking 访谈答复、治理 accept**。其余全是 agent 的机械劳动。

### Step 0 你会被问的唯一问题

三选一分流 + 两个钉死项，答完 agent 才动手：

| 你要的是 | 分流 | 效果 |
|---|---|---|
| 换语言/换栈重实现，行为对齐旧版 | **对等重写** | 激活 parity 分类与 parity 维度展开 |
| 借鉴问题域重新设计 | **重设计** | 侧重 Problem 与需求层，不出现 parity tags |
| 只想给旧系统补需求文档 | **只补 spec 文档** | 产出止于受治理的需求文档 |

同时钉死：**范围**（整项目还是某子系统）、**parity 基线**（一个 tag 或 commit，全部证据引用它）。基线定错后面全部白做，所以这里值得想清楚。

## 3. 阶段 A：需求重建（skill 自动执行）

Step 1–5 无需干预，agent 会：跑 `scripts/inventory_behavior_evidence.sh` 清点 8 类证据源 → 填行为面×证据源矩阵 → 逐面盘问 → 三源对照 → 起草候选块与发现清单。落盘约定路径：

| 产出 | 路径（重写仓库内） | 给谁看 |
|---|---|---|
| 行为面×证据源矩阵 | `docs/reconstruction/requirements/behavior-surface-matrix.md` | 人（评估覆盖面） |
| 发现清单 | `docs/reconstruction/requirements/findings.md` | **人（先读这个）** |
| 候选块文件 | `docs/reconstruction/requirements/candidate-blocks.md` | 机器（门 1 的输入） |

**先读 `findings.md` 的前两屏**——skill 强制把最危险的发现（文档与代码矛盾、静默契约、被测试锁死的偶然行为）放在那里。里面每条三源冲突都是留给你裁决的：以文档为准还是以代码为准，skill 不代答。

## 4. 阶段 B：门禁（skill 自动执行，你看结果）

在重写仓库根目录，四道门按序跑，任一步红灯回上游补，不带病前进：

```bash
agent-spec init --workspace          # 仅首次：建 knowledge/ 骨架，无通过/失败语义
agent-spec requirements import --from docs/reconstruction/requirements/candidate-blocks.md   # 门 1：结构可解析
agent-spec lint-knowledge --gate                                                # 门 2：内容质量（仅 Error 卡门）
agent-spec requirements graph --format json --gate                              # 门 3：依赖图无环、无悬空
agent-spec requirements questions --format json                                 # 门 4：产出访谈议程（不判负）
```

每道门挡什么、诊断长什么样、失败回哪一步，见 `references/cli-gates.md`。两类**不必理会/照拆即可**的 Warning：中文 Then 步骤触发的 `requirement-weak-then`（工具英文启发式的语言覆盖缺口，不卡门）；`requirement-single-statement`（成对 MUST 断言按「一条款一断言」拆开即消除）。

门 1 成功后，每个候选块落为 `knowledge/requirements/req-*.md`，frontmatter `status: proposed`——注意此刻它们还**不是**真相层。

## 5. 阶段 C：反向访谈与治理（你的动作）

**反向访谈**：门 4 产出的议程里只有 `blocking: true` 的条目会被拿来问你。规则是硬的：agent 的推断不算数，你确认的答案才回写；答案落成条款/场景/trace 之后对应 Open Question 才消；回写后重跑门 2 与门 4，直到没有 blocking 条目。

**治理 accept**：门禁全绿只证明产出自洽，不证明内容为真。逐条（或逐批）确认后由**你**执行：

```bash
agent-spec requirements transition REQ-XXX --to accepted   # 也可 rejected / deprecated
```

这条命令 skill 明文规定不代跑。accept 之后的需求才是重写工作的真相层。

## 6. 你的参与点汇总

| 时机 | 你做什么 | 不做会怎样 |
|---|---|---|
| Step 0 | 答分流三选一 + 钉范围与基线 | agent 默认「对等重写 + 整项目」并声明假设 |
| 读 findings.md | 裁决三源冲突（以 doc 还是 code 为准） | 冲突滞留在 Open Questions，下游无法起草对应条款 |
| 反向访谈 | 答复 blocking 问题 | 循环不收敛，不得进入交接 |
| 治理 | `transition --to accepted` | 需求停在 proposed，不构成真相层 |
| 阶段 D | 把 `pending_` 选择器绑到新仓库真实测试 | 草稿 spec 不可执行，`lifecycle` 判 fail |

## 7. 阶段 D：接到重写实施（agent-spec 既有管线）

真相层就绪后，离开本 skill 的边界，走 agent-spec 自己的链路：

```bash
agent-spec requirements work-units                    # 从 accepted 需求生成 work_units.json
agent-spec requirements draft-specs                   # 渲染 Task Contract 草稿 → specs/generated/
```

草稿场景的测试选择器带 `pending_` 前缀占位——KLL 场景是 code-independent 的，重写目标代码起草时还不存在。**在新仓库里**逐个把 `pending_...` 替换成真实测试名（这一步建议配合 agent-spec 仓库的 `agent-spec-authoring` skill 打磨 contract 措辞），然后：

```bash
agent-spec lifecycle                                  # lint → verify → report，验收证据
agent-spec requirements trace REQ-XXX                 # 需求级证据链回查
```

对等重写分流下有一条交接硬要求（skill 已在阶段 A 保证）：parity 维度组合（成功×部分失败×硬失败等）已显式写进 `## Scenarios`，因此 draft-specs 生成的草稿会带出对应场景——你只需绑测试，不需要回头补场景。

实现环节按 contract 驱动开发即可；每完成一个 work unit，`lifecycle` 绿灯 + `trace` 证据链闭合，就是「这条重建需求已在新实现里成立」的机械证明。

## 8. 降级与常见坑

- **CLI 不可用**：四道门各有等价人工检查（清单在 `references/cli-gates.md` §三），但产出头部必须带 `【未过机械门禁】` 声明——这是硬要求。
- **浅克隆**：`git log`/blame 类证据会缺失，Step 1 脚本会检测；命中就在产出里标注历史截断，别让【事实】引用残缺历史。
- **大型项目**：不要指望一轮盘完。标准档以上必须分行为面/分模块推进，并强制声明覆盖率与未覆盖行为面——「重建了需求」这种笼统宣称是被 skill 自检明文禁止的。多轮推进时先跑 `architecture-reconstruction` 得到 AD 作调度输入,再落轮次计划——轮的定义、排序依据、id 防撞纪律见 skill 内 `references/multi-round-planning.md`。
- **验证别停在门禁绿灯**：绿灯只证明自洽。完整档要求做上游对照（跑上游测试套件对差异）与探针测试（挑 `code-only` 断言在源项目基线上写测试验证）——后者是把 `code-only` 升格为可验证事实的唯一机械手段。

## 9. 端到端实例（v0.1.0 dogfood 摘要）

靶子：[chmln/sd](https://github.com/chmln/sd) @ `v1.1.0-4-g44febdf`，分流「对等重写」，整项目。

- 阶段 A 产出 10 个候选块、9 处 parity 判定、发现清单 10 条；
- 阶段 B 四道门全绿（28 条 Warning、0 Error）；门 4 产出 34 条问题（9 条 blocking），实跑一轮反向访谈，其中一条 doc-only 疑问用 `mkfifo` 流式探针当场消解；
- 两条「读文档照抄必踩」的发现：`--max-replacements` 文档三处说 per file、代码默认模式实际 per line、四条测试全部绕开默认模式（三源冲突，必须人裁）；CHANGELOG 承诺的「原子写保留属主」是未参与编译的死代码（`src/output.rs` 无 `mod output;`）。

任何跳过阶段 A 直接「读文档写 spec」的重写都会把这两个坑原样带进新实现——这就是先重建、后重写的理由。
