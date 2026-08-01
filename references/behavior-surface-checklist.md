# 行为面清单与逐面盘问细则

本文件展开 `SKILL.md`「工作流」Step 2（行为面清点）与 Step 3（逐面盘问）：SKILL.md 已经写清楚「要清点行为面、要逐面盘问静默正确性」这条纪律本身，此处不重复该纪律，只给**怎么机械地把清单列全**与**逐面到底要问什么措辞的问题**这两件操作性的事。

## 一、行为面类型清单

十类。前八类是「对外产生结果的路径」本身；后两类（信号处理、并发/时序）是 SKILL.md 引用的设计文档 §11 指出的已知风险——逐面盘问只能扫到 Step 2 清单里已经列出的面，清单外的面（尤其是信号处理、并发/时序这类不落在「调用一次拿一个返回值」心智模型里的行为）如果不显式列进类型清单，就永远不会被扫到。把它们收进清单本身，而不是指望盘问阶段临时想起来。

| # | 类型 | 怎么机械地列全 |
|---|---|---|
| 1 | CLI 命令×标志 | `--help` 递归展开到全部子命令（含隐藏/`deprecated` 标志）；再与 flag 解析代码（`clap`/`cobra`/`argparse` 等的声明处）做差集——help 文本手写维护的项目常年漏标新增标志 |
| 2 | API 端点 | 路由注册表（router 文件、`urls.py`、装饰器）逐条枚举 method + path；有 OpenAPI/proto 就以其为起点，再与实际路由注册代码做差集，抓 schema 未声明但代码已注册的端点 |
| 3 | 库公共 API | 语言原生的导出清单机械提取：Go 的 `pub`/大写导出、Python 的 `__all__` 与无下划线前缀符号、Rust 的 `pub fn`/`pub struct`、TS 的 `export`；不要凭文档目录猜，导出清单是唯一不遗漏的来源 |
| 4 | 配置项 | schema 文件（JSON Schema/proto/struct tag/`Config` 结构体字段）与解析代码逐字段对照做差集——schema 有但代码从未读取、或代码读了但 schema 未声明，两个方向都要抓 |
| 5 | 环境变量 | 全代码库 grep 取值调用点（`os.Getenv`/`process.env`/`os.environ.get` 等），逐个登记变量名与默认值；再与文档列出的环境变量表做差集 |
| 6 | 文件格式（读与写） | 读、写分列机械列举：读路径单独列 parser 实际接受的字段集合、版本兼容范围、对未知字段的容忍度；写路径单独列 serializer 实际产出的字段集合与顺序——读写两条路径常年不对称（宽进严出或反之），必须分开机械列举，不能假定「读什么就写什么」 |
| 7 | 退出码 | grep 全部退出调用点（`os.Exit`/`sys.exit`/`process.exit`/`panic` 后的进程退出路径），逐个记录触发条件；再与文档/man page 声明的退出码表做差集 |
| 8 | stdout/stderr 语义 | grep 全部输出语句的目标流与格式（human 文本 / JSON / 结构化日志），标注是显式分流设计还是随手写哪个算哪个——这决定了它属于 `parity-contractual` 还是需要 Open Question |
| 9 | 信号处理 | grep 信号注册调用点（`signal.Notify`/`signal.signal`/`sigaction`/框架级 graceful shutdown 钩子），逐个列出捕获的信号与处理动作（清理临时文件？flush 缓冲区？直接终止？） |
| 10 | 并发/时序可观察语义 | 找到并发原语（goroutine/线程池/异步任务/锁/channel）产生的对外可观察结果点：输出顺序在并发下是否仍稳定、竞态窗口下的可能行为、超时与重试的可观察表现——这些点往往不在任何单一「路径」里，要单独找 |

## 二、逐面盘问问题集

对行为面×证据源矩阵的每一行，逐条过下列八问。每问后附一句「为什么代码不报错、答案却是错的」——这类问题的共同点是：它们不会让程序崩溃、不会触发任何测试失败，只会让调用方拿到一个看似正常、实际错误或残缺的结果。

1. **这个参数真的被解析代码读取了吗，还是只出现在 `--help`/schema 里？** 把调用方能传的入参全集与代码里实际提取的字段做差集，非空即是发现。——**为什么不报错**：未读取的参数不会触发解析错误，调用方以为传了就生效，其实那条分支从未被执行到。
2. **有没有硬编码的上限，超限时是明确报错还是悄悄截断/降级？** 条数、大小、深度、超时时长都要查。——**为什么不报错**：截断/降级本身是一次「成功」的执行路径，返回值格式完全正常，只是内容是不完整数据算出来的。
3. **默认值是否反直觉，即与调用方基于命名/文档的合理预期不一致？** 例如 `--timeout` 默认值单位、`--recursive` 默认开关方向。——**为什么不报错**：使用默认值本身就是「正常」路径，代码按设计执行，只是设计和调用方的心智模型对不上。
4. **错误是否被吞掉或压平成统一状态码/统一异常类型？** 对照原始错误来源（多个不同失败原因）与最终暴露给调用方的错误形态。——**为什么不报错**：压平后调用方依然拿到一个「合法」的错误响应，只是丢失了区分不同失败原因、从而选择正确重试/降级策略所需的信息。
5. **部分失败时对外表现是成功还是失败？** 例如批量操作里九成成功一成失败，最终返回码/响应体是否如实反映「部分」这个状态。——**为什么不报错**：如果部分失败被归类为整体成功，程序确实完整跑完了，返回码确实是 0，只是这个「成功」掩盖了未完成的那部分。
6. **多来源合并或集合遍历后的输出顺序，是有意契约还是语言运行时的偶然产物（如 map 迭代顺序）？** 查是否有显式 `sort`/`order by`，还是自然遍历结果。——**为什么不报错**：两种情况下程序都会正常吐出一个顺序，重写后顺序变了不会有任何异常抛出，只会让依赖顺序做展示或做 diff 的调用方悄悄拿到「变了」的结果。
7. **并发执行下这条行为面的可观察结果是否仍然稳定？** 同一输入并发调用多次，比较输出是否一致；查是否有共享可变状态、锁粒度、竞态窗口。——**为什么不报错**：竞态条件下的错误结果本身也是合法类型、合法格式的返回值，只在特定时序下才会显现，单次运行、大多数测试运行都看不出问题。
8. **时区、locale、字符编码的假设是否显式声明，还是依赖运行环境？** 时间戳序列化用 UTC 还是本地时区、数字格式化用哪个 locale、文本 I/O 默认哪种编码。——**为什么不报错**：换一个运行环境（换时区的机器、换 locale 的容器基础镜像）程序照常运行不抛异常，只是产出的时间戳/数字/文本换了一种读者看不出来但语义不同的表示。

### 与 29148 §9.6.12 的同构关系（【一手】）

ISO/IEC/IEEE 29148:2018 §9.6.12 Functions 五个子项【一手】原文（已在 `docs/brainstorms/2026-08-01-usecase-reconstruction-feasibility.md` §2.3（(b) 小节）核对存档，与 `usecase-reconstruction` 共享同一批证据，此处不再另行取材）：

> a) validity checks on the inputs;
> b) exact sequence of operations;
> c) responses to abnormal situations, including: overflow; communication facilities; hardware faults and failures; and error handling and recovery;
> d) effect of parameters;
> e) relationship of outputs to inputs, including input/output sequences and formulas for input to output conversion.

八问与五项的对应关系不是一一映射，而是五项在行为重建场景下的具体展开——列出来是为了让盘问有标准可回溯，不是为了凑数：

| 盘问问题 | 对应子项 | 备注 |
|---|---|---|
| 1 未读取的入参 | a) validity checks / d) effect of parameters | 参数校验与参数效果，前提都是参数先被读取 |
| 2 静默截断/降级 | c) responses to abnormal situations（overflow） | 29148 原文明确点名 overflow |
| 3 反直觉默认值 | d) effect of parameters | 默认值是「参数未显式给定时」的效果 |
| 4 错误吞没/压平 | c) error handling and recovery | 原文子项自带此措辞 |
| 5 部分失败的表现 | c) responses to abnormal situations（communication facilities / hardware faults） | 部分失败是异常情形的一种表现形式 |
| 6 顺序稳定性 | b) exact sequence of operations | 原文直接对应 |
| 7 并发语义 | b) exact sequence of operations（外延） | 29148 成文于顺序执行心智模型，未预见并发；此处是本 skill 在 b) 基础上的合理外延，如实标注为外延，不冒充原文覆盖 |
| 8 时区/locale/编码假设 | e) relationship of outputs to inputs（formulas for input to output conversion） | 时区/locale/编码转换正是一种输入到输出的转换公式 |

## 三、parity 维度展开（对等重写分流专用）

四组维度，与 SKILL.md「工作流」Step 2 逐字一致：**命令×输出模式**、**本地×远程**、**冷×热**、**成功×部分失败×硬失败**。

出处【一手，仓库内可确证】：`agent-spec` 仓库 `README.md:245-250`——

> For rewrite/parity work, the authoring path should explicitly bind observable behavior before coding:
> - command x output mode
> - local x remote
> - warm cache x cold start
> - success x partial failure x hard failure

对应中文措辞见同仓库 `src/main.rs` 的 `generate_rewrite_parity_template_zh` 函数：「在写代码前先梳理行为矩阵：命令 x 输出模式、local x remote、warm cache x cold start、成功 x 部分失败 x 硬失败」；具体场景实例见 `examples/rewrite-parity-contract.spec`。

每组一个展开示例行（示例行优先取自 `examples/rewrite-parity-contract.spec` 的实际场景文本；该 spec 未覆盖到的维度组合显式标注为缺口/待盘问，不杜撰它没有的场景。行为面矩阵里应把每个组合各自落一行，不是笼统写「支持 JSON 输出」）：

| 维度组 | 展开示例行 |
|---|---|
| 命令×输出模式 | `get`（human 输出）与 `get --json`（结构化输出）是两个独立行为面：前者断言 stdout 含文档正文、stderr 只作诊断；后者断言 stdout **只**含 JSON 且字段集合稳定（`id`/`type`/`content`）——两者必须分别验证，不能验证了一个就假定另一个同样成立 |
| 本地×远程 | 查找顺序 `local source -> cache -> bundled content -> remote fetch` 的每一步都是一个独立场景：本地命中时是否跳过缓存和远程；本地未命中时是否按声明顺序依次尝试，而不是直接跳到远程 |
| 冷×热 | 冷启动端是 `examples/rewrite-parity-contract.spec` 显式断言的场景（"cold start falls back to bundled content before remote fetch"）：Given no cached doc content and bundled content for the target entry，Then bundled content is returned，And no remote HTTP request is required。**热端该 spec 未显式反向断言**——human/json 两个场景虽以「cached doc content」为前提，但断言止步于返回内容，没有一条断言「因此没有发起远程请求」；这本身就是一处值得盘问的缺口：热缓存命中时「不重新拉取」是否也需要独立验证，还是被想当然地认为伴随 cache 命中自动成立 |
| 成功×部分失败×硬失败 | `examples/rewrite-parity-contract.spec` 只显式覆盖成功、硬失败两端：成功端见上一行（human/json 两个场景）；硬失败端是 "remote fetch failure returns a stable error" 场景——Given no cached or bundled content and the remote source returns HTTP 404，Then the command fails，And the error explains that the remote content could not be fetched。**该 spec 未覆盖部分失败**（远程返回但内容不完整/截断这类中间态）——重建时需单独盘问：上游是否存在这条路径？若存在，它被压平成与硬失败相同的错误，还是被当作成功返回了残缺数据？两种后果都不同，且都不能靠这份 spec 的测试覆盖率去反推「上游不存在这条路径」 |
