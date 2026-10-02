# SonoField v3 — Dual EBAZ4205 Timing Synchronization

本仓库为 SonoField v3 当前开发交付。**截至 2026-10-02，TASK-001 双板时间同步已达到 SIMULATED / SYNTHESIZED / IMPLEMENTED；BOARD_TESTED / HARDWARE_VERIFIED 尚未完成。** 软件基线来自 2026-09-30。最新只读检测发现两个 JTAG target、两个 XC7Z010 和一路 USB UART（COM7）。用户确认 A=245711+COM7、B=835073；Board B UART、角色指定、电气核对及上板审查待完成，准备度为 NOT_READY_FOR_BITSTREAM。

## 项目进展与阅读入口

- [当前进展、验收状态与下一步（PROGRESS.md）](PROGRESS.md)：建议从这里开始阅读，也作为 ChatGPT 分析项目的入口。
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

The script executes RTL simulation, synthesis, implementation and timing analysis for separate
`ebaz_master` and `ebaz_slave` projects. Override the Vivado installation with `-VivadoBin` if needed.

- [中文交接说明](v3/docs/HANDOFF.md)
- [Architecture and protocol](v3/docs/ARCHITECTURE.md)
- [EBAZ4205 pin mapping](v3/docs/PINOUT.md)
- [Task evidence](v3/evidence/task001/)

Simulation and implementation results are distinct from board acceptance. IO timing budgets are provisional;
sub-cycle physical alignment and continuous operation beyond one hour require hardware measurements.
