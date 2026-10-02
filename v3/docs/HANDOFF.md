# SonoField v3 · TASK-001B 交接说明

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
