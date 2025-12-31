# FPGA-Based Digital Stroboscope for MEMS Vibration Visualization

## Overview

This repository contains the implementation of an **automatic digital LED stroboscope designed for the visualization of vibrations in MEMS structures**, developed as a final engineering (BSc) thesis project.

The system is implemented on an FPGA platform and enables real-time synchronization of stroboscopic illumination with the vibration frequency of the observed object. By introducing a configurable frequency offset, the design allows controlled aliasing, making mechanical vibrations visually observable as slowed-down or frozen motion.

Two independent measurement approaches were designed, implemented, and experimentally verified on FPGA:
- **Period-based measurement**
- **Frequency-based measurement**

Both approaches were evaluated under identical hardware conditions, allowing a direct comparison of accuracy, stability, and implementation complexity.

---

## Motivation

Although numerical simulation methods are widely used, **direct visualization of mechanical vibrations** remains an important tool in experimental analysis and education. Stroboscopic illumination enables observation of resonance, anti-resonance, and natural vibration modes without complex simulation setups.

Thanks to modern high-power LEDs and digital logic, stroboscopic systems can now be implemented using **fully digital control**, offering flexibility, repeatability, and real-time configurability. This project explores such a digital approach using FPGA technology.

---

## System Architecture

The stroboscope system consists of the following main components:

- FPGA-based digital processing core
- High-speed input signal conditioning
- LED driver output stage
- External excitation source (function generator)
- Custom-designed PCB

### FPGA Platform
- Development board: **ARTY A7-100**
- FPGA: **Xilinx Artix-7**
- Hardware description language: **VHDL**

Using FPGA technology allows rapid prototyping and easy modification of system behavior, making it possible to adapt the stroboscope to a wide range of excitation frequencies without hardware changes.

---

## Measurement Methods

### Period-Based Measurement
This approach measures the time interval between consecutive edges of the input signal. The measured period is then used to derive the LED stroboscopic frequency.

**Characteristics:**
- High resolution at low frequencies
- Simple control logic
- Increased sensitivity to input jitter

---

### Frequency-Based Measurement
This method counts the number of input signal cycles within a fixed time window to estimate the input frequency.

**Characteristics:**
- Better stability at higher frequencies
- Predictable averaging behavior
- Slightly higher FPGA resource usage

---

## Frequency Offset and Aliasing Control

To visualize vibrations, the stroboscope output frequency can be intentionally offset relative to the input excitation frequency.

Example:
- Input excitation frequency: **100 Hz**
- LED strobe frequency: **101 Hz**

This controlled offset produces an aliasing effect, resulting in an apparent slow-motion visualization of vibrations. The offset value is **user-configurable**, allowing flexible exploration of vibration behavior.

---

## Hardware Interface

### Input Signal Conditioning

The excitation signal applied to the piezoelectric actuator has an amplitude of approximately ±10 V. To interface this signal with FPGA logic operating at 3.3 V, a dedicated conditioning circuit is used.

- Input voltage divider
- High-speed comparator with propagation delay ≤ 10 ns

**Comparator used:**
- **TLV3511** (Texas Instruments)
- ~6 ns propagation delay
- Push–pull output

This ensures reliable edge detection for input frequencies up to hundreds of kilohertz.

---

### LED Driver Stage

FPGA GPIO pins are not capable of sourcing the current required for high-intensity stroboscopic illumination. Therefore, a dedicated MOSFET driver is used.

- **TC4420** (Microchip)
- Logic-level compatible input
- Output current capability up to 6 A

This stage enables short, high-current LED pulses required for effective stroboscopic operation, even at high repetition rates.

---

## FPGA Implementation

- Fully synchronous VHDL design
- Deterministic timing behavior
- Configurable frequency offset generation
- Operational input frequency range: **100 Hz – 350 kHz**
- Output architecture prepared for frequencies up to **1 MHz**

Both measurement approaches were implemented and tested on the same FPGA device, allowing direct comparison of:
- Measurement accuracy
- Output frequency stability
- FPGA resource utilization
- Quality of the stroboscopic effect

---

## Experimental Validation

The system was successfully implemented on FPGA and verified experimentally using:
- Function generator for piezoelectric excitation
- LED-based stroboscopic illumination
- MEMS / piezoelectric structure under test

The experiments confirmed correct operation of the stroboscope and demonstrated effective visualization of vibration phenomena.

---

## Additional Materials

- 📷 Custom PCB design (schematics and layout)
  ![Electronic schema of PCB](images/praca_inżynierska.pdf)
- 🎥 Demonstration video showing real-time stroboscopic operation
  ![The stroboscope demo recording](Media/stroboscope.mp4)

This recording captures the audible behavior of the stroboscopic system during operation and complements the visual demonstration.




---

## Key Features

- FPGA-based digital stroboscope
- Two independent frequency measurement methods
- Real-time frequency offset control
- High-speed input signal conditioning
- High-current LED driver stage
- Visualization of MEMS vibrations
- Fully synthesizable VHDL implementation

---

## Technologies Used

- FPGA: Xilinx Artix-7 (ARTY A7-100)
- HDL: VHDL
- Digital design: counters, FSMs, timing logic
- Hardware: comparator, MOSFET driver, custom PCB
- Measurement: function generator, LED stroboscopy

---

## Author

**Szymon Mazur**  
Final Engineering Thesis – FPGA-Based Digital Stroboscope

---


