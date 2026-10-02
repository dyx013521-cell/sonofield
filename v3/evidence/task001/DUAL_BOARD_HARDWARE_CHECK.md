# SonoField v3 双 EBAZ4205 硬件检测报告

## 1. 检测时间与环境

Windows USB/UART 检测：2026-10-02 14:50:52–14:53:08（Asia/Shanghai）；分类修正后的 JTAG 复查于 14:55:00 完成。PowerShell 7.6.5；Vivado 2025.2 / Build 6299465。检测源码基于仓库提交 `a79cffd7d0fdcefdc89758e3894a5ee62eb3c598`。

本任务仅做设备枚举、打开/关闭 JTAG target、读取设备属性及准备度分析。未生成或下载 bitstream，未写 Flash/寄存器，未执行设备刷新、板卡复位、UART 打开/收发或物理测量；未修改 RTL、XDC、器件、架构或 DRC 严重级别。

可复现入口：[check_dual_hardware.ps1](../../vivado/check_dual_hardware.ps1)、[check_dual_hardware.tcl](../../vivado/check_dual_hardware.tcl)。重复检测须指定新目录，以保留本次证据：

```powershell
# PowerShell 7，仓库根目录；替换日期时间为下一次扫描的标识
./v3/vivado/check_dual_hardware.ps1 -OutputDirectory ./v3/evidence/task001/hardware_check_next_scan
```

本次原始数据见 [hardware_check/](hardware_check/)，任务说明见 [DUAL_BOARD_HARDWARE_CHECK_REQUEST.md](../../docs/DUAL_BOARD_HARDWARE_CHECK_REQUEST.md)。Windows 与 Vivado 的采集时间不同，结果是这些采集时刻的快照，不代表连续稳定性测试。

## 2. 当前实际 USB 连接拓扑

用户提供的物理接线事实：两个 JTAG 下载器分别直连电脑原生 USB，两个 UART 通过 USB 扩展坞。以此作为接线输入，不将 UART 与 JTAG 混为同一路径。

```text
电脑原生 USB ─ JTAG1 ─ 板卡（A/B 未映射）
电脑原生 USB ─ JTAG2 ─ 板卡（A/B 未映射）
电脑 ─ USB 扩展坞 ─ UART1 / UART2（目前仅枚举到一路）
```

本报告的 JTAG1/JTAG2 按电缆 serial 分别定义为 `210299245711` / `210299835073`。检测后用户明确确认：245711→Board A、835073→Board B、COM7→Board A。此映射来源为用户确认，未执行人工断开对照；Master/Slave 角色仍未指定。

| 接口 | 用户说明的物理连接 | Windows 状态 | Vivado 状态 |
|---|---|---|---|
| JTAG1 / 210299245711 | 原生 USB 直连 | FTDI / Digilent，OK；直接父级为 ROOT_HUB30 | target 打开成功，XC7Z010 |
| JTAG2 / 210299835073 | 原生 USB 直连 | FTDI / Digilent，OK；逻辑父级含 05E3:0610 Hub | target 打开成功，XC7Z010 |
| Board A UART / COM7 | 用户确认 Board A；UART 经扩展坞 | CH340，OK；父级为 1A86:8095 Hub | N/A |
| 第二路 UART | 用户说明经扩展坞 | 未发现第二个 present USB UART | N/A |

系统不能可靠区分机内集线器与外部扩展坞，故保留 `USB_PHYSICAL_PORT_MAPPING_REQUIRES_MANUAL_CONFIRMATION`。JTAG2 下存在逻辑 Hub 节点，不足以否定用户的原生端口接线说明。

## 3. 检测结论

- 两个 USB JTAG 下载器均 present、状态 OK；两个独立 Vivado target 均成功打开。
- 每条链路识别一个 `xc7z010` FPGA 和一个 `arm_dap`，总计 **2 个 FPGA / 2 个 ARM DAP / 4 个 hardware device**。
- 两个 FPGA 均返回 IDCODE `13722093`，与 XC7Z010 型号预期一致；封装、速度等级、温度等级仍需芯片丝印与板卡资料核对。
- present USB UART 只有 **1 路：USB-SERIAL CH340 (COM7)**。四个蓝牙 COM 端口不属于两块板的 USB UART。
- 枚举本身不能确定物理板号；用户随后确认两路 JTAG 对应 Board A/B，COM7 对应 Board A。Board B UART 尚缺，Master/Slave 角色未指定。
- 当前为 **NOT_READY_FOR_BITSTREAM**。工程证据仍是 SIMULATED / SYNTHESIZED / IMPLEMENTED；BOARD_TESTED 与 HARDWARE_VERIFIED 仍为 false。

机器可读结果：[hardware-check-summary.json](hardware_check/hardware-check-summary.json)。

## 4. Windows USB 设备检测

执行了 `Get-PnpDevice -PresentOnly`、`Win32_USBControllerDevice`、`Win32_SerialPort`、匹配设备的 `Win32_PnPEntity`、`Win32_PnPSignedDriver` 和 `Get-PnpDeviceProperty` 父级追踪。采集到 303 个 present PnP 设备，15 个 USB/FTDIBUS 节点，5 个 Ports 类设备；查询错误列表为空。

两路 JTAG VID/PID 均为 `0403:6014`，USB 报告名称为 Digilent USB Device，电缆 serial 不同。FTDI 签名驱动版本均为 `2.12.36.20 / oem107.inf`。CH340 为 `1A86:7523`，签名驱动 `3.9.2024.9 / oem64.inf`。本任务没有安装、替换或重新绑定驱动。

原始资料：[windows-device-inventory.txt](hardware_check/windows-device-inventory.txt)、[windows-device-inventory.json](hardware_check/windows-device-inventory.json)、[matching-pnp-entities.txt](hardware_check/matching-pnp-entities.txt)、[usb-controller-associations.txt](hardware_check/usb-controller-associations.txt)、[usb-drivers.txt](hardware_check/usb-drivers.txt)。

## 5. USB 扩展坞与 UART 检测

| 项目 | 结果 |
|---|---|
| UART_DEVICE_COUNT | 1（仅 present USB UART） |
| 可见 COM | COM7 |
| FriendlyName | USB-SERIAL CH340 (COM7) |
| VID/PID | 1A86 / 7523 |
| PNPDeviceID | `USB\VID_1A86&PID_7523\8&148914A8&0&1` |
| Parent | `USB\VID_1A86&PID_8095\7&2e3fcb7b&0&1` |
| Location Path | `PCIROOT(0)#PCI(0801)#PCI(0004)#USBROOT(0)#USB(2)#USB(1)#USB(1)` |
| USB 唯一 serial | 未读取到可作为永久身份的唯一 serial；末段是位置生成的实例标识 |
| UART_MAPPING_CONFIDENCE | BOARD_A_USER_CONFIRMED；Board B 未发现 |

CH340 逻辑路径位于 1A86:8095 Hub 下，该 Hub 又在 05E3:0610 Hub 下；第二 UART 缺失，无法证明两路均在同一扩展坞层级。记录 `UART_PERSISTENT_MAPPING_NOT_AVAILABLE`，下一步结合 Location Path、物理标签和人工单板断开验证。

`Win32_SerialPort` 此次仅列出蓝牙 COM3–COM6，没有列出 PnP 已识别的 COM7。这是不同枚举接口的覆盖差异，因此不单独依赖 CIM 列表计数；COM7 由 present PnP Ports 与设备属性交叉确认。本次未打开串口，COM7 仅为 `UART_ENUMERATION_OK`，不证明数据通信正常。

第二 UART 应先检查扩展坞对应端口、USB-UART 转换器、数据线、供电、串口驱动和设备枚举；不要用蓝牙 COM 填补数量。原始资料：[serial-ports.txt](hardware_check/serial-ports.txt)、[uart-devices.txt](hardware_check/uart-devices.txt)、[usb-properties.json](hardware_check/usb-properties.json)。

## 6. 电脑原生 USB 与 JTAG 检测

| 检测别名 | Cable serial | Parent | Location Path |
|---|---|---|---|
| JTAG1 | 210299245711 | `USB\ROOT_HUB30\5&21d782f4&0&0` | `PCIROOT(0)#PCI(0801)#PCI(0004)#USBROOT(0)#USB(1)` |
| JTAG2 | 210299835073 | `USB\VID_05E3&PID_0610\6&1cb538dd&0&2` | `PCIROOT(0)#PCI(0801)#PCI(0004)#USBROOT(0)#USB(2)#USB(2)` |

用户接线说明为两个 JTAG 均插在电脑原生端口。本次逻辑枚举显示 JTAG1 直接挂在 root hub，JTAG2 经一个逻辑 hub；不能仅据这些节点判断具体物理端口位置。复查物理标签即可补齐此证据，不应先归因于 UART 所用扩展坞。

两路此次 JTAG 通信均正常，暂未发现需要修改驱动或电缆配置的证据。若后续 target 消失，按原生 USB → 数据线/下载器 → 驱动 → hw_server → JTAG 排针/板供电排查。原始资料：[jtag-usb-devices.txt](hardware_check/jtag-usb-devices.txt)、[usb-device-tree.txt](hardware_check/usb-device-tree.txt)。

## 7. Vivado hw_server 状态

采集开始前存在两个 Vivado GUI 进程，未检测到 hw_server 进程。本次批处理连接 `localhost:3121`，由 Vivado 自动启动 2025.2 hw_server 与 cs_server；连接、两个 target 的打开/关闭均成功，最终探测退出码 0、probe_error_count 0。初次扫描结束后的进程清单没有残留 hw_server；本任务没有终止原有 GUI、修改服务配置或安装驱动。

最终探测日志：[vivado-hardware-console.log](hardware_check/vivado-hardware-console.log)、[vivado-hardware.log](hardware_check/vivado-hardware.log)、[vivado-probe-status.tsv](hardware_check/vivado-probe-status.tsv)。进程快照：[hw-server-before.txt](hardware_check/hw-server-before.txt)、[hw-server-after.txt](hardware_check/hw-server-after.txt)。空的 after 文件表示该查询未返回进程，不能推断服务运行稳定性。

## 8. Hardware Target 列表

| Cable / TID | Hardware Target | 结果 |
|---|---|---|
| jsn-JTAG-HS3-210299245711 | `localhost:3121/xilinx_tcf/Digilent/210299245711` | 已打开；2 个链上 device |
| jsn-JTAG-HS3-210299835073 | `localhost:3121/xilinx_tcf/Digilent/210299835073` | 已打开；2 个链上 device |

读取的 `PARAM.FREQUENCY` 为 15 MHz；本次未修改 JTAG 频率。target 打开前属性 `DEVICE_COUNT=0` 是当时的未打开状态，实际链数以打开后的枚举为准。原始资料：[hw-targets.txt](hardware_check/hw-targets.txt)、[hw-properties.txt](hardware_check/hw-properties.txt)。

## 9. FPGA Device 列表

| 电缆 | FPGA 名称 | INDEX / 链位置 | PART | IDCODE_HEX | ARM DAP |
|---|---|---:|---|---|---|
| 210299245711 | xc7z010_1 | 1 | xc7z010 | 13722093 | index 0，4BA00477 |
| 210299835073 | xc7z010_1_1 | 1 | xc7z010 | 13722093 | index 0，4BA00477 |

器件类别为 Zynq-7000 / XC7Z010。两个 FPGA 的 `UNKNOWN_DEVICE=0`、`PROGRAM.IS_SUPPORTED=1`，`PROGRAM.FILE` 与 `PROBES.FILE` 为空。属性中的 DONE、EOS 均为 1、CRC_ERROR 为 0，但当前配置的来源、版本和功能未知；**不是本项目 bitstream 已下载的证据**。`REGISTER.CONFIG_STATUS` 等是本次 Hardware Manager 可见属性，未写寄存器，也未据此认定现有配置为同步工程。

本次无可见 FPGA DNA 属性，记录 `NOT_AVAILABLE_WITH_READ_ONLY_PROBE`；未运行可能需要编程或改变状态的 DNA 读取流程。两颗相同的 IDCODE 是型号标识，不是唯一芯片身份。DID 中的电缆 serial 可用于本次连接身份，不能替代 FPGA DNA。原始资料：[hw-devices.txt](hardware_check/hw-devices.txt)。

首次探测曾把 4 个链上 hardware device 都输出为 FPGA_DEVICE_COUNT；其中包含两个 ARM DAP。已修正分类并完成只读复查，最终 FPGA_DEVICE_COUNT=2；首次原始输出保留在 [probe01/](hardware_check/probe01/)，不作为最终数量。

## 10. Board A / Board B 身份映射

已确认两条不同电缆链路各连接一个 XC7Z010；检测后用户提供了以下对应关系。映射证据属于用户确认，设备排序不参与分配，Master/Slave 尚未指定。

| 物理板 | JTAG cable serial | UART | Master/Slave |
|---|---|---|---|
| Board A | 210299245711（USER_CONFIRMED） | COM7（USER_CONFIRMED） | UNASSIGNED |
| Board B | 210299835073（USER_CONFIRMED） | NOT_DETECTED | UNASSIGNED |

下一步将已确认的映射贴到板卡与电缆上。补齐 Board B UART 后，建议一次只断开一块板的相关接口，观察哪个 target 与 COM 消失，记录后重连，对两块板分别交叉验证。本任务未实施自动拔插。若断开 UART 会经转换器反向供电，须先由人工确认供电和接地方式再操作。

## 11. JTAG / UART 交叉映射状态

Board A 的 `210299245711 ↔ COM7 ↔ Board A` 已由用户确认；Board B 的 JTAG 为 `210299835073`，UART 尚未发现。两板完整交叉映射仍为 `JTAG_AND_UART_BOARD_MAPPING_UNCONFIRMED`，这是 Board B 接口缺失与尚未完成交叉观测的状态，不抹除用户已提供的对应关系。

建议持久身份记录为 Board_A/Board_B → JTAG cable serial + 实物板号/芯片丝印 + UART VID/PID/唯一 serial（若可获取）或 Location Path/物理标签。人工完成映射后再指定角色。COM 编号、target 排序和相同的 FPGA IDCODE 都不应作为永久板身份。

## 12. 与 SonoField 预期硬件对比

| 预期 | 当前证据 | 结论 |
|---|---|---|
| 两块 EBAZ4205 / XC7Z010 | 两条独立链路各识别 XC7Z010 | 型号匹配；板卡 revision 与完整料号待核对 |
| XC7Z010-1CLG400 / xc7z010clg400-1 | 软件目标与已归档综合/实现一致 | JTAG 不证明速度等级或封装，不修改 part |
| N18/X5 50 MHz | 已归档原理图及硬件说明；XDC 为 20.000 ns | 设计事实明确；当前板是否装配及实际幅值/频率仍待测 |
| 两个 USB UART | COM7 一路 | 未达到双 UART 枚举目标 |
| 双板同步电气接口 | PINOUT/XDC 完整 | 本次没有通断、VCCO 或示波器证据 |

用户再次提供的 [EBAZ4205_硬件说明.md](../../docs/EBAZ4205_硬件说明.md) 与仓库归档文件 SHA256 相同：`0eeaf76df7684f79159b20221789a22e06f2ab6a3d707951b8874ae1a606c52d`。它是参考材料，里面的操作建议不构成新授权。项目仍使用 Vivado 2025.2；其中 P4=10×2 的描述已由原图修正为 9×2，摄像头的 CLOCK_DEDICATED_ROUTE 覆盖建议不适用于本同步工程。原材料的“已焊/实测”等描述不替代本次两块板的测量证据；三张引用配图仍缺附件。

## 13. 当前仍缺少的物理参数

| 参数 | 当前状态 | 软件可确认 | 必须补齐 | 获取方法 |
|---|---|---|---|---|
| JTAG1 / JTAG2 | 两路 USB OK，两个 target 均成功 | 是，当前通信快照 | 连续调试时复查 | 本报告脚本 |
| UART1 / UART2 | COM7 一路，另一未发现 | 部分，仅枚举 | 本次清单要求补齐两路 | 检查扩展坞/线/转换器/驱动后重扫 |
| JTAG1 / JTAG2 对应板卡 | 用户确认 A=245711、B=835073 | 否，来源为用户确认 | 已提供映射；建议交叉观测 | 人工标签、逐板断开对照 |
| UART1 / UART2 对应板卡 | 用户确认 COM7=A；B 未发现 | 否，来源为用户确认 | 补齐 B | 两路齐全后逐板对照 |
| FPGA 实际型号 | 两个 XC7Z010 | 是，型号级 | 完整料号需核对 | 芯片丝印/板卡资料 |
| FPGA 唯一身份 | IDCODE 不唯一，DNA 未获取 | 本次不可用 | 用板号/电缆建立身份；DNA 后续可选 | 人工板号，后续允许流程 |
| 板卡 revision | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 是 | 实物丝印与原图版本 |
| X5/N18 晶振是否装配 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 是 | 实物检查 |
| N18 频率 | 设计 50 MHz；REQUIRES_PHYSICAL_MEASUREMENT | 否 | 是 | 示波器/计数器 |
| N18 幅值 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 是 | 示波器 |
| N18 抖动 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 时序/同步签核前 | 合适带宽与采样的仪器 |
| Bank VCCO | 原图方案 3.3 V；REQUIRES_PHYSICAL_MEASUREMENT | 否 | 是 | 万用表/实物原图 |
| P5 连接器方向 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 是 | 针 1 标记、原图与通断 |
| 两板共地 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 是 | 接线及低阻检查 |
| SYNC_CLK 通断 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 双板同步前 | N20/P5/7 通断与波形 |
| DATA 通断 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 双板同步前 | M18/P5/3 通断 |
| VALID 通断 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 双板同步前 | M20/P5/5 通断 |
| RESET 通断 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 双板同步前 | L17/P5/6 通断 |
| LOCK 通断 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 双板同步前 | M17/P5/9 通断 |
| ECHO 通断 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | RTT 验证前 | M19/P5/8 通断 |
| 跳线长度、连接器/线缆延迟 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 是 | 尺寸记录及时间测量 |
| 时钟/数据偏斜 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | 时序/同步签核前 | 测 SYNC_CLK、DATA、VALID |
| VGA/外设冲突 | 引脚复用已知；REQUIRES_PHYSICAL_MEASUREMENT | 部分 | 是 | 移除并核对复用外设 |
| 示波器状态 | REQUIRES_PHYSICAL_MEASUREMENT | 否 | Level 1/2 前 | 仪器、探头与接地确认 |
| PS7 启动配置 | ZPS7-1 尚未关闭 | 设计警告可确认，启动不可 | bitstream 测试前 | 设计/启动方案审查 |
| JTAG 启动模式 | 属性可读，当前配置来源未知；REQUIRES_PHYSICAL_MEASUREMENT | 部分 | 是 | 启动跳线/原图/电源流程 |

UART 不是 FPGA 实时同步通道；第二路 UART 缺失本身不能证明同步电气故障。但本次所要求的四接口身份清单还未完成，也不能据此把准备度升级。

## 14. RTL / XDC / STA / CDC / DRC 风险

以下分析基于已归档的 2026-09-30 报告及当前源码，本次未重新综合/实现。

**ZPS7-1：** 两板 DRC 均提示 PS7 block required，缺少正确默认 PS 配置。该设计警告不阻止本次 JTAG IDCODE 枚举，已成功发现两颗 FPGA；这是检测与生成/启动设计的不同层面。直接 JTAG 配置 PL 的准备度仍需要审查 PS 配置、板上启动方式与供电状态，不能从识别成功推断配置安全。正式 bitstream/启动方案应明确 PS7 的实现或正确配置流程，并复查 DRC；本任务未添加 PS7、改变严重级别或生成 bitstream。

**Slave TIMING-6/7：** local50 来自 N18 独立晶振，received50 来自 Master 转发时钟，g_hw.mmcm_clk 由 received50 派生。因此 local50 与后两者物理异步，received50 与其 MMCM 输出则有派生关系。已有 heartbeat/Alive 的 ASYNC_REG 同步器和复位链，CDC critical=0 仅是报告分类；异步输出门控仍需人工审查。后续应逐条核对跨域结构、同步器放置、复位释放、故障门控和约束覆盖。若改用不含时钟偏斜的 datapath 预算，须仅针对已确认的同步器入口并验证路由延迟；不能把相同 50 MHz 当作同相，也不能批量切断路径掩盖问题。本任务没有加入时钟分组或 false path。AMD [UG903 异步 CDC 说明](https://docs.amd.com/r/2025.2-English/ug903-vivado-using-constraints/Asynchronous-Clock-Domain-Crossings) 强调异步时钟没有确定相位关系，常规 slack 不能证明功能正确，需要正确 CDC 结构及对应约束。

**Master hold：** WHS +0.006 ns 是 6 ps 的极小余量。原始 [hold_paths.rpt](ebaz_master/hold_paths.rpt) 最小路径为内部 payload_reg[32]→payload_reg[33]，不能把它直接解释为线缆 hold 余量。需要后续实施/不确定度预算复核；对 SYNC_CLK/DATA/VALID 的板外时序还须单独测量，保留 jitter/uncertainty 与真实 IO 偏斜的证据。

**Slave setup：** WNS +0.199 ns 最差路径是 sync_data 输入至 CRC good_crc 寄存器，使用 4 ns 输入预算、10 ns 半周期建立窗口，组合路径含 5 级逻辑。线缆/连接器延迟、时钟与数据不对称、负载和边沿变化可能消耗有限余量。不能只靠延长跳线或更换 DRIVE/SLEW 后仍沿用原预算。

**GPIO：** 当前 LVCMOS33 / DRIVE 8 / SLEW SLOW 可作为短线、正确 3.3 V 电平和回流条件下的候选设置；是否满足实际接收阈值与时间窗需示波器确认。50 MHz 周期不直接决定边沿传播与反射问题；应关注线长、回流、负载、过冲和必要的源端终端评估，不无依据改为 FAST。

**其他审查：** 保留 TIMING-18、TIMING-28 及 Slave IOSR-1 警告。前者涉及外部边沿/多时钟覆盖，TIMING-28 涉及自动派生时钟约束引用，IOSR-1 提示 IOB 复位共享/打包限制。无证据将这些条目描述为全部通过。详见 [timing_report.md](timing_report.md)、[Master DRC](ebaz_master/drc.rpt)、[Slave DRC](ebaz_slave/drc.rpt)。

## 15. Bitstream 测试准备度

`BITSTREAM_TEST_READINESS=NOT_READY_FOR_BITSTREAM`；`DUAL_SYNC_TEST_READINESS=NOT_READY_FOR_BITSTREAM`。

JTAG 与 XC7Z010 型号枚举通过，两板 JTAG 与 Board A UART 的映射已有用户确认；但角色指定、Board B UART、完整料号、供电/VCCO、共地、P5 连接、启动方案与 ZPS7/时序审查尚未补齐，因此此次不授予 READY_FOR_CONTROLLED_BITSTREAM_TEST，也不授予 READY_FOR_DUAL_BOARD_SYNC_TEST。后续单独完成这些条件后再评估；一旦仅满足单板受控条件而双板 P5 尚未确认，最多为前一等级。

## 16. 推荐上板调试顺序

1. 给两块板和 JTAG cable 贴标签，确认原生 USB 物理路径；本次两路 JTAG 已成功，无需为了枚举修改 RTL。
2. 复查两个 target 分别识别 XC7Z010，并用实物丝印确认完整料号与 revision。
3. 找回第二路 USB UART，确认两路在扩展坞的端口及稳定枚举；不要把蓝牙 COM 当作板串口。
4. 按用户确认贴上 A=245711/COM7、B=835073 的标签，补齐 B UART 后逐板对照 target 与 COM；随后由用户指定 Master/Slave，建议 A=Master、B=Slave。
5. 核对电源、VCCO、公共地和启动跳线；只读软件枚举不能替代这些确认。
6. 按 [PINOUT.md](../../docs/PINOUT.md) 检查 CLK P5/7 N20、DATA P5/3 M18、VALID P5/5 M20、RESET P5/6 L17、LOCK P5/9 M17、ECHO P5/8 M19、GND P5/1。P5/2 是 3.3 V，不作为地；两板 P5/11 trigger 和 P5/13 waveform 输出禁止互接。
7. 移除占用复用网络的 VGA/外设，测 N18 约 50 MHz 的频率、幅值与稳定性，记录线长和探头信息。
8. 完成 ZPS7-1、TIMING-6/7/18、IO 预算、hold/setup 余量与异步安全门控审查。
9. 后续独立任务才生成对应 ebaz_master.bit / ebaz_slave.bit，并重新评估受控测试准备度。
10. 首次受控下载先观察 RUN、MMCM LOCK、SYNC_CLK、VALID、SYNC_LOCK，保存配置来源和版本；本任务未执行此步。
11. 再测 timestamp waveform、RESET_AT、TRIGGER_AT、ECHO/RTT 及断链恢复。
12. 示波器同时测两板 P5/13 波形及 P5/11 触发，记录物理 skew；最后依次完成 Level 0–3，包括 >1 小时连续运行和原始数据归档。

## 17. 工程优化建议

**必须现在做：** 将用户确认的板卡映射落实到标签、补齐 Board B UART 并指定角色、完成供电/电平/共地/P5 检查及启动与 PS7/时序审查。保留稳定电缆 serial、统一接线记录和有时间戳的扫描证据。用户当前 JTAG 直连、UART 经扩展坞的分工适合作为调试接线方案；UART 经 Hub 不直接参与 FPGA 实时相位时间基准，但需检查掉线、供电与 COM 重分配。

**首次 bitstream 测试时考虑：** 根据 XC7Z010 的实际资源余量配置有限 ILA 探针，观察 locked/run/sync_locked/alive、timestamp[31:0]、received_sequence、CRC/帧/序列/timeout 错误、VALID/DATA、reset_pending/trigger_pending 和 RTT valid/cycles。先考虑只观察的 ILA；VIO 会驱动信号，需要在后续获准改变硬件状态的任务中另行设计。增加 debug core 后须重新综合、实现、验证时序，不直接复用旧 slack。参考 AMD [UG908 2025.2 逻辑分析器说明](https://docs.amd.com/r/2025.2-English/ug908-vivado-programming-debugging/Using-Vivado-Logic-Analyzer-to-Debug-the-Design)。

**TASK-001 硬件验证后再做：** 审查 PREPARE / ACK_READY / COMMIT / APPLY_AT 两板原子切换协议，再推进相控阵参数调度；本阶段不提前实现声场或轨迹功能。

## 18. 最终状态

```text
JTAG1_PC_DIRECT_DETECTED: USB/JTAG_DETECTED; PC_DIRECT_USER_REPORTED; ROOT_HUB_PARENT_OBSERVED
JTAG2_PC_DIRECT_DETECTED: USB/JTAG_DETECTED; PC_DIRECT_USER_REPORTED; PHYSICAL_PORT_UNCONFIRMED
UART1_DOCK_DETECTED: COM7_ENUMERATED; BOARD_A_USER_CONFIRMED; DOCK_USER_REPORTED
UART2_DOCK_DETECTED: NOT_DETECTED
UART_DEVICE_COUNT: 1
UART1_COM: COM7 (BOARD_A_USER_CONFIRMED)
UART2_COM: NOT_DETECTED
UART_MAPPING_CONFIDENCE: BOARD_A_USER_CONFIRMED; BOARD_B_MISSING
HW_TARGET_COUNT: 2
HARDWARE_DEVICE_COUNT: 4
FPGA_DEVICE_COUNT: 2
ARM_DAP_DEVICE_COUNT: 2
BOARD_A_DETECTED: true (JTAG present, physical label USER_CONFIRMED)
BOARD_B_DETECTED: true (JTAG present, physical label USER_CONFIRMED)
BOARD_A_JTAG: 210299245711 (USER_CONFIRMED)
BOARD_A_UART: COM7 (USER_CONFIRMED)
BOARD_B_JTAG: 210299835073 (USER_CONFIRMED)
BOARD_B_UART: NOT_DETECTED
EXPECTED_DEVICE_MATCH: true (XC7Z010 family/part only; package/speed grade unconfirmed)
JTAG_UART_MAPPING_CONFIRMED: false
FPGA_DNA: NOT_AVAILABLE_WITH_READ_ONLY_PROBE
USB_PHYSICAL_PORT_MAPPING_REQUIRES_MANUAL_CONFIRMATION
UART_PERSISTENT_MAPPING_NOT_AVAILABLE
JTAG_AND_UART_BOARD_MAPPING_UNCONFIRMED
BITSTREAM_TEST_READINESS: NOT_READY_FOR_BITSTREAM
DUAL_SYNC_TEST_READINESS: NOT_READY_FOR_BITSTREAM
BOARD_TESTED: false
HARDWARE_VERIFIED: false
```

USB 识别、JTAG 通信、UART 枚举、同步线路正确、受控配置、双板同步与亚周期相位测量是不同证据层级；本次只补齐当前枚举/识别证据，未改变软件基线的硬件验收状态。
