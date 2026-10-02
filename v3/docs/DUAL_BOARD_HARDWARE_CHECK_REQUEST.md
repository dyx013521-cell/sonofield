你现在位于 SonoField v3 项目仓库中。

项目：

- Repository: `dyx013521-cell/sonofield`
- Active version: `v3`
- 当前阶段：`TASK-001 / DUAL_BOARD_TIMING_SYNCHRONIZATION`
- FPGA 板卡：EBAZ4205 × 2
- FPGA 型号预期：`XC7Z010-1CLG400`
- Vivado part：`xc7z010clg400-1`
- Vivado：2025.2
- 自动化环境：PowerShell 7

当前两块 EBAZ4205 已完成基础连接。

## 当前实际 USB 连接拓扑

请严格按照下面的真实连接关系理解硬件，不要混淆 UART 与 JTAG：

```text
电脑
│
├── USB 直连接口 1
│      └── Board A JTAG
│
├── USB 直连接口 2
│      └── Board B JTAG
│
└── USB 拓展坞
       ├── Board A UART
       └── Board B UART
```

即：

```text
UART1 → USB拓展坞 → 电脑
UART2 → USB拓展坞 → 电脑

JTAG1 → 电脑原生USB口直连
JTAG2 → 电脑原生USB口直连
```

非常重要：

**两块板子的 JTAG 都没有经过 USB 拓展坞。**

因此如果 Vivado Hardware Manager 无法发现 JTAG target：

不要优先把问题归因于 USB 拓展坞。

JTAG 故障应优先排查：

```text
电脑原生 USB
→ JTAG 下载器
→ 驱动
→ hw_server
→ JTAG 线路
→ EBAZ4205
```

USB 拓展坞相关问题主要影响：

```text
UART1
UART2
COM 端口
USB Serial 枚举
串口稳定性
```

---

# 一、任务目标

调用 Vivado 2025.2 Hardware Manager，对当前连接的两块 EBAZ4205 做一次完整、只读、可复现的硬件检测。

本任务主要解决：

1. 电脑是否识别两个 JTAG 下载器。
2. Vivado 是否发现两个独立 Hardware Target。
3. 两块 EBAZ4205 是否都能被识别。
4. 两块 FPGA 实际型号是否与 `XC7Z010` 预期一致。
5. 两个 UART 是否均正常枚举为独立 COM 设备。
6. 是否可以建立：

```text
JTAG1 ↔ UART1 ↔ Board A

JTAG2 ↔ UART2 ↔ Board B
```

的稳定映射。

7. 当前还缺少哪些实板参数。
8. TASK-001 第一次 bitstream 上板前还需要解决哪些问题。
9. 对后续上板调试给出明确的下一步分析和优化建议。

---

# 二、安全限制

本任务仅允许：

> Hardware detection + inventory + diagnosis + readiness analysis

禁止：

- 自动下载 bitstream
- Program FPGA
- 写 Flash
- 写寄存器
- 修改 FPGA 状态
- 自动复位板卡
- 自动修改 RTL
- 自动修改 XDC
- 为了“通过检测”而降低 DRC 严重级别
- 添加错误 false path
- 修改现有同步架构

本阶段只观察。

最终必须生成：

`v3/evidence/task001/DUAL_BOARD_HARDWARE_CHECK.md`

---

# 三、首先阅读项目资料

开始检测前，必须先阅读：

- `AGENTS.md`
- `PROGRESS.md`
- `README.md`
- `v3/docs/HANDOFF.md`
- `v3/docs/ARCHITECTURE.md`
- `v3/docs/PINOUT.md`
- `v3/evidence/task001/hardware_report.md`
- `v3/evidence/task001/timing_report.md`
- `v3/evidence/task001/SYNC_MODULE_BASELINE.json`

必须理解：

当前 TASK-001 已经达到：

```text
SIMULATED
SYNTHESIZED
IMPLEMENTED
```

但尚未达到：

```text
BOARD_TESTED
HARDWARE_VERIFIED
```

这次硬件枚举成功也不能直接改变这两个状态。

---

# 四、检查电脑 USB 拓扑

先通过 Windows / PowerShell 7 读取当前 USB 设备。

至少执行：

```powershell
$PSVersionTable.PSVersion

Get-PnpDevice -PresentOnly

Get-CimInstance Win32_USBControllerDevice

Get-CimInstance Win32_SerialPort

Get-CimInstance Win32_PnPEntity |
    Where-Object {
        $_.Name -match "Xilinx|AMD|FTDI|JTAG|USB Serial|UART|COM"
    }
```

如果条件允许，进一步读取：

```text
InstanceId
PNPDeviceID
VID
PID
Serial Number
Parent USB device
Location Path
COM port
FriendlyName
```

目标是区分：

```text
原生 USB 直连 JTAG

与

拓展坞下挂 UART
```

---

# 五、USB 拓扑必须在报告中明确体现

报告中必须形成类似：

| 设备 | 连接方式 | Windows状态 | Vivado状态 |
|---|---|---|---|
| JTAG1 | 电脑原生USB直连 | | |
| JTAG2 | 电脑原生USB直连 | | |
| UART1 | USB拓展坞 | | N/A |
| UART2 | USB拓展坞 | | N/A |

如果能够读取 USB Parent / Location Path：

必须尝试证明：

```text
UART1
UART2
```

位于同一个 USB Hub / Dock 层级下。

同时检查：

```text
JTAG1
JTAG2
```

是否位于电脑原生 USB Controller 路径。

如果系统无法可靠判断物理 USB 端口：

写：

`USB_PHYSICAL_PORT_MAPPING_REQUIRES_MANUAL_CONFIRMATION`

不能猜测。

---

# 六、检查 UART

当前两块 UART 都通过拓展坞连接。

重点检查：

```text
COM port 数量
COM编号
设备名称
VID/PID
USB Serial Number
PNPDeviceID
Location Path
```

至少确认是否发现两个独立串口。

最终输出：

```text
UART_DEVICE_COUNT=
UART1_COM=
UART2_COM=
UART_MAPPING_CONFIDENCE=
```

如果只有一个 COM：

重点分析：

```text
拓展坞USB端口
USB串口驱动
Type-C/UART转换器
供电
数据线
设备枚举冲突
```

如果两个串口均存在：

不要因此宣称 UART 通信成功。

只能写：

```text
UART_ENUMERATION_OK
```

真正的数据收发还需要后续串口测试。

---

# 七、UART 稳定身份

如果 UART 芯片提供唯一 USB Serial Number：

优先使用：

```text
VID
PID
Serial Number
```

建立永久映射。

不要长期依赖：

```text
COM3
COM4
```

因为插拔后 COM 编号可能改变。

推荐形成：

```text
UART_A_ID = VID/PID/SERIAL
UART_B_ID = VID/PID/SERIAL
```

如果两个 UART 转换器没有唯一 Serial Number：

报告必须指出：

`UART_PERSISTENT_MAPPING_NOT_AVAILABLE`

后续需要结合：

- USB Location Path
- 物理标签
- 单板 UART 输出

建立稳定映射。

---

# 八、调用 Vivado Hardware Manager

建立：

`v3/vivado/check_dual_hardware.tcl`

该脚本必须只读。

基本流程：

```tcl
open_hw_manager

connect_hw_server -allow_non_jtag

set targets [get_hw_targets]

puts "HW_TARGET_COUNT=[llength $targets]"

foreach target $targets {

    puts "================================="
    puts "TARGET=$target"
    puts "================================="

    catch {
        report_property $target
    }

    catch {
        current_hw_target $target
        open_hw_target

        set devices [get_hw_devices]

        puts "DEVICE_COUNT=[llength $devices]"

        foreach dev $devices {

            puts "---------------------------------"
            puts "DEVICE=$dev"
            puts "---------------------------------"

            catch {
                report_property $dev
            }
        }
    }
}
```

根据 Vivado 2025.2 实际 API 可以增强，但：

不要假设 target 名称。

不要假设 cable 顺序。

不要假设：

```text
target 0 = Master
target 1 = Slave
```

---

# 九、特别注意两个 JTAG 都是电脑直连

当前物理关系为：

```text
PC Native USB
 ├─ JTAG1
 └─ JTAG2
```

因此理想情况下 Vivado 应发现：

```text
HW_TARGET_1
HW_TARGET_2
```

并分别发现：

```text
XC7Z010
XC7Z010
```

但不要假设一定如此。

可能出现：

### 情况 A

```text
2 JTAG targets
2 FPGA devices
```

这是当前期望状态。

### 情况 B

```text
2 JTAG USB devices
1 Vivado hw_target
```

重点检查：

- 一个 cable 是否被占用
- hw_server 是否只绑定其中一个
- 驱动
- cable firmware
- JTAG wiring
- Board power

### 情况 C

```text
1 JTAG USB device
```

重点检查：

```text
电脑原生USB口
USB线
下载器
驱动
第二块板供电
```

不要优先检查拓展坞。

因为 JTAG 没经过拓展坞。

### 情况 D

```text
2 JTAG devices
2 targets
只有1个XC7Z010
```

说明：

USB 层正常，但某一路：

```text
JTAG cable → FPGA
```

之间有问题。

### 情况 E

```text
TARGET_COUNT=0
```

优先排查：

```text
Vivado hw_server
      ↓
AMD/Xilinx cable driver
      ↓
电脑原生USB
      ↓
JTAG1 / JTAG2
      ↓
EBAZ4205
```

---

# 十、记录 FPGA 信息

对每个 FPGA 尽量记录：

```text
Hardware Target
Cable
Device index
JTAG chain position
Device name
Part
Family
Architecture
IDCODE
Device state
PROGRAM.FILE
PROBES.FILE
```

如果可以只读获取：

```text
DNA
unique identifier
boot/config state
```

则保存。

如果必须 Program 后才能得到：

写：

`NOT_AVAILABLE_WITH_READ_ONLY_PROBE`

---

# 十一、检查 FPGA 型号

项目固定目标：

```text
EBAZ4205
XC7Z010-1CLG400
Vivado part = xc7z010clg400-1
```

如果实际识别不是 XC7Z010：

必须标记：

```text
HARDWARE_IDENTITY_MISMATCH
```

不要自动修改项目 part。

---

# 十二、建立四条接口身份

本次检测必须尽可能建立：

```text
JTAG1
JTAG2
UART1
UART2
```

然后进一步尝试映射：

```text
Board A
 ├─ JTAG?
 └─ UART?

Board B
 ├─ JTAG?
 └─ UART?
```

但是：

单靠 Windows USB 枚举不一定可以证明哪个 UART 与哪个 JTAG 属于同一块 FPGA 板。

如果无法证明：

必须明确写：

```text
JTAG_AND_UART_BOARD_MAPPING_UNCONFIRMED
```

不能猜。

---

# 十三、推荐的板卡身份确认方式

如果本次只读检查无法完成：

```text
JTAG1 ↔ UART1
JTAG2 ↔ UART2
```

映射，则报告给出下一步操作方案。

优先方案：

### 方法 A：单板断开验证

人工一次只断开 Board A：

观察消失的：

```text
JTAG target
COM port
```

即可建立：

```text
Board A = JTAGx + UARTx
```

然后重新连接。

再对 Board B 验证。

本任务不能自动拔插 USB。

只需要把这个步骤写入报告。

---

# 十四、建立长期稳定的板卡身份

最终建议以后不要使用：

```text
COM3
COM4

hw_target 0
hw_target 1
```

作为永久身份。

推荐使用：

```text
Board_A:
    JTAG cable serial
    FPGA IDCODE / DNA
    UART USB serial

Board_B:
    JTAG cable serial
    FPGA IDCODE / DNA
    UART USB serial
```

然后再人工指定：

```text
Board_A = Master
Board_B = Slave
```

这样以后即使：

- 换 USB 口
- 重启电脑
- COM 编号改变
- Vivado target 顺序改变

也不会把 Master / Slave 搞反。

---

# 十五、检查 TASK-001 还缺什么硬件参数

结合：

- 当前 Windows USB 枚举
- 当前 Vivado Hardware Manager
- HANDOFF
- ARCHITECTURE
- PINOUT
- RTL
- XDC
- 当前 timing / DRC / CDC

建立：

# 上板前缺失参数表

至少包含：

| 参数 | 当前状态 | 是否软件可确认 | 是否必须补齐 | 获取方法 |
|---|---|---|---|---|
| JTAG1状态 | | | | |
| JTAG2状态 | | | | |
| UART1状态 | | | | |
| UART2状态 | | | | |
| JTAG1对应板卡 | | | | |
| JTAG2对应板卡 | | | | |
| UART1对应板卡 | | | | |
| UART2对应板卡 | | | | |
| FPGA实际型号 | | | | |
| FPGA唯一身份 | | | | |
| 板卡revision | | | | |
| X5/N18晶振是否装配 | | | | |
| N18频率 | | | | |
| N18幅值 | | | | |
| N18抖动 | | | | |
| Bank VCCO | | | | |
| P5连接器方向 | | | | |
| 两板共地 | | | | |
| SYNC_CLK通断 | | | | |
| DATA通断 | | | | |
| VALID通断 | | | | |
| RESET通断 | | | | |
| LOCK通断 | | | | |
| ECHO通断 | | | | |
| 跳线长度 | | | | |
| 时钟/数据偏斜 | | | | |
| VGA/外设冲突 | | | | |
| 示波器状态 | | | | |
| PS7启动配置 | | | | |
| JTAG启动模式 | | | | |

软件不能确认的内容统一写：

`REQUIRES_PHYSICAL_MEASUREMENT`

---

# 十六、检查当前连接方式是否合理

报告必须单独增加：

# USB连接拓扑分析

分析当前：

```text
JTAG1、JTAG2 → 电脑原生USB

UART1、UART2 → USB拓展坞
```

这种连接方式。

需要说明：

### JTAG

JTAG 直连电脑原生 USB 是优先推荐连接方式。

理由包括：

- 降低 USB hub 兼容问题
- 降低 JTAG cable 枚举异常
- 降低 hw_server cable 丢失
- 便于区分问题来源

因此当前 JTAG 拓扑总体合理。

### UART

UART 对带宽和时延要求很低，所以两路 UART 通过 USB Hub / Dock 通常可以正常使用。

但需要检查：

- 两个 USB-UART 是否能稳定同时枚举
- 是否有唯一 serial number
- 拓展坞供电是否稳定
- 大量其他 USB 设备同时工作时是否发生掉线
- Windows 是否重新分配 COM 端口

注意：

UART 仅承担：

```text
配置
状态读取
日志
调试
```

不承担：

```text
实时相控阵同步
实时 phase timing
```

所以 UART 经过拓展坞不会直接影响 FPGA 双板实时同步精度。

---

# 十七、结合 RTL/XDC 检查当前风险

必须分析：

## ZPS7-1

Master / Slave 当前：

```text
ZPS7-1
PS7 block required
```

说明：

- 对当前 JTAG 硬件枚举意味着什么
- 对直接 JTAG 配置 PL 意味着什么
- 对正式 bitstream / 启动配置意味着什么

不能简单忽略。

---

## Slave TIMING-6 / TIMING-7

检查：

```text
local50
received50
g_hw.mmcm_clk
```

之间的异步关系。

提出正确 CDC / timing model 建议。

禁止为了清 Warning 添加错误 false path。

---

## Master Hold

当前：

```text
WHS = +0.006 ns
```

明确属于非常小余量。

当前：

```text
IO delay
jitter
uncertainty
```

仍主要属于设计预算。

需要后续真实测量：

```text
SYNC_CLK
DATA
VALID
```

---

## Slave Setup

当前：

```text
WNS = +0.199 ns
```

也需要关注。

分析：

- 跳线长度
- connector
- skew
- DRIVE
- SLEW
- 外部负载

可能造成的影响。

---

## GPIO

当前：

```text
LVCMOS33
DRIVE 8
SLEW SLOW
```

分析是否适合短距离板间连接。

不要无依据改为 FAST。

---

# 十八、检查是否具备 bitstream 测试条件

最终只允许给出以下等级：

```text
NOT_READY_FOR_BITSTREAM

READY_FOR_CONTROLLED_BITSTREAM_TEST

READY_FOR_DUAL_BOARD_SYNC_TEST
```

判断必须综合：

```text
JTAG1
JTAG2
UART1
UART2
FPGA型号
Board mapping
共地
同步线
供电
PS7风险
STA
CDC
DRC
```

注意：

如果：

```text
JTAG正常
但P5连接尚未确认
```

最多只能：

```text
READY_FOR_CONTROLLED_BITSTREAM_TEST
```

不能直接写：

```text
READY_FOR_DUAL_BOARD_SYNC_TEST
```

---

# 十九、给出后续具体调试步骤

报告最后必须给出明确顺序。

建议：

## Step 1

确认：

```text
JTAG1
JTAG2
```

都被电脑原生 USB 正确枚举。

## Step 2

Vivado Hardware Manager 确认：

```text
Target A → XC7Z010
Target B → XC7Z010
```

## Step 3

确认：

```text
UART1
UART2
```

都通过拓展坞正常出现。

## Step 4

建立：

```text
Board A = JTAGx + UARTx
Board B = JTAGy + UARTy
```

映射。

## Step 5

指定：

```text
Board A = Master
Board B = Slave
```

并记录唯一设备 ID。

## Step 6

人工核对同步连接：

```text
Master → Slave

P5/7  N20  SYNC_CLK
P5/3  M18  DATA
P5/5  M20  VALID
P5/6  L17  RESET

Slave → Master

P5/9  M17  LOCK
P5/8  M19  ECHO

GND ↔ GND
```

示波器输出：

```text
P5/11 trigger
P5/13 waveform
```

禁止两个 scope output 相互连接。

## Step 7

示波器检查：

```text
N18 ≈ 50 MHz
```

并测量：

```text
频率
幅值
稳定性
```

## Step 8

处理 bitstream 前必要问题：

```text
ZPS7-1
TIMING-6
TIMING-7
TIMING-18
IO timing assumptions
```

## Step 9

后续单独任务生成：

```text
ebaz_master.bit
ebaz_slave.bit
```

本任务不要生成。

## Step 10

第一次烧录只验证：

```text
RUN
MMCM LOCK
SYNC_CLK
VALID
SYNC_LOCK
```

## Step 11

通过后测试：

```text
timestamp waveform
RESET_AT
TRIGGER_AT
ECHO / RTT
```

## Step 12

示波器同时观察：

```text
Master P5/13
Slave P5/13
```

测真实 skew。

最后完成：

```text
Level 0
Level 1
Level 2
Level 3
```

---

# 二十、工程优化建议

最终报告增加：

# 工程优化建议

分为：

## 必须现在做

只包括影响：

```text
JTAG
供电
电平
同步连接
第一次安全上板
```

的问题。

## 第一次 bitstream 测试时建议做

考虑在 FPGA 中加入 ILA / VIO 或 debug probe。

建议观察：

```text
MMCM locked
run
sync_locked
alive
timestamp[31:0]
received_sequence
crc/frame error
sequence error
timeout error
sync_valid
sync_data
reset_pending
trigger_pending
RTT valid
RTT cycles
```

注意资源使用要适合 XC7Z010。

## TASK-001 硬件验证后再做

设计：

```text
PREPARE
ACK_READY
COMMIT
APPLY_AT
```

用于后续两板相控阵参数原子切换。

不要提前实现声场功能。

---

# 二十一、最终报告

生成：

`v3/evidence/task001/DUAL_BOARD_HARDWARE_CHECK.md`

结构至少包含：

```markdown
# SonoField v3 双 EBAZ4205 硬件检测报告

## 1. 检测时间与环境

## 2. 当前实际USB连接拓扑

## 3. 检测结论

## 4. Windows USB设备检测

## 5. USB拓展坞与UART检测

## 6. 电脑原生USB与JTAG检测

## 7. Vivado hw_server状态

## 8. Hardware Target列表

## 9. FPGA Device列表

## 10. Board A / Board B身份映射

## 11. JTAG / UART交叉映射状态

## 12. 与SonoField预期硬件对比

## 13. 当前仍缺少的物理参数

## 14. RTL / XDC / STA / CDC / DRC风险

## 15. Bitstream测试准备度

## 16. 推荐上板调试顺序

## 17. 工程优化建议

## 18. 最终状态
```

最后必须填写：

```text
JTAG1_PC_DIRECT_DETECTED:
JTAG2_PC_DIRECT_DETECTED:

UART1_DOCK_DETECTED:
UART2_DOCK_DETECTED:

UART_DEVICE_COUNT:

HW_TARGET_COUNT:
FPGA_DEVICE_COUNT:

BOARD_A_DETECTED:
BOARD_B_DETECTED:

BOARD_A_JTAG:
BOARD_A_UART:

BOARD_B_JTAG:
BOARD_B_UART:

EXPECTED_DEVICE_MATCH:

JTAG_UART_MAPPING_CONFIRMED:

BITSTREAM_TEST_READINESS:
DUAL_SYNC_TEST_READINESS:

BOARD_TESTED: false
HARDWARE_VERIFIED: false
```

---

# 二十二、保存原始数据

建立：

`v3/evidence/task001/hardware_check/`

至少保存：

```text
windows-device-inventory.txt
usb-device-tree.txt
serial-ports.txt
uart-devices.txt
jtag-usb-devices.txt

vivado-hardware-console.log
hw-targets.txt
hw-devices.txt
hw-properties.txt

hardware-check-summary.json
```

如果可以获得 USB：

```text
VID
PID
Serial Number
Location Path
Parent Device
```

也必须保存。

---

# 二十三、核心原则

本次检测必须明确区分：

```text
USB识别
≠ JTAG通信成功

JTAG通信成功
≠ FPGA同步线路正确

UART枚举成功
≠ UART通信成功

FPGA被Vivado识别
≠ Bitstream可安全下载

Bitstream下载成功
≠ 双板同步成功

双板时间戳相同
≠ 亚周期物理相位已经验证
```

另外：

```text
UART经过拓展坞
```

与：

```text
JTAG直连电脑
```

是两个独立 USB 路径。

分析问题时禁止混为一谈。

执行检测后，生成最终：

`v3/evidence/task001/DUAL_BOARD_HARDWARE_CHECK.md`