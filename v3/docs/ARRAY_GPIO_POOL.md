# Array GPIO pool — TASK-001B

Sources: core and expansion PDFs page 1, visually reviewed; exact Vivado
2025.2 xc7z010clg400-1 database in `gpio_audit/package-pins.tsv`.
All P5-connected balls are excluded, including their aliases on P2/P3.
P1 contains 14 GPIO, not 16 or 19. P2 adds G20/J18 and three explicitly
repurposed LED outputs H20/J20/L19. P3 adds no unique GPIO outside P5.
There are 19 selected outputs, all Bank35. P1/P2 pin1/2 are VCC_IN,
not logic pins or a guaranteed 3.3V supply. Pin10 is NC and pin12 is ground.
The core adds 22 ohm series resistors between FPGA balls and DATA headers.
Camera/VGA/header nets have parallel connectors; VGA/Camera modules are
USER_CONFIRMED removed on 2026-10-02. Hardwired branches remain. LEDs retain their 2 kohm series loads; worst
case current with a zero-volt LED-drop bound is 3.3/2000=1.65mA. DRIVE=4mA,
SLEW=SLOW is a conservative initial setting, not waveform qualification.
No button, JTAG, MIO or DDR ball is repurposed. LED1/K18 remains a sync LED.
Connector duplicate aliases are listed intentionally; selected duplicates are
checked separately and are zero. This table is not permission to wire a PCB.

| Connector | Pin | FPGA Ball/net | Bank | VCCO | Current use | Available | Selected role |
|---|---:|---|---|---|---|---|---|
| P1 | 1 | VCC_IN | - | - | VCC_IN | NO_GPIO | - |
| P1 | 2 | VCC_IN | - | - | VCC_IN | NO_GPIO | - |
| P1 | 3 | GND | - | - | GND | NO_GPIO | - |
| P1 | 4 | GND | - | - | GND | NO_GPIO | - |
| P1 | 5 | A20 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[0] |
| P1 | 6 | H16 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[1] |
| P1 | 7 | B19 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[2] |
| P1 | 8 | B20 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[3] |
| P1 | 9 | C20 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[4] |
| P1 | 10 | NC | - | - | NC | NO_GPIO | - |
| P1 | 11 | H17 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[5] |
| P1 | 12 | GND | - | - | GND | NO_GPIO | - |
| P1 | 13 | D20 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[6] |
| P1 | 14 | D18 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[7] |
| P1 | 15 | H18 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[8] |
| P1 | 16 | D19 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[9] |
| P1 | 17 | F20 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[10] |
| P1 | 18 | E19 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[11] |
| P1 | 19 | F19 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[12] |
| P1 | 20 | K17 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[13] |
| P2 | 1 | VCC_IN | - | - | VCC_IN | NO_GPIO | - |
| P2 | 2 | VCC_IN | - | - | VCC_IN | NO_GPIO | - |
| P2 | 3 | GND | - | - | GND | NO_GPIO | - |
| P2 | 4 | GND | - | - | GND | NO_GPIO | - |
| P2 | 5 | G20 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[14] |
| P2 | 6 | J18 | 35 | 3.3V USER_CONFIRMED_MEASURED | Camera header parallel net | REUSABLE_PERIPHERAL_PIN | serial_data[15] |
| P2 | 7 | G19 | 35 | 3.3V USER_CONFIRMED_MEASURED | S1 reset | HARD_CONFLICT | - |
| P2 | 8 | H20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LED0/R9 2k | REUSABLE_PERIPHERAL_PIN | shift_clock |
| P2 | 9 | J19 | 35 | 3.3V USER_CONFIRMED_MEASURED | S2 scheduled epoch reset | HARD_CONFLICT | - |
| P2 | 10 | NC | - | - | NC | NO_GPIO | - |
| P2 | 11 | K18 | 35 | 3.3V USER_CONFIRMED_MEASURED | LED1/R10 2k retained sync indicator | HARD_CONFLICT | - |
| P2 | 12 | GND | - | - | GND | NO_GPIO | - |
| P2 | 13 | K19 | 35 | 3.3V USER_CONFIRMED_MEASURED | S3 manual scheduled test | HARD_CONFLICT | - |
| P2 | 14 | J20 | 35 | 3.3V USER_CONFIRMED_MEASURED | LED2/R11 2k | REUSABLE_PERIPHERAL_PIN | latch_clock |
| P2 | 15 | L16 | 35 | 3.3V USER_CONFIRMED_MEASURED | S4/220R to ground when pressed | HARD_CONFLICT | - |
| P2 | 16 | L19 | 35 | 3.3V USER_CONFIRMED_MEASURED | LED3/R12 2k | REUSABLE_PERIPHERAL_PIN | output_disable |
| P2 | 17 | M18 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P2 | 18 | L20 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P2 | 19 | M20 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P2 | 20 | L17 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 1 | VCC_IN | - | - | VCC_IN | NO_GPIO | - |
| P3 | 2 | VCC_IN | - | - | VCC_IN | NO_GPIO | - |
| P3 | 3 | GND | - | - | GND | NO_GPIO | - |
| P3 | 4 | GND | - | - | GND | NO_GPIO | - |
| P3 | 5 | M19 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 6 | N20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 7 | P18 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 8 | M17 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 9 | N17 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 10 | NC | - | - | NC | NO_GPIO | - |
| P3 | 11 | P20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 12 | GND | - | - | GND | NO_GPIO | - |
| P3 | 13 | R18 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 14 | R19 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 15 | P19 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 16 | T20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 17 | U20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 18 | T19 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 19 | V20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P3 | 20 | U19 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | - |
| P5 | 1 | GND | - | - | GND | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 2 | VCC_3V3 | - | - | VCC_3V3 | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 3 | M18 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 4 | L20 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 5 | M20 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 6 | L17 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 7 | N20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 8 | M19 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 9 | M17 | 35 | 3.3V USER_CONFIRMED_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 10 | P18 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 11 | P20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 12 | N17 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 13 | R19 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 14 | R18 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 15 | T20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 16 | P19 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 17 | T19 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 18 | U20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 19 | U19 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 20 | V20 | 34 | 3.3V schematic nominal / NOT_MEASURED | VGA/header parallel net | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 21 | NC | - | - | NC | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 22 | NC | - | - | NC | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 23 | TXD | - | - | TXD | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 24 | RXD | - | - | RXD | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 25 | NC | - | - | NC | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 26 | NC | - | - | NC | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 27 | NC | - | - | NC | RESERVED_SYNC | RESERVED_SYNC |
| P5 | 28 | NC | - | - | NC | RESERVED_SYNC | RESERVED_SYNC |
