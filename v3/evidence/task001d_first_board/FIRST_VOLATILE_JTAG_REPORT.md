# First volatile JTAG bringup / NOT_STARTED

Phase-A is MINIMAL_PS7_NOT_READY / BLOCKED_PS_CLOCK_FACT. Its strict release
gate is false, so Phase-B was not entered. No .bit or new .ltx, configuration
hash, program result, MMCM capture, P5 synchronization capture or serializer
ILA frame exists for this phase. No board reset or PS initialization was run.
Existing configured-device DONE/EOS/CRC properties appear only in the Phase-A
read-only boot report and are not new SonoField program results.

Bank35 measured 3.3 V, common ground, removed VGA/Camera and N18 50 MHz are
USER_CONFIRMED. Current 19 GPIO per board remain device-database verified
Bank35. Board2 UART remains optional and does not block this task.
Arm=0/output_disable=1 remains the RTL default, with no newly programmed pin
measurement. P1/P2 shift/latch/data/disable measurements, 2.5 MHz burst pulse
width/levels/edges/setup/hold, common logical APPLY and physical latch skew,
P5 GND seating and manual loss/recovery tests remain unperformed.

PCB_CONNECTED=null because software cannot establish actual connection;
PCB_CONNECTION_REQUIRES_USER_CONFIRMATION. The intended test leaves the PCB
disconnected. READY_FOR_PCB_CONNECTION=false; no AXC/595/physical channel,
PCB, acoustic or levitation verification is claimed.

Resume only after the [Phase-A gate](../task001c_ps7/PS7_RELEASE_STATUS.json)
becomes READY_FOR_FIRST_VOLATILE_JTAG_BITSTREAM. The user already authorized
volatile PL JTAG with identity and release gates; no new approval is needed
for that same scope. Permanent boot media and PS software remain excluded.
