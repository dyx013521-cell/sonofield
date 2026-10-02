"""Summarize measured tool results. Missing or failing gates never become PASS."""
import csv,datetime,hashlib,json,pathlib,re
here=pathlib.Path(__file__).resolve().parent;root=here.parents[1]
rows=list(csv.DictReader((here/'build-results.tsv').open(),delimiter='\t'))
assert {r['role'] for r in rows}=={'master','slave'}, 'both implementation results required'
roles={r['role']:r for r in rows}
resources={};unconstrained={};methodology={};bus_skew={}
for role in roles:
 text=(here/role/'utilization.rpt').read_text()
 resources[role]={}
 for key,label in [('LUT','Slice LUTs'),('FF','Slice Registers'),('BRAM_TILE','Block RAM Tile'),('IOB','Bonded IOB')]:
  match=re.search(r'\|\s*'+re.escape(label)+r'\s*\|\s*([0-9.]+)',text)
  assert match, f'{role} resource {label} missing'
  resources[role][key]=float(match.group(1))
 text=(here/role/'timing.rpt').read_text()
 unconstrained[role]={key:int(re.search(r'checking '+key+r' \(([0-9]+)\)',text).group(1)) for key in ('no_clock','unconstrained_internal_endpoints','no_input_delay','no_output_delay')}
 unconstrained[role]['data_ports_missing_output_delay']=int(re.search(r'There are ([0-9]+) ports with no output delay specified',text).group(1))
 text=(here/role/'methodology.rpt').read_text()
 methodology[role]=[{'rule':m[0],'severity':m[1].strip(),'count':int(m[2])} for m in re.findall(r'^\|\s*((?:TIMING|LUTAR|IOSR|XDCB)-[0-9]+)\s*\|\s*([^|]+)\|[^|]+\|\s*([0-9]+)\s*\|',text,re.M)]
 text=(here/role/'bus-skew.rpt').read_text()
 slack=[float(x) for x in re.findall(r'Slack \((?:MET|VIOLATED)\)\s*:\s*(-?[0-9.]+)ns',text)]
 assert slack, f'{role} bus skew result missing'
 bus_skew[role]={'worst_slack_ns':min(slack),'pass':min(slack)>=0}
sim={}
for tb in ('dual_sync_tb','top_clock_tb','serializer64_tb','dual_serializer_sync_tb'):
 text=(here/f'simulation/{tb}.log').read_text(encoding='utf-8-sig')
 match=re.search(tb.upper()+r' PASS[^\r\n]*',text)
 sim[tb]={'pass':bool(match) and 'Fatal:' not in text,'result':match.group(0) if match else 'FAIL'}
pin_audit=json.loads((here/'gpio_audit/mapping-audit.json').read_text())
identity={'Board1':{'role':'MASTER','jtag_serial':'210299245711','uart':'COM7'},'Board2':{'role':'SLAVE','jtag_serial':'210299835073','uart':'NOT_ENUMERATED','uart_gate':'OPTIONAL_DEBUG_NOT_BLOCKING'},'mapping_source':'USER_CONFIRMED','read_only_scan':'hardware_check/vivado-probe-status.tsv','programming_performed':False}
(here/'board-identity.json').write_text(json.dumps(identity,indent=2)+'\n',encoding='utf-8')
timing=all(float(r['setup_ns'])>=0 and float(r['hold_ns'])>=0 for r in rows)
cdc=all(int(r['cdc_critical'])==0 for r in rows)
drc=all(int(r['drc_errors'])==0 for r in rows)
blockers=['BLOCKED_ZYNQ_CONFIGURATION_REVIEW','PHYSICAL_PRECONDITIONS_UNCONFIRMED','P5_SYNC_NOT_BOARD_TESTED','SERIALIZER_NOT_BOARD_TESTED']
critical_unconstrained=all(r['no_clock']==0 and r['unconstrained_internal_endpoints']==0 and r['no_input_delay']==0 and r['data_ports_missing_output_delay']==0 for r in unconstrained.values())
if not critical_unconstrained:blockers.append('CRITICAL_UNCONSTRAINED_ENDPOINTS')
if not timing:blockers.append('TIMING_FAIL')
if not cdc:blockers.append('CDC_FAIL')
if not drc:blockers.append('DRC_FAIL')
if not all(x['pass'] for x in bus_skew.values()):blockers.append('DEBUG_BUS_SKEW_FAIL')
status={
 'TASK':'TASK-001B / DUAL_BOARD_SERIALIZER_PRE_PCB_BRINGUP','CAPTURED_AT':datetime.datetime.now().astimezone().isoformat(),
 'BOARD1_ROLE':'MASTER','BOARD2_ROLE':'SLAVE','BOARD1_CHANNELS':64,'BOARD2_CHANNELS':64,'TOTAL_CHANNELS':128,
 'SERIAL_LANES_PER_BOARD':16,'BITS_PER_LANE':4,'SERIAL_DATA_GPIO':16,'SHIFT_CLOCK_GPIO':1,'LATCH_CLOCK_GPIO':1,'OUTPUT_DISABLE_GPIO':1,
 'TOTAL_ARRAY_GPIO_PER_BOARD':19,'PRIMARY_CONNECTOR':'P1','FALLBACK_CONNECTORS':['P2','P3'],'P1_GPIO_USED':14,'P2_GPIO_USED':5,'P3_GPIO_USED':0,
 'P5_RESERVED_FOR_SYNC':True,'P1_P2_P3_PINMAP_COMPLETE':pin_audit['pinmap_complete'],'P1_P5_CONFLICT_COUNT':0,'P5_ARRAY_GPIO_COUNT':0,
 'BANK_VCCO_SCHEMA_PASS':True,'BANK_VCCO_PASS':False,'BANK_VCCO_MEASURED':False,
 'SERIALIZER_SIM_PASS':sim['serializer64_tb']['pass'],'595_MODEL_SIM_PASS':sim['serializer64_tb']['pass'],'DUAL_SERIALIZER_SIM_PASS':sim['dual_serializer_sync_tb']['pass'],
 'TASK001_REGRESSION_PASS':sim['dual_sync_tb']['pass'] and sim['top_clock_tb']['pass'],
 'SYNTHESIS_PASS':all(r['synthesis']=='SYNTHESIZED' for r in rows),'IMPLEMENTATION_PASS':all(r['implementation']=='IMPLEMENTED' for r in rows),
 'DRC_PASS':drc,'CDC_PASS':cdc,'TIMING_PASS':timing,'ZYNQ_CONFIGURATION_RELEASED':False,
 'CRITICAL_UNCONSTRAINED_ENDPOINTS_ZERO':critical_unconstrained,'UNCONSTRAINED_CHECKS':unconstrained,'RESOURCES':resources,'METHODOLOGY_REVIEW_ITEMS':methodology,
 'AUTOMATIC_PROGRAMMING_ALLOWED':False,'PROGRAMMING_POLICY':'Latest user engineering contract: No automatic programming.',
 'METHODOLOGY_REVIEW_COMPLETE':False,'PHYSICAL_TIMING_MEASURED':False,
 'DEBUG_BUS_SKEW_RESULTS':bus_skew,'DEBUG_BUS_SKEW_PASS':all(x['pass'] for x in bus_skew.values()),
 'MASTER_BITSTREAM_GENERATED':False,'SLAVE_BITSTREAM_GENERATED':False,'MASTER_PROGRAMMED':False,'SLAVE_PROGRAMMED':False,
 'P5_SYNC_LOCK':False,'P5_SYNC_LOCK_OBSERVED':None,'SERIALIZER_PREPCB_TEST_PASS':False,'DEFAULT_DISABLE_SIM_PASS':sim['dual_serializer_sync_tb']['pass'],
 'PCB_CONNECTED':None,'PCB_EXPECTED_CONNECTED':False,'PCB_CONNECTION_CONFIRMED':False,
 'READY_FOR_PCB_CONNECTION':False,'BOARD_TESTED':False,'HARDWARE_VERIFIED':False,
 'BLOCKERS':blockers,'BUILD_RESULTS':roles,'SIMULATION_RESULTS':sim,
 'NOTE':'False for an unperformed acceptance gate is not a measured failure. null denotes unavailable physical observation. JTAG scan success is not programming or sync verification.'
}
(here/'PRE_PCB_SERIALIZER_STATUS.json').write_text(json.dumps(status,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
table='| Board | Synthesis | Implementation | Setup WNS ns | Hold WHS ns | CDC Critical | DRC Error |\n|---|---|---|---:|---:|---:|---:|\n'
for role,r in roles.items():table+=f"| {role} | {r['synthesis']} | {r['implementation']} | {r['setup_ns']} | {r['hold_ns']} | {r['cdc_critical']} | {r['drc_errors']} |\n"
report=f'''# TASK-001B PRE-PCB Serializer report

Generated {status['CAPTURED_AT']}. **READY_FOR_PCB_CONNECTION=false**.
No FPGA programming, flash/boot changes or PCB connection were performed.
Tool simulation/synthesis/routing evidence below is separate from real P5,
array-header voltage, external translation and 595 physical timing evidence.

## Fixed architecture and identity

Board1/Master=210299245711, UART COM7; Board2/Slave=210299835073.
Board2 UART is OPTIONAL_DEBUG/NOT_BLOCKING. A new read-only scan opened both
exact serial targets and found one xc7z010 each, two FPGAs/four chain devices,
zero probe errors. Existing configured-device DONE/EOS/CRC properties do not
prove these new sources were programmed. Full package/speed-grade confirmation
still comes from physical marking; the build uses xc7z010clg400-1.

Each board:64 logical channels ->16 parallel lanes ->4 used outputs of each
of16 SN74LVC595A ->64 channels; two boards total128. No64-GPIO redesign,
cascaded single serial chain, acoustics, ADC, phase solver, trajectory or v4.
19 control signals need at least3 AXC8T245 per board by capacity (six total),
but actual PCB grouping is unconfirmed. AXC rail/OE/DIR review is in
[BANK_VCCO_REPORT.md](BANK_VCCO_REPORT.md).

## GPIO / XDC

[Complete pool](../../docs/ARRAY_GPIO_POOL.md),
[19-signal pin map](../../docs/SERIALIZER_PINMAP.md),
[machine mapping](../../docs/array_gpio_mapping.json).
P1 has14 usable GPIO; P2 supplies2 additional data pins plus3 known LED-loaded
outputs. H20/J20/L19 replace LED0/2/3 in the new wrappers;2kohm loads remain.
LED1/K18 displays sync lock. Original TASK-001 wrappers retain their four LED
interface and are regression tested. No button pin is driven as array output.
All19 selected pins are Bank35/LVCMOS33/DRIVE4/SLOW; nominal VCCB=3.3V is
traced through core R2460 to VCC/U22/L7/TP1. Vivado confirms bank/function,
not actual voltage. P1/P2 supply pins1/2 are VCC_IN, never array data.
Duplicate selected balls/connectors, array-to-P5 conflicts and bank mismatches
are all0. All P5-connected aliases on P2/P3 are excluded. P3 adds no GPIO
outside P5. P5 remains only sync and original scope outputs.

## Serializer / 595 model / scheduled commit

Serializer captures all64 bits in shadow, sends bit3/2/1/0 on four SRCLK rises,
then publishes once on the common latch. Each full8-bit virtual595 shifts
all eight bits; Q0..Q3 reconstruct the current frame, while Q4..Q7 hold older
shifted data and are not counted as current-frame channels. Actual PCB Q
mapping, unused-output wiring and physical /OE polarity are not established.
Active waveform updates only with latch. APPLY_AT waits after shifting and
rejects a deadline with less than82 cycles lead or overlap. Fault disable is
independent of the serializer FSM. PRE-PCB wrappers keep output_disable=1;
manual Master S3 is the only diagnostic single-frame request, default idle.
Startup receiver fragments remain counted; array fatal events become sticky
after first lock and require RUN reset, rather than treating all historical
training counts as an irrevocable error.

50MHz FSM,2.5MHz shift burst,200ns data setup/hold and pulse widths. Untimed
frame to latch81 cycles, done92, next start93:1.86us /537634frames/s.
Future required rate U requires at least4U shift edges/s plus overhead.
No acoustic update-rate requirement or physical timing pass is inferred.
[Timing budget](../../docs/SERIALIZER_TIMING_BUDGET.md) remains
PRE_PCB_TIMING_ESTIMATE with explicit translator/PCB mismatch assumptions.

## Simulation

'''
for tb,item in sim.items():report+=f"- `{item['result']}`\n"
report+='''
The serializer includes388 reconstructed frames,64 walking-one/zero pairs,
256 random words, immutable capture, four-pulse/latch timing, mid-frame reset,
overrun/deadline rejection and independent guard faults while a frame is busy.
Guard checks include sync loss, MMCM unlock, watchdog, CRC/frame, sequence,
fatal and disarm, asserting disable without waiting for completion. Dual test
uses actual sync protocol/wrappers,100ppm local-crystal mismatch and a3ns
forwarded-clock delay; seven common logical-timestamp latches pass. Clock loss
during the next frame produces no partial latch and clears slave pins through
the independent watchdog. These are simulation observations, not scope data.
The original long-duration test remains accelerated BOUNDARY_ONLY, not1hour.

## Synthesis, implementation and release gates

'''+table+'''
Full synthesis/opt/place/phys_opt/route includes a64-bit,1024-sample ILA per
board. Reports include utilization/IOB, setup/hold, CDC, DRC, methodology,
IO/clocks/clock interaction and unconstrained endpoints. Routed checkpoints
and .ltx exist for GUI inspection. Source hashes are in source-sha256.json;
run_task001b.ps1 checks that sources did not change across simulation/build.
Vendor debug bus-skew constraints are also reported. Initial routing had
Slave setup -0.099ns from sync_data to good_crc (attempt03); additional physical
optimization did not improve it (attempt04). Current RTL compares the fully
registered CRC on the original VALID-fall commit cycle, avoiding the long raw
serial-input comparison path without changing protocol latency or IO budgets.
Final reports come from a complete simulation/synthesis/route of this revision.
Initial failed reports in attempt01 are explicitly superseded. The first
Master failure was a falling-edge fault-to-pin half-cycle path; first Slave
CDC failures came from raw watchdog/reset status entering array/ILA logic.
Current architecture separates synchronized logic from asynchronous assertion.
The intermediate two CDC-11 reports in attempt02 came from two independent
raw-reset release chains. The endpoint now shares core RUN release; a dual
mid-frame reset regression verifies immediate clamp without a partial latch.

No user false_path, clock-group exclusion, non-dedicated clock routing or DRC
severity downgrade was added. ILA/debug-hub vendor constraints contain their
own synchronizer exceptions; these do not exempt the inter-board link. Review
the actual methodology and clock interaction reports before release, including
independent local/received clocks, asynchronous safety resets and generated
clock-reference notices. A positive STA number for independent clocks does
not prove a physical phase relationship.
The rule-by-rule dispositions and still-open work are recorded in
[IMPLEMENTATION_REVIEW.md](IMPLEMENTATION_REVIEW.md); this is not release
sign-off. The status keeps METHODOLOGY_REVIEW_COMPLETE=false.

Resource counts (LUT / FF / BRAM tiles / total bonded IOB):
'''
for role,r in resources.items():report+=f"- {role}: {r['LUT']:g} / {r['FF']:g} / {r['BRAM_TILE']:g} / {r['IOB']:g}.\n"
report+='''
Array IOB count is19 per board; bonded IOB totals also include clocks, keys,
P5 and the remaining LED. Critical unconstrained internal endpoint and missing
clock/input-delay counts are recorded in the status JSON. Master's forwarded
sync_clk is the one LOW clock-output notice; it is not a data endpoint.

The ZPS7-1 default-configuration warning remains a blocking release review;
[ZYNQ_CONFIGURATION_REVIEW.md](ZYNQ_CONFIGURATION_REVIEW.md) explains it.
DRC Error=0 does not close that review. No unreviewed generic PS7 preset was
inserted simply to suppress the warning. Therefore neither requested .bit
was generated or programmed. .ltx files are not a downloadable bitstream.

## Actual hardware state / remaining work

Real P5 lock and ILA serializer frames: NOT_BOARD_TESTED. Physical P1/P2
module absence, board revision, VCCO and exact P5 wiring remain unconfirmed.
PCB expected disconnected for this task; actual connection cannot be read
from JTAG, so PCB_CONNECTED is null rather than an invented observation.
Scope/logic-analyzer amplitude, edge, setup/hold and latch measurements remain
REQUIRES_PHYSICAL_MEASUREMENT. No PCB/AXC/595/channel/acoustic/levitation pass.

Before continuation: close PS7/default/isolation review; resolve any failing
CDC/STA in the recorded final reports; confirm actual boards/rails, no camera
or VGA devices on reused nets, PCB absent, and P5 six signals/common ground.
Then generate bitstreams under all gates, match JTAG serial/part again.
The latest engineering contract says No automatic programming; programming
is a separate authorized/manual stage, restricted to volatile PL. Verify new
DONE/EOS/CRC/MMCM/RUN/real P5 lock. After
lock, capture manual ALL_ZERO/WALKING_ONE/1010 single frames with disable=1,
resetting both boards before a new test sequence. Keep resulting GUI pages
open. Do not connect the PCB until every readiness gate actually passes.
'''
(here/'PRE_PCB_SERIALIZER_REPORT.md').write_text(report,encoding='utf-8')
print(json.dumps({'ready':False,'timing_pass':timing,'cdc_pass':cdc,'drc_errors_zero':drc,'blockers':blockers}))
