# SonoField v3 当前进展

整理日期：2026-10-02（Asia/Shanghai）。软件基线验证：2026-09-30；最新只读硬件检测：2026-10-02。
仓库：<https://github.com/dyx013521-cell/sonofield>。

## 当前结论

当前任务为 **TASK-001 / DUAL_BOARD_TIMING_SYNCHRONIZATION**。两块 EBAZ4205 的共享时钟、64 位时间戳、同步帧、预约复位/触发、失锁恢复及往返延迟计数已形成可复现的 RTL 基线。两套 RTL 仿真通过，Master / Slave 均完成综合与布局布线。

状态为 **SIMULATED / SYNTHESIZED / IMPLEMENTED**。**BOARD_TESTED / HARDWARE_VERIFIED 尚未达到**。不能据此宣称实板亚周期同步、超过一小时稳定运行、声场正确或悬浮成功。

首次 GitHub 同步核对了现有交付与 16 项源文件 SHA256，上传源码、测试、约束、构建脚本、报告、原始日志、硬件参考资料及综合/布局布线检查点。2026-10-02 后续完成了新的 Windows USB/UART 与 Vivado JTAG 只读检测；没有重跑仿真/综合/实现，没有生成或下载 bitstream，也没有物理测量。下文软件性能数值仍来自已归档基线。

## 最新硬件检测（2026-10-02）

新增 [双板硬件检测报告](v3/evidence/task001/DUAL_BOARD_HARDWARE_CHECK.md)、[原始证据](v3/evidence/task001/hardware_check/) 和 [机器可读结果](v3/evidence/task001/hardware_check/hardware-check-summary.json)。两个独立 JTAG target 均成功打开，每条链路识别一个 XC7Z010；另有各一个 ARM DAP，共 2 个 FPGA、4 个链上 hardware device。两个电缆 serial 为 `210299245711` 与 `210299835073`。

USB UART 目前仅发现 CH340 `COM7`，第二路未发现。检测后用户确认 **Board A=JTAG 210299245711 + COM7；Board B=JTAG 210299835073，UART 待发现**；Master/Slave 角色尚未指定。用户说明两路 JTAG 直连电脑、两路 UART 经扩展坞；系统逻辑父级不能完整证明物理端口，其中一路 JTAG 含 Hub 节点，不能据此猜测接线。当前仍为 **NOT_READY_FOR_BITSTREAM**，BOARD_TESTED / HARDWARE_VERIFIED 均为 false。下一步补齐 Board B UART、落实身份标签和角色、完成供电/VCCO/共地/P5 接线与启动/时序审查。

再次提供的 EBAZ4205 硬件说明与归档文件 SHA256 一致；其中设计资料与旧实验操作建议不替代当前工程规则或实板测量。

## 固定工程事实与架构

| 项目 | 当前约定 |
|---|---|
| 开发环境 | Vivado 2025.2，Build 6299465；PowerShell 7（交付环境 7.6.5） |
| FPGA | EBAZ4205 × 2；XC7Z010-1CLG400 / `xc7z010clg400-1` |
| 主时钟 | Master N18 / X5，50 MHz，`create_clock -period 20.000` |
| 共享时间基准 | Master 用 ODDR 转发 50 MHz；Slave 从 P5/7 → N20 接收，并以转发时钟驱动时间戳 |
| Slave 本地晶振 | 仅用于独立失钟看门狗，避免两个独立晶振各自维持时间戳 |
| 同步传输 | GPIO 源同步接口；144 bit 帧，含头、板号、命令、32 bit 序列、64 bit 时间戳与 CRC16 |
| 校准 | 往返延迟计数；单向估计依赖链路对称及已知周转延迟，不能替代亚周期实测 |

实际接线与引脚来源以 [PINOUT.md](v3/docs/PINOUT.md) 为准；电平、VCCO、板卡修订版、时钟与线缆参数仍需实物核对。UART 仅用于后续配置、调试和状态读取，不承担实时相控同步。

## 已完成模块

| 模块 | 当前功能 | 源码入口 |
|---|---|---|
| clk_manager | 50 MHz MMCM 管理 | [clk_manager.sv](v3/rtl/clock/clk_manager.sv) |
| timestamp_counter | 64 位计数、装载、共同清零及回绕 | [timestamp_counter.sv](v3/rtl/sync/timestamp_counter.sv) |
| sync_master | 同步快照、序列号、预约复位与触发 | [sync_master.sv](v3/rtl/sync/sync_master.sv) |
| sync_slave | 帧接收、偏差计算、锁定、错误处理及重新同步 | [sync_slave.sv](v3/rtl/sync/sync_slave.sv) |
| sync_protocol | 串行帧及 CRC16 | [sync_protocol.sv](v3/rtl/sync/sync_protocol.sv) |
| delay_measure | RTT 测量、超时及有条件单向估计 | [delay_measure.sv](v3/rtl/sync/delay_measure.sv) |
| sync_button / dual_sync_top | 5 ms 按键去抖、主从物理接口、失钟看门狗及输出安全门控 | [sync_button.sv](v3/rtl/sync/sync_button.sv)、[dual_sync_top.sv](v3/rtl/top/dual_sync_top.sv) |

## 已归档验证证据

| 检查 | 结果 | 证据 |
|---|---|---|
| 协议 RTL 仿真 `dual_sync_tb` | PASS，34 项检查，264138 次时间戳对齐观察 | [simulation_report.md](v3/evidence/task001/simulation_report.md)、[xsim.log](v3/evidence/task001/xsim.log) |
| 顶层仿真 `top_clock_tb` | PASS，6 项检查，9405 次对齐观察 | [xsim-top.log](v3/evidence/task001/xsim-top.log) |
| Master 综合 / 实现 | SYNTHESIZED / IMPLEMENTED | [synthesis_report.md](v3/evidence/task001/synthesis_report.md)、[build-results.tsv](v3/evidence/task001/build-results.tsv) |
| Slave 综合 / 实现 | SYNTHESIZED / IMPLEMENTED | 同上 |
| Master 时序 | Setup WNS 0.936 ns；Hold WHS 0.006 ns；CDC critical 0 | [timing_report.md](v3/evidence/task001/timing_report.md)、[Master timing.rpt](v3/evidence/task001/ebaz_master/timing.rpt) |
| Slave 时序 | Setup WNS 0.199 ns；Hold WHS 0.052 ns；CDC critical 0 | [Slave timing.rpt](v3/evidence/task001/ebaz_slave/timing.rpt) |
| 2026-09-30 历史硬件扫描 | 当时发现 0 个可访问 JTAG 目标；未下载 FPGA | [hardware_report.md](v3/evidence/task001/hardware_report.md)、[hardware_probe.txt](v3/evidence/task001/hardware_probe.txt) |
| 2026-10-02 最新硬件扫描 | 2 个 target、2 个 XC7Z010；USB UART 仅 COM7；未下载 FPGA | [DUAL_BOARD_HARDWARE_CHECK.md](v3/evidence/task001/DUAL_BOARD_HARDWARE_CHECK.md) |

覆盖 CRC 错误、重复/缺失帧、随机链路延迟、共同清零/触发、超时及恢复；顶层测试包括本地晶振相差 100 ppm 与转发时钟断开/恢复。

仿真约执行 1.395 ms 和 0.370 ms 模型时间。“一小时测试”仅将真实计数器装载到一小时计数边界附近并跨越该边界，**不是完整一小时耐久仿真或实板长测**。顶层行为仿真绕过 MMCM/ODDR，未验证模拟相位、抖动或带 SDF 的布局布线网表。

## 验收等级与当前缺口

| 等级 | 实板目标 | 当前状态 |
|---|---|---|
| Level 0 | 双板实体同步链路通信 | RTL 已仿真；实板待验收 |
| Level 1 | 时间戳误差 < 1 时钟周期 | 仿真整数周期对齐；实板误差及亚周期偏斜待测 |
| Level 2 | 同时输出 GPIO 波形，以示波器验证 | 预约触发已有仿真；双通道示波器证据待采集 |
| Level 3 | 连续运行 > 1 小时，无 lost sync / drift | 待执行完整实板长测 |

时序满足当前分析预算不等于硬件签核：Master hold 余量仅 0.006 ns；Slave 尚有 TIMING-6 / TIMING-7 Critical Warning；两板仍有 TIMING-18 / TIMING-28 审查项及 PS7 默认配置相关问题。独立看门狗与接收时钟物理异步，相关 STA 正余量不能证明实物时钟同相。详见 [timing_report.md](v3/evidence/task001/timing_report.md) 与各板 `methodology.rpt`。

预约事件尚无双向确认事务；链路错误可能导致双方命令未共同提交。失钟检测存在看门狗检测窗口。RTT 单向延迟估计依赖对称假设与周转参数。这些边界见 [ARCHITECTURE.md](v3/docs/ARCHITECTURE.md)。

## 开发顺序与下一步

| 步骤 | 当前进度 |
|---|---|
| 1. 建立 v3 双 EBAZ Vivado 工程 | 完成源码与可复现脚本，两个独立顶层已综合/实现 |
| 2. 单板 50 MHz 时钟系统 | 完成 RTL 与实现，实际时钟/抖动/锁定待测 |
| 3. 双板同步接口 | 完成 RTL、约束和仿真，实体连接待验收 |
| 4. timestamp 同步 | 完成仿真逻辑对齐，实板一致性待测 |
| 5. 同步验证 | 软件证据已归档，Level 0–3 实板验收待完成 |
| 6. 双板相控阵控制 | 未开始；规划 128 通道，两板各 64 通道 |
| 7. 空间运动控制 | 未开始 |
| 8. 声学实验 | 未开始 |

下一步继续 TASK-001：确认两块板身份和可用 JTAG 目标，核对供电/VCCO/共地/时钟/接线；审查启动配置、IO 预算及方法学告警；之后生成并下载对应 bitstream，完成通信、复位/触发、示波器偏斜、断链恢复和超过一小时稳定性验收，保存原始测量资料。

遇到问题按 Hardware Fact → Architecture → RTL Bug → Constraint Bug 排查。同步实板验证完成后再进入相控阵与运动控制，优先稳定性及相位精度。

## 复现与版本溯源

```powershell
# PowerShell 7，仓库根目录
./v3/simulation/run_xsim.ps1
./v3/vivado/run_task001.ps1
# 其他 Vivado 安装路径通过 -VivadoBin 指定
```

源码与交付的原始本地提交分别为 `e0cc3a6412ea2559e698ffe13aa403de790279f1` 和 `f42f4811ec73bebb5e8b50ec4ad763d0dd6b60cb`。由于此次通过 GitHub API 发布文件快照，远端发布提交与原始本地提交哈希不同；原始哈希是来源标识，不应当作远端同名提交链接。原始完整历史仍保存在本地仓库和此前生成的 `SonoField-v3-TASK001.bundle` 中。

[SYNC_MODULE_BASELINE.json](v3/evidence/task001/SYNC_MODULE_BASELINE.json) 保留验证工具、状态、资源、未关闭审查项和 16 项源文件 SHA256。`attempt01/`、`attempt02/`、`attempt03/` 保存早期失败/修正证据，不代表最终结果。综合与布局布线 DCP 已归档；本阶段没有发布用于硬件验收的 bitstream。

归档输入材料 `v3/docs/EBAZ4205_硬件说明.md` 中引用的三张 `assets/` 配图未包含在原交付中，因此相关图片链接仍缺附件；材料原文保留，已上传的两份 PDF 原理图可从 `v3/docs/references/` 查阅。该输入材料内的旧工具版本与硬件推断不取代本项目的 Vivado 2025.2 约定或实物核对要求。

## 给 ChatGPT 的项目阅读提示

> 请阅读 GitHub 仓库 dyx013521-cell/sonofield，先读 PROGRESS.md 和 README.md，再读 v3/docs/HANDOFF.md、ARCHITECTURE.md、PINOUT.md 及 v3/evidence/task001/SYNC_MODULE_BASELINE.json。分析当前 TASK-001 的完成项、剩余时序/约束问题和实板验收计划。请严格区分 SIMULATED、SYNTHESIZED、IMPLEMENTED、BOARD_TESTED、HARDWARE_VERIFIED，不把仿真计数边界测试当作一小时稳定性测试，也不要推断悬浮成功。
