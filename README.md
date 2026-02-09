# RTL Design of UART Communication Interface

## Overview
This project implements a **UART (Universal Asynchronous Receiver Transmitter)** communication interface using **SystemVerilog**, supporting full-duplex serial communication.

The design includes **UART transmit and receive paths**, configurable control registers, and FIFO-based buffering for reliable data transfer.

---

## Architecture Description

### UART Register Block
- Implements control and status registers
- Supports:
  - Baud rate generation
  - Word length selection
  - Parity configuration
  - FIFO enable and threshold control

### Transmitter (TX)
- Serializes parallel data from TX FIFO
- Supports:
  - Start, data, parity, and stop bits
  - Configurable parity and word length
- Operates using generated baud pulse

### Receiver (RX)
- Deserializes incoming serial data
- Detects:
  - Parity error
  - Framing error
  - Break interrupt
- Pushes received data into RX FIFO

### FIFO Buffers
- Separate FIFOs for TX and RX paths
- Prevent data loss during burst transfers
- Support programmable threshold levels

---

## Module Hierarchy
- `all_mod` (Top-level UART module)
  - `regs_uart` – Control and status registers
  - `uart_tx_top` – UART transmitter
  - `uart_rx_top` – UART receiver
  - `fifo_top` – TX FIFO
  - `fifo_top` – RX FIFO

---

## Verification
- Functional verification performed using simulation
- Verified:
  - Correct baud-based data transmission
  - RX/TX FIFO operation
  - Error detection mechanisms
  - Register-controlled behavior

---

## Tools Used
- RTL Design: SystemVerilog
- Simulation: Xilinx Vivado / XSIM

---

## Applications
- Serial communication controllers
- Embedded systems
- FPGA-based peripheral interfaces
