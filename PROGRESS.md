# SonoField v3 当前进展

更新日期：2026-10-02。仓库：https://github.com/dyx013521-cell/sonofield。

**当前阶段：TASK-001C / PHASE-A。状态：MINIMAL_PS7_NOT_READY；BLOCKED_PS_CLOCK_FACT；STOP_BEFORE_BITSTREAM。** Phase-B 未开始，READY_FOR_PCB_CONNECTION=false。

本轮已完成原理图 PS 时钟/复位、MIO、NAND、DDR、启动选项审查，以及两板只读 JTAG 检测和现有已实现设计的引脚复核。问题是：PS_CLK 位于专用 E7/CLK，X8 标注 33.333 MHz 的候选路径通过 NC 的 R2340；当前资料未证明实际 PS 时钟的来源和频率。N18/X5=50 MHz 是单独的 PL 时钟，不能借用作为 PS7 配置参数。该任务的 A12 和停止规则要求对此停止放行。

| 本轮结果 | 状态与依据 |
|---|---|
| 两板身份 | 210299245711→Master；210299835073→Slave；2 个 XC7Z010、4 个链设备、0 探测错误 |
| 当前阵列引脚 | 重新读取两个 TASK-001B routed checkpoint；每板 19 根全部 Bank35 / LVCMOS33 / DRIVE4 / SLOW |
| Bank35 电压 | 用户确认实测 3.3 V；BANK_VCCO_MEASURED=true，BANK_VCCO_PASS=true，限当前未改变的 19 根 Bank35 IO |
| 共地 / 外设 | COMMON_GROUND_CONFIRMED=true；VGA_MODULE_ATTACHED=false；CAMERA_MODULE_ATTACHED=false；原 LED/电阻负载仍存在 |
| N18 / P5 / P1/P2 | 映射全部未变；N18 50 MHz；P5 永久同步；每板 P1 14 + P2 5 GPIO |
| 现有配置只读状态 | 两板 DONE/EOS=1、CRC_ERROR=0；并非本任务下载结果 |
| 当前 PS Boot Mode | UNKNOWN；Hardware Manager 未暴露 PS BOOT_MODE 采样寄存器；PL MODE=111 不代替它 |
| 当前固件 | UNKNOWN；可能初始化 MIO/DDR/SLCR，但未观察，不得标为 NONE 或 CONFIRMED |
| PS7 实例 / ZPS7-1 | PS7 未创建；ZPS7-1 未关闭；无 preset、频率猜测或告警降级 |
| 本轮仿真 / 综合 / 实现 | 未执行；已有 TASK-001B 结果只作为历史基线，不能顶替 Phase-A 的新结果 |
| Phase-B | 未生成 .bit，未 Program，未采集 P5/Serializer ILA，未测 P1/P2 物理输出 |
| PCB 实际连接 | 软件不可确认，PCB_CONNECTED=null；PCB_CONNECTION_REQUIRES_USER_CONFIRMATION |

当前阅读入口：

- [Phase-A 完整报告](v3/evidence/task001c_ps7/MINIMAL_PS7_CONFIGURATION_REPORT.md)、[Release JSON](v3/evidence/task001c_ps7/PS7_RELEASE_STATUS.json)、[当前硬件事实](v3/evidence/task001c_ps7/CONFIRMED_HARDWARE_FACTS.json)。
- [EBAZ PS7 事实表](v3/docs/EBAZ4205_PS7_FACTS.md)、[启动模式](v3/evidence/task001c_ps7/BOOT_MODE_REPORT.md)、[PS/PL 边界](v3/evidence/task001c_ps7/PS_PL_BOUNDARY_REPORT.md)。
- [Phase-B 未执行报告](v3/evidence/task001d_first_board/FIRST_VOLATILE_JTAG_REPORT.md)、[状态](v3/evidence/task001d_first_board/FIRST_VOLATILE_JTAG_STATUS.json)。
- [本轮 38 行引脚审计](v3/evidence/task001c_ps7/current-pin-audit.tsv)、[两板只读状态](v3/evidence/task001c_ps7/board-read-only-status.json)、[交接说明](v3/docs/HANDOFF.md)。

下一步先补实际两板 E7/CLK 的时钟来源、频率及 X8/R2340 或替代接法证据。随后创建可复现最小 PS7、审查专用接口/DDR/启动固件边界，重新执行四项仿真和双板综合/实现，检查新 DRC/STA/CDC/methodology；仅达到 READY_FOR_FIRST_VOLATILE_JTAG_BITSTREAM 才进入易失性 JTAG 和实板验收。用户已授权该条件下的 PL JTAG，无需再次请求同一下载授权。Board2 UART 不阻塞。

以下为 TASK-001B 原构建历史快照。其“未确认 VCCO/外设”和当时的“禁止自动 Program”描述仅记录当时状态；本轮用户事实和条件授权由上方 TASK-001C 结果取代。旧状态 JSON 不作为当前电气事实来源。

---

# SonoField v3 TASK-001B 历史基线

更新日期：2026-10-02。仓库：https://github.com/dyx013521-cell/sonofield。

当前任务为 **TASK-001B / DUAL_BOARD_SERIALIZER_PRE_PCB_BRINGUP**。当前源码、四项仿真、两个独立顶层的综合/布局布线和完整 STA/CDC/DRC 证据见 [PRE_PCB_SERIALIZER_REPORT.md](v3/evidence/task001b/PRE_PCB_SERIALIZER_REPORT.md)；最终数值和各项门槛见 [PRE_PCB_SERIALIZER_STATUS.json](v3/evidence/task001b/PRE_PCB_SERIALIZER_STATUS.json) 与 [build-results.tsv](v3/evidence/task001b/build-results.tsv)。历史 TASK-001 报告用于追溯，不代表当前扩展设计的结果。

**当前不具备 PCB 连接条件：READY_FOR_PCB_CONNECTION=false。** 本轮没有生成或下载 bitstream，没有实板 P5 同步/Serializer 波形验收，也没有写入任何启动介质。最新工程约束禁止自动 Program。只读 JTAG 检测成功与仿真通过均不等于 BOARD_TESTED / HARDWARE_VERIFIED。

## 固定硬件与身份

| 项目 | 当前约定 |
|---|---|
| 工具 / 器件 | Vivado 2025.2；PowerShell 7；`xc7z010clg400-1` |
| Board1 / A | Master；JTAG `210299245711`；UART COM7 |
| Board2 / B | Slave；JTAG `210299835073`；UART 未枚举，OPTIONAL_DEBUG / NOT_BLOCKING |
| 时间基准 | Master N18 / X5 = 50 MHz / 20 ns；ODDR 转发到 Slave P5/7 / N20 |
| Slave N18 晶振 | 独立失钟看门狗，不维持第二套全局时间 |
| 每板逻辑通道 | 64；16 独立 serial lane；每 lane 4 bit；两板共 128 |
| 每板阵列 GPIO | 16 data + 1 shift + 1 latch + 1 output_disable = 19 |
| 连接器策略 | P1 优先：14 GPIO；P2 补 5 GPIO；P3 未使用；所有 P5 及其别名保留 |
| 计划 PCB 接口 | 每板 16 颗 SN74LVC595A，每颗使用 4 个输出；按容量至少 3 颗 AXC8T245 |

每次打开硬件目标必须按电缆 serial 匹配角色，不能根据 target 索引猜测。新只读扫描识别两条目标、两个 XC7Z010、四个链上设备，错误为 0，见 [board-identity.json](v3/evidence/task001b/board-identity.json) 和 [原始扫描状态](v3/evidence/task001b/hardware_check/vivado-probe-status.tsv)。已有器件 DONE/EOS 值不能证明当前源码已下载。

## 本轮完成的工作

- 按两份 EBAZ 原理图和 Vivado 器件数据库审计 P1/P2/P3 全部针脚，排除电源、地、NC、MIO 和全部 P5 别名。[完整 GPIO 池](v3/docs/ARRAY_GPIO_POOL.md)、[引脚表](v3/docs/SERIALIZER_PINMAP.md)、[机器映射](v3/docs/array_gpio_mapping.json)。
- 每板分配 19 GPIO，全部 Bank35 / LVCMOS33 / DRIVE4 / SLOW。P2 的 H20/J20/L19 复用原 LED0/2/3 网络，已有 2 kohm LED 负载明确保留；K18 / LED1 显示同步锁定。未把按键网络作为输出。
- 实现 64 bit shadow capture、16 lane bit3→2→1→0 发送、四次 shift、统一 latch、busy/done/overrun 及预约 APPLY_AT。50 MHz 状态机生成 2.5 MHz shift burst，未增加高频 MMCM。
- 独立安全 guard，PRE-PCB 顶层始终保持 `output_disable=1`。人工 Master S3 只请求单帧；默认不产生连续 shift/latch。同步故障、超时、重叠或截止时间不足会撤销安全许可。
- 每板加入 64 bit × 1024 sample ILA。阵列逻辑和 ILA 使用同步后的状态；独立看门狗保留异步安全断言。Serializer 复用核心 RUN 的复位释放，避免两条释放链重汇合。
- 重新运行 `dual_sync_tb`、`top_clock_tb`、`serializer64_tb`、`dual_serializer_sync_tb`。595 模型按完整 8 bit 寄存器实现，仅检查各颗 Q0..Q3；随机数据、walking-one/zero、发送途中故障及双板预约 latch 均纳入验证。
- 双板分别完成 synth / opt / place / phys_opt / route，以及 setup、hold、CDC、DRC、methodology、IO、clock interaction 和利用率报告。[最终证据目录](v3/evidence/task001b/)。

仿真共验证 388 个重建帧；双板测试比较相同逻辑 timestamp 下的七次 latch，并检查发送中复位和失钟。具体 PASS 计数以最新报告为准。行为仿真不验证真实 MMCM 相位/抖动、IO 波形或带 SDF 的网表。历史一小时计数边界测试不等于连续一小时运行。

[Serializer 时序预算](v3/docs/SERIALIZER_TIMING_BUDGET.md) 的结论仅为 PRE_PCB_TIMING_ESTIMATE：200 ns 逻辑 setup/hold/pulse；无预约等待时下一帧最早在第 93 周期启动，即 1.86 µs / 537634 frame/s。未来更新率 U 至少需要 4U shift edge/s，另加 latch 等开销；没有给定声学更新率，也没有实测 PCB/translator 延迟。

## 未关闭的验收门槛

[Zynq 配置审查](v3/evidence/task001b/ZYNQ_CONFIGURATION_REVIEW.md) 保留 ZPS7-1 默认配置告警：尚无针对这两块实际板卡、启动固件和 PS/PL 隔离状态的审查证据。不能仅为了消除告警添加不明 PS7 preset，DRC Error=0 也不能替代此审查。

Bank35 的 3.3 V 来源已追溯到原理图，但实际 VCCO、板卡修订版、外设占用、P5 六根信号及共地仍未实物确认。P1/P2 电源脚 1/2 是 VCC_IN，不能当作 3.3 V 阵列 GPIO。PCB 实际连接状态未知，状态 JSON 用 null 记录，不能根据 JTAG 推断未连接。Board2 UART 缺失不阻止后续 JTAG/ILA 调试。

| 实板目标 | 当前状态 |
|---|---|
| Level 0：P5 实体同步链路通信 | 待验收 |
| Level 1：时间戳误差 < 1 cycle | 逻辑仿真通过；实板待测 |
| Level 2：预约同时输出波形 | 逻辑仿真通过；双通道示波器待测 |
| Level 3：> 1 小时无失锁/漂移 | 待完整实板长测 |
| Serializer PRE-PCB：真实 ILA 单帧 | 待安全配置及上板门槛关闭后执行 |
| AXC/595/PCB/声学/悬浮 | 均未验证 |

先关闭 Zynq 配置和所有实现审查项，确认板卡/电气/P5 与 PCB 未连接，再生成 bitstream。下载另属人工或独立授权阶段，限制为易失性 PL JTAG；后续先验证 MMCM/RUN/真实 P5 锁定，再采集禁用输出条件下的单帧 ILA。PCB 连接就绪必须由真实测试支持。同步实板验收前不进入声场求解、轨迹、ADC、声学实验或 v4。

## 复现与追溯

```powershell
# PowerShell 7，仓库根目录；默认 Vivado D:\amd2025_2\2025.2\Vivado\bin
./v3/vivado/run_task001b.ps1
```

早期 Slave route 的 CRC 输入路径 setup 为 −0.099 ns，额外物理优化仍未改善，失败摘要保存在 attempt03/attempt04。当前 RTL 在既有 VALID 撤销提交周期比较已寄存的完整 CRC，保持协议及 146 周期补偿不变；最终数值只取该修正后的完整重跑。

构建入口检查运行前后源文件 SHA256 一致。当前 [source-sha256.json](v3/evidence/task001b/source-sha256.json) 对应最新仿真/实现；历史 [TASK-001 基线](v3/evidence/task001/SYNC_MODULE_BASELINE.json) 保留原版本哈希，不能用于声称当前修改后的源文件未变化。失败尝试只保留追溯摘要，详细报告与 DCP 留在本地；GitHub 发布当前源代码、测试、约束和最终文本证据。`v3/build/`、本轮 DCP 和无关 Windows USB 全量信息不进入此次发布，换电脑可按脚本重建。

## 给 ChatGPT 的项目阅读提示

> 请阅读 dyx013521-cell/sonofield，先读 PROGRESS.md、README.md 和 v3/evidence/task001b/PRE_PCB_SERIALIZER_REPORT.md，再读同目录 STATUS JSON、Bank/VCCO 报告、v3/docs/HANDOFF.md、ARCHITECTURE.md、PINOUT.md、SERIALIZER_PINMAP.md 和 SERIALIZER_TIMING_BUDGET.md。分析 TASK-001B 的源码、GPIO、时序/CDC、Zynq 配置及实板验收缺口。严格区分仿真、综合、实现、实板测试和硬件验证；不要推断 PCB 已接入、真实同步、声场正确或悬浮成功。
