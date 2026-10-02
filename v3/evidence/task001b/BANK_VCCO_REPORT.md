# Bank / VCCO audit — TASK-001B

State: BANK35_USER_CONFIRMED_MEASURED_3V3. BANK_VCCO_MEASURED=true;
BANK_VCCO_PASS=true for the unchanged 19 Bank35 array GPIO.
Source: user two-phase task 2026-10-02; fresh pin audit in task001c_ps7.
The earlier TASK-001B STATUS JSON is the historical build-time snapshot.
Current machine hardware facts are task001c_ps7/CONFIRMED_HARDWARE_FACTS.json.
Vivado confirms all 19 selected balls are Bank35 HR GPIO. It does not measure
VCCO. Core U31D Bank35 supply pins C19/H14/J17/K20/M16/N19 connect VCCB;
VCCB goes through R2460 (0 ohm) to VCC. U22/L7 output TP1 is labeled 3V3.
Bank34 uses VCCE via FB16 from the same nominal VCC rail. Core/expansion
revision and component population on the actual boards remain unconfirmed.

| Signal | Ball | Bank | Bank VCCO | IO standard | Connector | PCB voltage | AXC VCCA / VCCB |
|---|---|---|---|---|---|---|---|
| serial_data[0] | A20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/5 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[1] | H16 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/6 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[2] | B19 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/7 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[3] | B20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/8 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[4] | C20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/9 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[5] | H17 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/11 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[6] | D20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/13 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[7] | D18 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/14 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[8] | H18 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/15 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[9] | D19 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/16 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[10] | F20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/17 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[11] | E19 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/18 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[12] | F19 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/19 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[13] | K17 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P1/20 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[14] | G20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P2/5 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| serial_data[15] | J18 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P2/6 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| shift_clock | H20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P2/8 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| latch_clock | J20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P2/14 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |
| output_disable | L19 | 35 | 3.3V USER_CONFIRMED_MEASURED | LVCMOS33 | P2/16 | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |

SN74AXC8T245 rails must each be within 0.65..3.6V; it is not a 5V translator.
If A is the FPGA side, DIR1/DIR2 high requests A-to-B; OE is referenced to
VCCA and a pull-up requests high impedance at startup. The translated
output_disable signal and translator OE are distinct nets. Minimum signal
capacity is 3 translators per board (ceil(19/8)), six total; real grouping,
pulls, power sequencing, direction and 595 /OE mapping require PCB schematic.
An unknown PCB-side supply is not an observed incompatibility, but does not
pass a physical connection gate. BANK_VCCO_PASS is true for the unchanged Bank35 GPIO after user voltage
confirmation and a fresh exact-part pin audit. Other electrical gates remain. No FPGA download should precede the
required physical checks and the Zynq default configuration review.

TI source: https://www.ti.com/lit/ds/symlink/sn74axc8t245.pdf (SCES875C).
