# SonoField v3 · TASK-001C 当前交接

当前停止：**MINIMAL_PS7_NOT_READY / BLOCKED_PS_CLOCK_FACT / STOP_BEFORE_BITSTREAM**。以 [Phase-A 报告](../evidence/task001c_ps7/MINIMAL_PS7_CONFIGURATION_REPORT.md) 和 [Release JSON](../evidence/task001c_ps7/PS7_RELEASE_STATUS.json) 为准。PS7 未创建，Phase-B 未开始，未生成 bitstream 或 Program。

[PS7 事实表](EBAZ4205_PS7_FACTS.md) 记录 E7/CLK 专用 PS 时钟及 NC 的 R2340/X8 可选路径。需先确认实际两板 E7/CLK 来源/频率，再创建最小 PS7 配置；禁止把独立 N18/50 MHz 或常见 33.333 MHz 用作无依据默认值。当前 PS 采样启动模式未从 Hardware Manager 获取，现有固件 UNKNOWN；PL MODE/BOOT_STATUS/DONE 不能代替 PS boot evidence。

用户已确认 Bank35 实测 3.3 V、共地、VGA/Camera 卸下。新审计确认现有 19 GPIO 全部 Bank35，N18/P5/P1/P2 均未改。当前事实见 [CONFIRMED_HARDWARE_FACTS.json](../evidence/task001c_ps7/CONFIRMED_HARDWARE_FACTS.json)；旧 TASK-001B STATUS JSON 保留构建时历史状态。LED 的 2 kohm 硬负载和实际 P5/1 接线检查仍需注意，Bank35 电压结论不延伸到未测量的 PS/MIO/其他 Bank。

身份仍为 Master/210299245711/COM7 与 Slave/210299835073/UART OPTIONAL_DEBUG。本轮用户已明确授权严格 Phase-A 放行后的 volatile PL JTAG，取代旧交接的“另行授权”描述。该授权不包括 PS 初始化、FSBL、CPU 下载、永久启动介质写入或自动 PCB 测试。

当前只读复现（PowerShell 7；不更改板卡）：

```powershell
# 不覆盖既有硬件扫描，使用新的输出目录保存新观测。
& 'D:\amd2025_2\2025.2\Vivado\bin\vivado.bat' -mode batch -notrace -source v3/vivado/check_dual_hardware.tcl -tclargs D:/codex_project/sonofield/v3/build/prepcb_ps7/new_hardware_check
# 审计现有 TASK-001B 实现，不是新的 PS7 综合/实现。
& 'D:\amd2025_2\2025.2\Vivado\bin\vivado.bat' -mode batch -notrace -source v3/vivado/audit_ps7_preflight.tcl
```

本地已有两个 Vivado 窗口仍保留 TASK-001B routed checkpoint。Slave 当前显示 Design Timing Summary（setup 0.430 ns / hold 0.015 ns），它是旧实现页面，不是新 PS7 结果。新报告可以从上述入口阅读。[Phase-B 报告](../evidence/task001d_first_board/FIRST_VOLATILE_JTAG_REPORT.md) 明确记录所有未执行项目。

恢复开发顺序：确认 PS_CLK → 明确 IP 属性/专用边界 → 更新架构和关联接口测试 → 四项新仿真 → 两板新实现 → 新 DRC/STA/CDC/methodology 和 boot interference 审查 → Release Gate → 新 bit/ltx 和哈希 → serial/part 身份复核 → Slave/Master 易失性 PL JTAG → MMCM/P5 → 人工前三帧 ILA → P1/P2 示波器测量 → PCB 前停止。物理示波器数据不存在时不得宣布 FPGA_PRE_PCB_HARDWARE_VERIFIED 或 READY_FOR_PCB_CONNECTION。

下面保留 TASK-001B 历史接口、复现和诊断说明。其旧未确认事实/授权描述均以上方当前状态为准。

---

# TASK-001B 历史交接

当前任务是双板 Serializer 的 PCB 连接前准备；只允许诊断接口和共享时间基准的扩展。器件 `xc7z010clg400-1`、Master N18/X5=50 MHz / 20 ns、Vivado 2025.2、PowerShell 7 固定。当前门槛和最终数值见 [报告](../evidence/task001b/PRE_PCB_SERIALIZER_REPORT.md)、[状态 JSON](../evidence/task001b/PRE_PCB_SERIALIZER_STATUS.json)；准备度 false。无真实 P5/Serializer 验收，无声学或悬浮结论。

## 永久身份与接口

| 板卡 | 角色 | JTAG serial | UART |
|---|---|---|---|
| Board1 / A | Master | 210299245711 | COM7 |
| Board2 / B | Slave | 210299835073 | 未枚举；OPTIONAL_DEBUG / NOT_BLOCKING |

P5 保留全部同步网络和原示波器输出，包括其出现在 P2/P3 的别名。P1 是主阵列接口，P2/P3 是必要补充。当前每板 P1 使用 14 GPIO、P2 使用 5 GPIO、P3 使用 0 GPIO；总计 16 data + shift + latch + output_disable = 19。

每板 64 个逻辑通道 → 16 serial lane → 每 lane 4 bit → 16 颗 SN74LVC595A 各使用 4 个输出。两板共 128 通道，按信号容量每板至少 3 颗 SN74AXC8T245。实际 PCB Q 输出、VCCA/VCCB、OE/DIR、分组和是否还有额外缓冲器尚未确认。参考项目的 132/66 MHz 与 clock-only LVC244 结论不沿用。

[引脚表](SERIALIZER_PINMAP.md)、[GPIO 池](ARRAY_GPIO_POOL.md)、[机器映射](array_gpio_mapping.json)、[Bank/VCCO](../evidence/task001b/BANK_VCCO_REPORT.md) 是新顶层约束来源。P2 H20/J20/L19 复用 LED0/2/3，2 kohm 负载仍存在；K18/LED1 保留同步指示。使用这些网络前必须确认没有 camera/VGA 等并接外设。P1/P2 电源脚是 VCC_IN，不能接作逻辑 3.3 V。

## 本地复现和 GUI

```powershell
# PowerShell 7，仓库根目录
./v3/vivado/run_task001b.ps1
# 只跑四项仿真
./v3/simulation/run_task001b_xsim.ps1
```

默认工具路径 `D:\amd2025_2\2025.2\Vivado\bin`，其他环境通过 `-VivadoBin` 指定。入口执行四项回归、双板综合/布局布线、STA/CDC/DRC 等报告，运行前后核对源文件哈希。不生成 bitstream，不 Program，不修改启动介质。

项目在 `v3/build/prepcb/master/` 和 `slave/`；每板最新 routed.dcp 在 `v3/evidence/task001b/master/` 与 `slave/`，对应 .ltx 在 `v3/build/prepcb/`。这些本轮生成文件仅保存在本地，换电脑需要重建。批处理采用内存实现流程，GUI 应打开 routed.dcp；不能用未执行的 GUI synth_1/impl_1 标签推断批处理未运行。结束时保留打开的实现/时序结果页面。

## 设计边界与诊断

50 MHz 核心通过状态机生成 2.5 MHz shift burst，捕获全部 64 bit 后按 bit3/2/1/0 发四次 SRCLK，再统一 latch。shadow/active 分离；APPLY_AT 可预约共同逻辑 timestamp，提前量不足或 busy 重叠会故障。预约事务尚无 PREPARE/ACK_READY/COMMIT 双向确认，错误时不能假设双方提交成功。

独立 guard 与 Serializer FSM 分离，PRE-PCB 顶层将 arm 固定为 0，因此 `output_disable=1`。Master S3 的人工请求产生单帧；复位两板后序列依次为 ALL_ZERO、bit0 WALKING_ONE、1010、ALL_ONE、0101、bit0 WALKING_ZERO、counter。完整 walking 图样由仿真覆盖，上板诊断先验收前三帧。逻辑在第一次锁定后锁存致命事件；启动片段错误仍有计数，但不让历史训练计数永久阻止首次锁定后的测试。

ILA probe0 为 64 bit、深度 1024：31:0 timestamp，32 lock，33 alive，34 MMCM，35 RUN，36 fault，37 start，38 busy，39 done，40 overrun，56:41 data，57 shift，58 latch，59 disable，60 accepted APPLY，63:61 zero。复位释放复用核心 RUN，只有本地看门狗另有独立异步断言/同步释放链。失钟检测仍有看门狗窗口，必须实测。

## 后续上板门槛和顺序

1. 关闭 [Zynq 默认配置审查](../evidence/task001b/ZYNQ_CONFIGURATION_REVIEW.md)，审查 PS/PL 隔离、板卡配置和当前启动方式。不得为消除 ZPS7-1 随意加入其他板卡 preset。
2. 最终 DRC Error=0、CDC Critical=0、setup/hold 非负、关键未约束端点=0；复核方法学、时钟交互、IO 预算。禁止用虚假 false path 或 severity downgrade 掩盖问题。
3. 确认真实 PCB 未连接、板卡修订、VCCO/共地、无并接外设；按 [PINOUT](PINOUT.md) 核对 P5 CLK/DATA/VALID/RESET/LOCK/ECHO/GND。P5/2 是 3.3 V，不能当 GND；两板示波器输出禁止互接。
4. 所有门槛通过才生成对应 .bit。最新工程约束禁止自动下载；独立授权或人工下载时按 serial/part 匹配角色，仅做易失性 PL JTAG，禁止写 QSPI/Flash/eMMC/启动配置。
5. 先验证新程序 DONE/EOS/CRC、两板 MMCM/RUN 和真实 P5 锁定，再人工触发禁用输出下的前三个单帧并采集 ILA。Board2 UART 缺失不影响该步骤。
6. 示波器/逻辑分析仪测 serial_data[0]/[15]、shift、latch、disable 的幅度、边沿、建立/保持和 latch 位置；没有测量即 REQUIRES_PHYSICAL_MEASUREMENT。同步 Level 0–3 实板验收与 >1 小时长测也必须补齐。

本阶段停在 PCB 连接前。状态里的 PCB_CONNECTED=null 表示未知实物状态，false 的未执行门槛不代表测得故障。不得标记 READY_FOR_PCB_CONNECTION、PCB_VERIFIED、64/128_CHANNEL_HARDWARE_VERIFIED、ACOUSTIC_FIELD_VERIFIED 或 LEVITATION_VERIFIED，直到相应真实证据齐全。
