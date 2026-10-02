# TASK-001 routed resource usage

| Resource | Master used | Slave used | Z7010 available |
|---|---:|---:|---:|
| Slice LUTs | 635 | 562 | 17600 |
| Slice Registers | 616 | 615 | 35200 |
| Block RAM Tile | 0 | 0 | 60 |
| DSPs | 0 | 0 | 80 |
| Bonded IOB | 16 | 14 | 100 |
| BUFGCTRL | 2 | 3 | 32 |
| MMCME2_ADV | 1 | 1 | 2 |

Per device, not the sum of two boards. Source: each `utilization.rpt`. No acoustic channel capacity is inferred from this timing-only baseline.
