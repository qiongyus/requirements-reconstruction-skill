# parity 分类与 modality 判定细则

本文件展开 SKILL.md「契约还是偶然（对等重写分流激活）」与「产出什么：内容项与可恢复性」两节：parity class 三值判据表、测试直译判据表、Modality 映射表**本体**均已在 SKILL.md 给出，此处不重复表格，只给：三值的判定顺序与每类的判定问句/正反例、Modality 映射表里两处需要人裁的具体操作判据、Hyrum's Law 的执行动作、以及 golden/快照测试这个最容易把偶然锁成契约的坑该怎么拆。

## 一、parity 三分类判定细则

### 判定顺序（五步，机械执行，不得跳步）

1. **查 doc 承诺**——文档是否明确写下了这个行为？
2. **再查测试锁定**——是否有测试断言这个行为（黑盒可观察，或至少可作条款的支撑证据）？
3. **再查 semver 公开面**——该行为是否落在项目声明的 semver 兼容承诺语义内（公开 API 签名、CLI 标志存在性等）？
4. **都无，则查依赖证据**——issue、讨论区、生态用法、兼容性讨论里是否有人已经在依赖它？
5. **都无，标 `parity-incidental`。**

前三步命中任意一步即可判 `parity-contractual`，不必再往下查；第 1–3 步全部落空、第 4 步命中即 `parity-incidental-relied`；连第 4 步也落空才是 `parity-incidental`。这五步就是 SKILL.md 三值判据表的执行顺序，不是三个可以任意顺序核对的并列条件——先查强证据（doc/test/semver）能省掉大量本来就该判 contractual 的行为被误拉去查依赖证据的成本。

### `parity-contractual`

判定问句：这个行为是否被文档承诺、或被测试有意锁定为可观察断言、或落在项目声明的 semver 公开面语义内？三者满足其一即可。

- **正例**：README 明确承诺的输出字段集合。出处【一手，仓库内可确证】：`agent-spec` 仓库 `examples/rewrite-parity-contract.spec:39-44` 的 json 场景——`Then stdout contains only JSON` / `` And the payload includes `id`, `type`, and `content` ``，字段集合既是场景断言（测试锁定）又是该 spec 的 `## Decisions` 承诺（`--json` and human output are separate observable modes and both must remain stable，第 16 行），双重命中，判 `parity-contractual` 无疑。
- **反例**：错误消息的具体措辞，文档只说「报错」。文档承诺的只是「这种情况下会报错」这一行为类别（存在这条错误路径），没有承诺错误消息文本的逐字内容。如果把错误消息原文当成 contractual 锁定，就是把「确实会报错」这个真契约和「报错文案怎么写」这个偶然内容混为一谈——这正是第四节 golden 测试陷阱的微缩版本。

### `parity-incidental-relied`

判定问句：该行为无文档承诺、无测试专门锁定（或只有白盒断言）、也不在 semver 公开面内，但是否存在可确证的下游依赖证据？

- **正例**（构造示例，非真实项目引用）：未文档化但 issue 里有人依赖的退出码 2/3 区分——工具从未在文档里区分退出码 2（部分失败）与退出码 3（配置错误），代码里也只是两处不同的 `os.Exit` 调用，没有测试专门锁定这个区分；但假定下游某 CI 脚本的 issue 讨论里明确写了「我们靠退出码 3 判断要不要重试」且该讨论帖可具体定位到链接，这就是 evidence-classes.md 里说的「issue/讨论区」这一唯一来源提供的可确证依赖证据，判 `parity-incidental-relied`。实际判定时「可具体定位到链接」是硬要求，不能用「大概有人这么用吧」代替。
- **反例**（构造示例，非真实项目引用）：某 CLI 内部按 map 遍历顺序打印字段名，无文档承诺、无测试锁定顺序，代码里也没有显式排序调用；查遍 issue/讨论区也找不到任何一条提到「依赖这个顺序」的记录。即便直觉上「看起来像会有人在意顺序」，没有可确证的依赖证据就不能判 `relied`，只能标 `parity-incidental`——这正是下面「宁标 incidental」纪律要防的误判方向：把「我觉得可能有人依赖」当成了「查到了依赖证据」。

### `parity-incidental`

判定问句：走完前四步（doc / test / semver / 依赖证据）均未命中？

- **正例**（构造示例，非真实项目引用）：日志时间戳精确到毫秒还是微秒，从未被文档提及、未被任何测试断言、不在公开面承诺内，也搜不到任何用户依赖这个精度做解析的讨论——标 `parity-incidental`，重写时不必保留这个精度，记入行为观察附录即可。
- **反例**（构造示例，非真实项目引用）：不能仅凭「实现手法看起来像随手写的」就跳过判定顺序直接标 incidental。例如某函数对返回列表做了显式 `sort.Strings` 调用，表面上像一处无人特意设计的实现选择；但如果测试专门断言了这个排序结果（且断言的是返回值这一黑盒可观察语义，不是内部状态），根据判定顺序第 2 步「测试锁定」，就应当判 `parity-contractual`，不是 `parity-incidental`。这个反例演示的是流程纪律本身：判类必须走完五步查证，不能凭代码写法的第一印象抄近路。

### 纪律：宁标 `parity-incidental` 加 Open Question，不虚标 relied

`parity-incidental-relied` 的依赖证据只能来自 issue/讨论区这一类无法机械化取证的来源（evidence-classes.md 已指出这类证据系统性偏少），一旦取证不到位就容易靠「感觉像是有人会依赖」把行为拔高成 relied，结果是重写背上了一个其实没有真实依赖方的约束。上面 `parity-incidental-relied` 的反例就是这个误判的样子。可执行的纪律是：**查不到可确证的依赖出处（具体 issue 链接、具体讨论帖、具体生态用法），就不得判 `relied`，一律落回 `parity-incidental`，并在对应 Candidate Requirement Block 的 `## Open Questions` 里留一条「是否存在未查到的下游依赖，需人工/上游确认」**——宁可事后被人裁纠正为 relied，也不能让一个凭直觉拔高的 relied 判断混进产出且无法回溯它的依赖出处。

## 二、Modality 细则（回指 SKILL.md 映射表）

Modality 映射表本体（四行证据情形到 MUST/SHOULD/人定/不写条款的对应关系）见 SKILL.md「产出什么：内容项与可恢复性」，此处不重复，只展开表里两处需要人来做判断、而不是查表就能定案的地方。

### 人裁点 1：`parity-incidental-relied` 升 MUST 的判据

映射表把这一类行为的 modality 交给治理阶段人定，skill 给判据不代答。判据是三个观察角度，供人裁参考：

1. **依赖面广度**：是本地一个仓库的孤立 issue，还是多个独立下游项目、多个生态位都报告了同样的依赖？广度越宽，升 MUST 的理由越强；单条 issue、无跟帖佐证的依赖证据，本身只够支撑判 `relied`（见第一节判据），不足以单独作为升 MUST 的理由。
2. **破坏后果**：改掉这个偶然行为后，下游遭遇的是数据丢失、流程中断这类硬失败，还是仅仅「看起来不一样」的软影响？后果越硬，越应当升 MUST。
3. **上游是否已经把它当 bug 修过又被迫回滚**：如果上游自己曾经尝试修正这个偶然行为、因下游抗议而回滚发布，这本身就是「事实上已成为契约」的最强信号——这正是 Hyrum's Law 的经典场景，可以单独作为升 MUST 的充分理由，不需要再叠加前两条。

三条不要求同时满足，但也不能只拿第 1 条的单薄证据（一条孤立 issue）就升 MUST；应结合破坏后果或回滚历史综合判断。判断结果与依据要写进对应条款的 `## Open Questions` 或治理记录，不能只留一个「已升级为 MUST」的结论而不说明依据是三条里的哪一条。

### 人裁点 2：文档「建议性措辞」的识别

映射表把「文档建议性措辞」单列一行对应 SHOULD，识别时要认的词面：

- 英文：should、recommended、prefer(red)、it is advisable to、may want to（弱建议）
- 中文：建议、推荐、宜、最好、应当尽量、酌情

要与 MUST 级措辞区分开，不要混进同一档：must、required、shall、have to；中文「必须」「务必」「不得」——这些词面对应的是映射表里「测试锁定或文档承诺」那一行，直接是 MUST，不经过 SHOULD 这一档。

识别陷阱：不能只看孤立词面，要看该行为是否同时被更强的证据命中。例如中文文档写「建议使用 `--json` 以获得稳定输出」，「建议」本身是 SHOULD 级措辞；但如果该行为同时被测试专门锁定（黑盒可观察的输出稳定性断言），那么这条行为已经满足映射表里「测试锁定」这一更强的判据，modality 按 MUST 那一行走，不能因为文档语气是「建议」就把它降级成 SHOULD——映射表按行匹配取的是「命中的最强证据对应哪一行」，不是「文档自己怎么措辞就照单全收」。

## 三、Hyrum's Law 处置（标注：业界共识、风险提示非规范）

Hyrum's Law 在本 skill 里的依据地位是业界共识、只作风险提示，不作规范依据——不与 29148、EARS 这类一手标准并列引用。原文【一手，`hyrumslaw.com` 官网原文，已 curl 核对】：

> With a sufficient number of users of an API, it does not matter what you promise in the contract: all observable behaviors of your system will be depended on by somebody.

SKILL.md「三个最危险失败模式」已经点出这条现实修正：偶然行为可能确实有人依赖，处置不是删掉，也不许伪装成设计意图。落到可执行动作上，处置是三个动作，**缺一不可**：

1. **标明偶然**——判定结果落在 `parity-incidental` 或 `parity-incidental-relied`，且在产出里写清楚「这不是设计意图」，防止重写时被误当验收标准（呼应尖锐发现清单 #3 静默契约、#4 测试锁死的偶然行为）。
2. **依赖证据**——若判 `relied`，必须附上可确证的依赖出处（具体 issue 链接、具体讨论帖、具体生态用法），不能停留在「我觉得可能有人依赖」的直觉判断（呼应本文件第一节「宁标 incidental」纪律）。
3. **交人裁**——升 MUST 还是留 SHOULD、还是止步于行为观察附录，由治理阶段人工决定，skill 本身不代答（呼应第二节人裁点 1、Modality 映射表第三行「治理时人定」）。

三个动作任一缺失都不合格：只标偶然不给依赖证据，`relied` 的判断就没有依据支撑，等同于凭空拔高；只给依赖证据不交人裁，等于 skill 自己替人工做了 modality 决定，违反「治理时人定」的通用纪律；只交人裁不先标明偶然，治理者根本不会意识到这是一个需要决策的偶然行为，会被直接当成普通 MUST 条款接受下来，Hyrum's Law 提示的风险反而完全落空。

## 四、golden/快照测试陷阱（尖锐发现清单 #4 展开）

golden/快照测试锁定的是**全部**输出字节——契约成分（字段是否存在、语义是否正确）和偶然成分（格式怎么排版）混在同一份断言里。直译成 scenario 前必须逐字段过一遍 parity 分类，不能把整份 golden 文件当作一条不可拆分的契约直译（对应 SKILL.md「测试直译判据」表里 golden/快照测试单列一行、要求先过 parity 分类再决定是否进场景）。

典型偶然成分列举（这些是最常见的、容易被 golden 文件顺带锁死的格式细节）：

- **字段顺序**：JSON key 顺序、CSV 列输出顺序——若代码没有显式声明这个顺序是契约（也没有文档/依赖证据支撑），顺序本身就是偶然的
- **空白/缩进**：pretty-print 的缩进宽度、是否有尾随换行
- **时间戳格式**：具体到毫秒还是微秒、是否带时区偏移这类排版细节（区别于「是否包含时间戳」这件事本身——后者可能是契约）
- **错误消息全文**：逐字文案（区别于「是否报错」「报什么类别的错」这件事本身——后者可能是契约，见第一节 `parity-contractual` 反例）

### golden 测试直译前后对照示例（构造示例，非真实项目引用）

**前**——把 golden 文件的全部字节当作一条不可拆分的契约直译：

```
Scenario: export --format json returns the documented payload
  Test: test_export_json_golden
  Given a record with id "42"
  When the user runs `export --format json`
  Then stdout equals byte-for-byte the golden file `testdata/export.json.golden`
```

这种写法把 golden 文件的全部字节（字段顺序、缩进宽度、末尾换行、时间戳精度……)都当成 `parity-contractual` 锁定；一旦重写实现换一种 JSON 序列化库、产出语义等价但格式不同的输出，这条场景就会误报「违反契约」，而实际上没有任何调用方在意过这些格式细节。

**后**——逐字段过完 parity 分类后，拆成条款只锁字段存在性与语义，格式细节单独标注：

```
[REQ-EXPORT-JSON-001] `export --format json` 的 stdout MUST 是合法 JSON，
且包含字段 `id`、`type`、`content`，语义与人类可读模式返回的内容一致。
parity: parity-contractual（字段集合与语义——文档承诺 + 测试锁定，
证据类别 test+code+doc）

（行为观察附录，不写成条款）
stdout 的 JSON 序列化细节（键顺序、缩进宽度、末尾换行）当前由 golden
测试固化，但无文档承诺、无下游依赖证据。
parity: parity-incidental
```

「前后」差异：前者把「字段集合」和「格式细节」混在同一条按同一强度锁死的断言里；后者拆成两条——字段集合与语义升格为正式 `[REQ-*]` 条款（MUST，`parity-contractual`），格式细节降格为行为观察附录（`parity-incidental`），不进条款、不参与重写验收，重写实现只要字段集合与语义不变，换用任何 JSON 序列化方式都不算破坏 parity。
