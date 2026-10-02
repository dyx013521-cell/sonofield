"""Rebuild GPIO tables from schematic transcription and current Vivado database.
Run after audit_array_gpio.tcl; no hardware access, no voltage measurement claim.
"""
import csv,json,pathlib,re
root=pathlib.Path(__file__).resolve().parents[1]
mapping=json.loads((root/'docs/array_gpio_mapping.json').read_text(encoding='utf-8'))
db={r['ball']:r for r in csv.DictReader((root/'evidence/task001b/gpio_audit/package-pins.tsv').open(),delimiter='\t')}
selected=mapping['selected'];by_ball={r[3]:r[0] for r in selected}
confirmed=mapping.get('confirmed_hardware',{})
bank35_measured=confirmed.get('bank35_vcco_measured_volts')==3.3
def current_facts(text):
 if not bank35_measured:return text
 text=text.replace('All are Bank35, schematic nominal 3.3V, not measured.','All are Bank35; 3.3V measured voltage is USER_CONFIRMED on 2026-10-02.')
 text=text.replace('module absence and voltage confirmation are pending.','actual optional component population remains unconfirmed; VGA/Camera are USER_CONFIRMED removed.')
 text=text.replace('Camera/VGA/header nets have parallel connectors; absence of attached modules\nrequires physical confirmation.','Camera/VGA/header nets have parallel connectors; VGA/Camera modules are\nUSER_CONFIRMED removed on 2026-10-02. Hardwired branches remain.')
 text=text.replace('State: SCHEMATIC_NOMINAL_COMPATIBLE; physical rails NOT_MEASURED.','State: BANK35_USER_CONFIRMED_MEASURED_3V3. BANK_VCCO_MEASURED=true;\nBANK_VCCO_PASS=true for the unchanged 19 Bank35 array GPIO.\nSource: user two-phase task 2026-10-02; fresh pin audit in task001c_ps7.\nThe earlier TASK-001B STATUS JSON is the historical build-time snapshot.\nCurrent machine hardware facts are task001c_ps7/CONFIRMED_HARDWARE_FACTS.json.')
 text=text.replace('3.3V nominal, unmeasured','3.3V USER_CONFIRMED_MEASURED')
 text=text.replace('Their LEDs/resistors remain electrically connected. Physical board revision,\nactual optional component population remains unconfirmed; VGA/Camera are USER_CONFIRMED removed.','Their LEDs/resistors remain electrically connected. Board revision and actual\ncomponent population remain unconfirmed; VGA/Camera are USER_CONFIRMED removed.')
 text=text.replace('BANK_VCCO_PASS is false until the actual\nboard/header conditions are confirmed.','BANK_VCCO_PASS is true for the unchanged Bank35 GPIO after user voltage\nconfirmation and a fresh exact-part pin audit. Other electrical gates remain.')
 return text
p5={b for b in mapping['connector_pins']['P5'] if b in db}
reserved=set(mapping['reserved_base'])|p5
assert len(selected)==19 and len(by_ball)==19
assert len({(r[1],r[2]) for r in selected})==19
for signal,connector,pin,ball in selected:
 assert connector!='P5' and ball not in reserved
 assert mapping['connector_pins'][connector][pin-1]==ball
 assert db[ball]['bank']=='35' and db[ball]['pin_func'].startswith('IO_')
 for role in ('master','slave'):
  xdc=(root/f'constraints/ebaz_{role}_array.xdc').read_text()
  assert f'PACKAGE_PIN {ball} [get_ports {{{signal}}}]' in xdc or f'PACKAGE_PIN {ball} [get_ports {signal}]' in xdc
leds={'H20':'LED0/R9 2k','J20':'LED2/R11 2k','L19':'LED3/R12 2k','K18':'LED1/R10 2k retained sync indicator'}
keys={'G19':'S1 reset','J19':'S2 scheduled epoch reset','K19':'S3 manual scheduled test','L16':'S4/220R to ground when pressed'}
camera=set(mapping['connector_pins']['P1'])|{'G20','J18'}
rows=[]
for connector,pins in mapping['connector_pins'].items():
 for pin,ball in enumerate(pins,1):
  bank=db[ball]['bank'] if ball in db else '-'
  vcco=('3.3V USER_CONFIRMED_MEASURED' if bank=='35' and bank35_measured else '3.3V schematic nominal / NOT_MEASURED') if bank in ('34','35') else '-'
  use=leds.get(ball,keys.get(ball,'Camera header parallel net' if ball in camera and ball in db else 'VGA/header parallel net' if ball in p5 else ball))
  available='RESERVED_SYNC' if connector=='P5' or ball in p5 else 'HARD_CONFLICT' if ball in reserved else 'REUSABLE_PERIPHERAL_PIN' if ball in db else 'NO_GPIO'
  rows.append(f'| {connector} | {pin} | {ball} | {bank} | {vcco} | {use} | {available} | {by_ball.get(ball,"-") if connector!="P5" else "RESERVED_SYNC"} |')
header='''# Array GPIO pool — TASK-001B

Sources: core and expansion PDFs page 1, visually reviewed; exact Vivado
2025.2 xc7z010clg400-1 database in `gpio_audit/package-pins.tsv`.
All P5-connected balls are excluded, including their aliases on P2/P3.
P1 contains 14 GPIO, not 16 or 19. P2 adds G20/J18 and three explicitly
repurposed LED outputs H20/J20/L19. P3 adds no unique GPIO outside P5.
There are 19 selected outputs, all Bank35. P1/P2 pin1/2 are VCC_IN,
not logic pins or a guaranteed 3.3V supply. Pin10 is NC and pin12 is ground.
The core adds 22 ohm series resistors between FPGA balls and DATA headers.
Camera/VGA/header nets have parallel connectors; absence of attached modules
requires physical confirmation. LEDs retain their 2 kohm series loads; worst
case current with a zero-volt LED-drop bound is 3.3/2000=1.65mA. DRIVE=4mA,
SLEW=SLOW is a conservative initial setting, not waveform qualification.
No button, JTAG, MIO or DDR ball is repurposed. LED1/K18 remains a sync LED.
Connector duplicate aliases are listed intentionally; selected duplicates are
checked separately and are zero. This table is not permission to wire a PCB.

| Connector | Pin | FPGA Ball/net | Bank | VCCO | Current use | Available | Selected role |
|---|---:|---|---|---|---|---|---|
'''
(root/'docs/ARRAY_GPIO_POOL.md').write_text(current_facts(header)+'\n'.join(rows)+'\n',encoding='utf-8')
pinmap='''# Serializer pin map — both Board1/Master and Board2/Slave

19 outputs: 14 data on P1, 2 data plus 3 control outputs on P2; P3 unused,
P5_ARRAY_GPIO_COUNT=0. All are Bank35, schematic nominal 3.3V, not measured.
H20/J20/L19 replace three original LED outputs in the PRE-PCB wrappers only.
Their LEDs/resistors remain electrically connected. Physical board revision,
module absence and voltage confirmation are pending. Keep PCB disconnected.

| Logical signal | Connector | Physical pin | FPGA ball | Bank | IOSTANDARD |
|---|---|---:|---|---:|---|
'''
for signal,c,p,b in selected:pinmap+=f'| {signal} | {c} | {p} | {b} | 35 | LVCMOS33 / DRIVE4 / SLOW |\n'
pinmap+='''
Each lane N sends CH[4N+3], CH[4N+2], CH[4N+1], CH[4N] on four rising
SRCLK edges. An actual 8-bit shift register then has CH[4N+i] in Qi (i=0..3),
with the preceding four values still in Q4..Q7. These upper outputs must be
unused. This is a behavioral-model mapping; actual PCB Q pin/channel wiring
and /OE polarity remain unconfirmed. No 595 SRCLR wire is assigned; the first
four-bit frame replaces Q0..Q3 even from an unknown prior shift register.
Pin numbers are schematic numbers; connector viewing orientation requires
silkscreen/continuity confirmation before physical wiring.
'''
(root/'docs/SERIALIZER_PINMAP.md').write_text(current_facts(pinmap),encoding='utf-8')
bank='''# Bank / VCCO audit — TASK-001B

State: SCHEMATIC_NOMINAL_COMPATIBLE; physical rails NOT_MEASURED.
Vivado confirms all 19 selected balls are Bank35 HR GPIO. It does not measure
VCCO. Core U31D Bank35 supply pins C19/H14/J17/K20/M16/N19 connect VCCB;
VCCB goes through R2460 (0 ohm) to VCC. U22/L7 output TP1 is labeled 3V3.
Bank34 uses VCCE via FB16 from the same nominal VCC rail. Core/expansion
revision and component population on the actual boards remain unconfirmed.

| Signal | Ball | Bank | Bank VCCO | IO standard | Connector | PCB voltage | AXC VCCA / VCCB |
|---|---|---|---|---|---|---|---|
'''
for s,c,p,b in selected:bank+=f'| {s} | {b} | 35 | 3.3V nominal, unmeasured | LVCMOS33 | {c}/{p} | UNKNOWN, PCB absent/unconfirmed | FPGA side 3.3V candidate / PCB side UNKNOWN |\n'
bank+='''
SN74AXC8T245 rails must each be within 0.65..3.6V; it is not a 5V translator.
If A is the FPGA side, DIR1/DIR2 high requests A-to-B; OE is referenced to
VCCA and a pull-up requests high impedance at startup. The translated
output_disable signal and translator OE are distinct nets. Minimum signal
capacity is 3 translators per board (ceil(19/8)), six total; real grouping,
pulls, power sequencing, direction and 595 /OE mapping require PCB schematic.
An unknown PCB-side supply is not an observed incompatibility, but does not
pass a physical connection gate. BANK_VCCO_PASS is false until the actual
board/header conditions are confirmed. No FPGA download should precede the
required physical checks and the Zynq default configuration review.

TI source: https://www.ti.com/lit/ds/symlink/sn74axc8t245.pdf (SCES875C).
'''
(root/'evidence/task001b/BANK_VCCO_REPORT.md').write_text(current_facts(bank),encoding='utf-8')
audit={'selected_array_gpio_count':19,'p1_count':14,'p2_count':5,'p3_count':0,'p5_count':0,'selected_duplicate_ball_count':0,'selected_duplicate_connector_pin_count':0,'array_sync_pin_conflict_count':0,'bank_mismatch_count':0,'schematic_nominal_vcco_conflict_count':0,'physical_confirmation':'USER_CONFIRMED_BANK35_VCCO_MODULE_REMOVAL' if bank35_measured else 'PENDING','pinmap_complete':True}
(root/'evidence/task001b/gpio_audit/mapping-audit.json').write_text(json.dumps(audit,indent=2)+'\n',encoding='utf-8')
print(json.dumps(audit))
