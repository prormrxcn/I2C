# I2C Master Controller

A configurable I2C master controller module written in Verilog HDL for FPGA/ASIC implementations.

## Features

- Configurable address and data widths
- Standard I2C protocol compliant
- Supports both read and write operations
- Automatic start/stop condition generation
- Built-in clock generation (SCL)
- Bidirectional data line (SDA) with tri-state control
- Asynchronous active-low reset

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `address_width` | 8 | Width of slave address bus |
| `data` | 8 | Width of data bus |

## Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | Input | 1 | System clock |
| `rst_n` | Input | 1 | Active-low asynchronous reset |
| `address` | Input | `address_width` | Target slave address |
| `scl` | Output | 1 | Serial clock line |
| `sda` | Inout | 8 | Serial data line (LSB used) |

## Quick Start

### Instantiation Example

```verilog
// 7-bit addressing mode (standard I2C)
I2C #(
    .address_width(7),
    .data(8)
) i2c_master (
    .clk(sys_clk),      // System clock
    .rst_n(reset_n),    // Active-low reset
    .address(7'h50),    // Slave device address
    .scl(scl_line),     // Serial clock
    .sda(sda_bus)       // Serial data
);
```

### Required External Components

- Pull-up resistors (4.7kΩ typical) on both SCL and SDA lines
- Stable system clock source

## Operation

### SCL Frequency

The SCL clock frequency is derived from the system clock:
- **SCL = System Clock / 18**

Examples:
- 50 MHz clock → ~2.78 MHz SCL
- 10 MHz clock → ~556 kHz SCL
- 1 MHz clock → ~55.6 kHz SCL

### Write Operation

1. Master generates START condition
2. Transmits slave address with R/W bit = 0
3. Waits for ACK from slave
4. Transmits data byte
5. Waits for ACK from slave
6. Generates STOP condition

### Read Operation

1. Master generates START condition
2. Transmits slave address with R/W bit = 1
3. Waits for ACK from slave
4. Receives data byte from slave
5. Generates STOP condition

## Signal Timing

```
START            Address + R/W    ACK      Data       ACK     STOP
  │                  │            │        │          │        │
  ▼                  ▼            ▼        ▼          ▼        ▼
SDA: ──┬─────────────┬────────────┬────────┬──────────┬─────────┬──
      │             │            │        │          │         │
      └─────────────┴────────────┴────────┴──────────┴─────────┘
SCL:  ‾‾‾\________/‾‾‾\______/‾‾‾\______/‾‾‾\______/‾‾‾\______/‾‾‾
```

## Important Notes

1. **Pull-up Resistors Required**: The SDA and SCL lines require external pull-up resistors as the module only drives SDA low and releases it high (tri-state).

2. **Only sda[0] Used**: The 8-bit SDA bus uses only bit 0 for I2C communication. The remaining bits are reserved.

3. **Reset State**: When reset is asserted (rst_n = 0), SDA is released (high-impedance) and SCL stops toggling.

4. **Single Byte Transfer**: This module transfers one byte per transaction. Multiple bytes require multiple start/stop sequences.

## Limitations

- No multi-master arbitration
- No clock stretching support
- No error recovery on NACK
- Single byte per transaction only

## License

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/
