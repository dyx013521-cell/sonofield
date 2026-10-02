# Zynq default configuration gate — NOT_RELEASED

The TASK-001 PL-only baseline and initial TASK-001B implementation have a
Vivado ZPS7-1 warning: "The PS7 cell must be used in this Zynq design in order
to enable correct default configuration." The serializer extension does not
add an unreviewed PS7 primitive merely to remove the warning.

An actual EBAZ PS7 profile, board revision, current boot firmware and PS/PL
isolation behavior have not been established for these two physical boards.
No PS initialization Tcl, DDR/MIO register writes, boot-media writes or PS
reset are performed. The exact JTAG devices being xc7z010 does not supply a
verified PS7 configuration. Treat this as BLOCKED_ZYNQ_CONFIGURATION_REVIEW
for a downloadable release, even when DRC Error count is zero.

The existing Vivado Quick Start recent project C:/amd/project_1 was checked
read-only: its .xpr targets xc7z010iclg225-1L, with no board preset recorded.
It is not this EBAZ xc7z010clg400-1 project and supplies no reusable reviewed
PS7 profile. That project was not changed.

Resolve with a reviewed minimal PS7 configuration appropriate to the actual
boards, explicit PS/PL boundary tie-offs, regenerated implementation/DRC/STA,
and confirmed boot/isolation behavior. Do not reuse another Zynq board preset,
lower DRC severity, add arbitrary clock exceptions or assume PS firmware
initializes PL correctly. This report does not assert a board is electrically
damaged; it records that the requested safe release gate is not established.

AMD documentation distinguishes the PL bitstream from PS register
initialization: PS configuration generates initialization for DDR/MIO/SLCR.
Source: https://docs.amd.com/r/en-US/ug821-zynq-7000-swdev/Zynq-PS-Configuration
and https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Device-Boot-and-PL-Configuration

The TASK-001B attachment allowed volatile JTAG under engineering gates. The
latest user engineering contract subsequently says "No automatic programming."
No programming is performed in this run. Independently, the PS7/default
configuration release gate remains unmet; it must be closed before any future
download, even if programming is separately authorized or performed manually.
