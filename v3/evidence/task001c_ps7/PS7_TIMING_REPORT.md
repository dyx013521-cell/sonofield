# PS7 timing gate / NOT_RUN

No new synthesis/opt/place/phys_opt/route exists. No Phase-A setup/hold value,
timing delta or effect attributable to PS7 can be reported.

| Historical TASK-001B baseline | Setup ns | Hold ns |
|---|---:|---:|
| Master | 0.494 | 0.007 |
| Slave | 0.430 | 0.015 |

These are prior implementation values, not rerun results. The PL RTL and
XDC are unchanged. Actual N18 remains 50 MHz; PS clock remains separate and
unknown. No false paths, clock groups, routing overrides or FCLK replacement
were introduced. Four fresh simulations and both fresh implementations are
still required after a justified PS7 profile is created.
