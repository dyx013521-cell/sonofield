# SonoField v3 — 双 EBAZ4205 同步与 PRE-PCB Serializer

本仓库为 SonoField v3 当前开发交付。**当前任务为 TASK-001C / PHASE-A：最小安全 PS7 配置前置核查。当前停在 `MINIMAL_PS7_NOT_READY / BLOCKED_PS_CLOCK_FACT / STOP_BEFORE_BITSTREAM`。** 原理图的 PS_CLK 是 E7/CLK，X8 的 33.333 MHz 候选路径经过标为 NC 的 R2340；实际两板 PS 时钟来源及频率未确立。N18/X5 的 50 MHz 是独立 PL 时钟，不能替代 PS_CLK。当前结果以 [Phase-A 报告](v3/evidence/task001c_ps7/MINIMAL_PS7_CONFIGURATION_REPORT.md)、[Release 状态](v3/evidence/task001c_ps7/PS7_RELEASE_STATUS.json) 和 [PS 硬件事实表](v3/docs/EBAZ4205_PS7_FACTS.md) 为准。

本轮只读打开两条 JTAG 目标并重新读取两个已有 routed checkpoint，核对每板 19 根阵列 IO 仍全部 Bank35 / LVCMOS33 / DRIVE4 / SLOW；N18、P5 和 P1/P2 引脚未变。用户已确认 Bank35 VCCO 实测 3.3 V、共地、VGA/Camera 已卸下，见 [当前硬件事实](v3/evidence/task001c_ps7/CONFIRMED_HARDWARE_FACTS.json)。原 LED 的 2 kohm 硬连线仍保留。Board1/Master JTAG `210299245711`、COM7；Board2/Slave JTAG `210299835073`，缺少 UART 是 OPTIONAL_DEBUG / NOT_BLOCKING。

用户本轮已授权在 Phase-A 严格放行后进行易失性 PL JTAG；目前门槛未通过，**PS7 未创建，Phase-B 未开始，没有新 bitstream、下载或实板 P5/Serializer 验收，READY_FOR_PCB_CONNECTION=false**。[Phase-B 未执行报告](v3/evidence/task001d_first_board/FIRST_VOLATILE_JTAG_REPORT.md)。未运行 PS init/FSBL，未修改任何启动介质。旧 [TASK-001B 报告](v3/evidence/task001b/PRE_PCB_SERIALIZER_REPORT.md) 和 STATUS JSON 保留原构建时快照，不能当作本轮 PS7 仿真/实现结果。每板 64 逻辑通道、16 lane、每 lane 4 bit、19 GPIO 的架构保持不变。

## 项目进展与阅读入口

- [当前进展、验收状态与下一步（PROGRESS.md）](PROGRESS.md)：建议从这里开始阅读，也作为 ChatGPT 分析项目的入口。
- [TASK-001B 完整报告](v3/evidence/task001b/PRE_PCB_SERIALIZER_REPORT.md)、[状态 JSON](v3/evidence/task001b/PRE_PCB_SERIALIZER_STATUS.json)、[Bank/VCCO](v3/evidence/task001b/BANK_VCCO_REPORT.md)。
- [完整 GPIO 池](v3/docs/ARRAY_GPIO_POOL.md)、[19 根引脚分配](v3/docs/SERIALIZER_PINMAP.md)、[Serializer 时序预算](v3/docs/SERIALIZER_TIMING_BUDGET.md)。
- [2026-10-02 双板硬件检测报告](v3/evidence/task001/DUAL_BOARD_HARDWARE_CHECK.md)：JTAG/UART、USB 拓扑、身份映射与上板准备度；[原始数据](v3/evidence/task001/hardware_check/)。
- [中文交接说明](v3/docs/HANDOFF.md)：复现命令、硬件参数缺口和实板验收顺序。
- [架构与同步协议](v3/docs/ARCHITECTURE.md)、[EBAZ4205 接线表](v3/docs/PINOUT.md)。
- [机器可读验证基线](v3/evidence/task001/SYNC_MODULE_BASELINE.json)、[仿真报告](v3/evidence/task001/simulation_report.md)、[时序及未关闭审查项](v3/evidence/task001/timing_report.md)、[硬件状态报告](v3/evidence/task001/hardware_report.md)。
- [RTL](v3/rtl/)、[测试平台](v3/tb/)、[Vivado 脚本](v3/vivado/)、[XDC 约束](v3/constraints/)、[全部证据](v3/evidence/task001/)。

固定硬件：**EBAZ4205 × 2，XC7Z010-1CLG400（Vivado: `xc7z010clg400-1`）**；主板 N18 / X5 输入 **50 MHz / 20 ns**。当前阶段先验证共享时间基准，再进入双板相控阵与运动控制。

本仓库上传的是独立 v3 同步工程，旧版参考工程 `loverlike1216/SonoField-FPGA` 的 v1/v2 成果不构成此双 EBAZ4205 工程的硬件验收证据。

## 构建与复现

TASK-001 builds a shared 50MHz time domain across two `xc7z010clg400-1` devices.
This baseline contains timing synchronization only: no acoustic array, phase solver, ADC or trajectory logic.

Use **PowerShell 7** and **Vivado 2025.2**:

```powershell
./v3/vivado/run_task001.ps1
```

当前 TASK-001B 复现入口（四项 RTL 回归、双板综合/实现及完整报告；不自动生成 bitstream 或 Program）：

```powershell
./v3/vivado/run_task001b.ps1
```

该任务采用独立 PRE-PCB 顶层，每板配置 64 bit × 1024 sample ILA，默认 `output_disable=1`。单帧诊断使用人工 Master S3 请求；在真实 P5 锁定及上板审查通过前，不执行诊断。每板计划连接 16 颗 SN74LVC595A，每颗使用 4 个输出；19 根信号按容量至少需要 3 颗 SN74AXC8T245，实际 PCB 分组与电气参数尚未确认。

The script executes RTL simulation, synthesis, implementation and timing analysis for separate
`ebaz_master` and `ebaz_slave` projects. Override the Vivado installation with `-VivadoBin` if needed.

- [中文交接说明](v3/docs/HANDOFF.md)
- [Architecture and protocol](v3/docs/ARCHITECTURE.md)
- [EBAZ4205 pin mapping](v3/docs/PINOUT.md)
- [Task evidence](v3/evidence/task001/)

Simulation and implementation results are distinct from board acceptance. IO timing budgets are provisional;
sub-cycle physical alignment and continuous operation beyond one hour require hardware measurements.
