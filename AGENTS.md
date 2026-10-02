# SonoField v3 engineering contract
Repository: https://github.com/dyx013521-cell/sonofield.git
Active version v3; TASK-001 / DUAL_BOARD_TIMING_SYNCHRONIZATION.
All orchestration uses PowerShell 7 (pwsh), never Windows PowerShell 5.
Vivado 2025.2; part xc7z010clg400-1; EBAZ4205 X5/N18=50 MHz, period20 ns.
Do not default to xc7z020 or 33.333 MHz. No v4.
This task only implements dual-board timing: no acoustics, ADC, power, phase solver or trajectory code.
Keep simulation, synthesis, implementation, timing and measured hardware evidence separate.
Do not use false paths or non-dedicated clock routing to hide problems.
Physical pin assignments must be traced to EBAZ4205 schematics and validated against the device database.
No physical synchronization/levitation claims without measurements. No automatic programming.
Before changing interfaces, update v3/docs/ARCHITECTURE.md and associated tests.
