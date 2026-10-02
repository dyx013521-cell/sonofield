# TASK-001 hardware availability

Read-only Vivado2025.2 Hardware Manager probe: **TARGET_COUNT0**. Raw result: `hardware_probe.txt`.
Windows PowerShell7 inventory: `windows_device_inventory.json`; only matching Bluetooth COM ports were present.
This establishes that no accessible JTAG target was discovered in this scan. It does not identify the physical
board on the desk, prove that it is powered, or prove any particular driver/cable fault.

No FPGA programming, memory writes, board reset, electrical measurement or oscilloscope acquisition was
performed. Both board identity and instrument availability must be established before hardware acceptance.

BOARD_TESTED: false. HARDWARE_VERIFIED: false. See `v3/docs/HANDOFF.md` for required parameters and sequence.
