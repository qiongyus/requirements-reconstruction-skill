# requirements-reconstruction

从既有开源项目/代码库的源码、测试与文档**重建结构化需求**，产出 agent-spec KLL 层的 Candidate Requirement Blocks——经确定性门禁与人工治理后，作为重写工作的受治理真相层。

这是一个中文个人 skill。给 agent 读的正文在 `SKILL.md`；本 README 面向浏览仓库的人，介绍定位、内容与安装方式。**结合 agent-spec 的端到端使用说明（从触发到 Task Contract 落地）见 `USAGE.md`。**

## 定位

代码里没有「需求」这个现成的东西，只有三类回答不同问题的**行为证据**：测试（有意锁定的行为）、代码（实际行为）、文档（宣称的行为）。本 skill 的方法核心是三源对照 + 认知地位标注：

- **三级证据纪律**：【事实】/【推断】/【缺口】，每条断言落到 Candidate Requirement Block 的既有字段，缺口显式声明而不是编造
- **证据类别组合**：`test+code+doc` / `code-only` / `doc-only` 等，机械推导 `confidence`，直接决定重写风险等级
- **契约还是偶然**：对等重写分流下每条行为断言标 parity class（`parity-contractual` / `parity-incidental-relied` / `parity-incidental`），防止把实现事故写成 MUST，也防止漏掉静默契约
- **尖锐发现**：七类三源冲突与契约缺口逐类扫描，每条发现必须写明「谁会因此做出错误判断」
- **确定性门禁**：产出过 `agent-spec requirements import → lint-knowledge --gate → requirements graph --gate → requirements questions` 四道门，机械可验，不停留在 prose 自洽

与相邻方法的分工：

| 要做的事 | 用什么 |
|---|---|
| 为尚不存在的系统做正向需求分析 | `agent-spec-intent-compiler`（PRD 正向路径） |
| 重建架构描述（AD） | `architecture-reconstruction` |
| 重建用例模型 | `usecase-reconstruction` |
| **从既有项目重建需求、做对等重写的 parity 分析** | **本 skill** |

三个重建型 skill 相互独立，只共享证据层；本 skill 不起草 Task Contract（交给 `requirements draft-specs` + `agent-spec-authoring`）。

## 工作流一览

| Step | 内容 |
|---|---|
| 0 | 定重写语义（对等重写 / 重设计 / 只补 spec 文档），钉死范围与 parity 基线版本 |
| 1 | 证据清点（`scripts/inventory_behavior_evidence.sh`，8 类行为证据源，报告哪些**不存在**） |
| 2 | 行为面清点，填行为面×证据源矩阵 |
| 3 | 逐面盘问（静默正确性问题集的行为版） |
| 4 | 三源对照，冲突单列成漂移发现 |
| 5 | 起草 Candidate Requirement Blocks + 发现清单 |
| 6 | agent-spec 四道门禁 + 反向访谈循环 |
| 7 | 交接 `draft-specs` 与验证（上游对照 / 问维护者 / 探针测试） |
| 8 | 自检（13 项清单） |

## 内容

```
SKILL.md                                  正文：方法、失败模式、工作流、自检
references/
  evidence-classes.md                     8 类行为证据源、各自陷阱、confidence 判据、三源冲突处理
  behavior-surface-checklist.md           十类行为面清单 + 逐面盘问问题集 + parity 维度组合
  contractual-vs-incidental.md            parity 分类判据、Hyrum 处置、golden 测试陷阱
  requirement-quality.md                  ISO/IEC/IEEE 29148 §5.2 质量特征 + EARS 句式（依据逐条标注一手/二手）
  cli-gates.md                            agent-spec CLI 门禁序列、降级人工清单、交接要求
assets/
  behavior-surface-matrix.md              行为面×证据源矩阵模板
  candidate-block-template.md             Candidate Requirement Block 模板（与 requirements import 兼容，实测过导入）
scripts/
  inventory_behavior_evidence.sh          Step 1 证据清点脚本
```

## 安装

```bash
rsync -a --exclude .git <本仓库>/ ~/.agents/skills/requirements-reconstruction/
ln -s ../../.agents/skills/requirements-reconstruction ~/.claude/skills/requirements-reconstruction
```

依赖：`agent-spec` CLI（门禁与导入；不可用时 skill 内有显式降级路径，见 `references/cli-gates.md`）。
