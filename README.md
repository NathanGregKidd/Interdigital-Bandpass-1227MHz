# ⚡Interdigital-Bandpass-1240MHz
An interdigital microstrip bandpass filter with a center frequency of 1240MHz. Kicad design files, Electromagnetic Simulations, fabrication files, and test data.

Despite not *technically* being microwave frequency, this microwave structure still applies to S, X, Ku, etc. bands. I used this frequency because I only have a NanoVNA which can measure up to 2GHz.

### Summary
This project will showcase my ability to design, fabricate, and test a 1240MHz microwave structure. The design stage will start with calculations. Simulations will be done in QUCS (an open-source version of Keysight ADS) and Sonnet Lite (a free 2.5D Method of Moments EM solver). If possible, a free evaluation license will be acquired for ADS and HFSS in order to validate QUCS and Sonnet Lite as well as build skills. The fabrication stage will be done with KiCad and whichever fab-house works the best. Right now I am expecting to use JLCPCB, with FR4 substrate. The testing stage will be done with a NanoVNA (VNA with LO up to 2GHz) and the VNA results will be compared with the simulation results.

Skills (that will be) showcased:
- Microwave Structures
- Impedence control
- Stackup management
- Keysight ADS (in the form of QUCS, an open source "copy" and following ADS workflows)
- 2.5D Electromagnetic solver and optimization
- PCB design, assembly, and test
- VNA
- Smith Charts
- S parameters

### 💡Current Status💡
Design Phase
- Currently calculating and setting up a baseline geometry for the filter before optimizing in the simulators.

# ✅ Design Requirements 📖✏️

| Parameter                        | Value     | Units |
|----------------------------------|-----------|-------|
| Center Frequency, f<sub>0</sub>  | 1240      | MHz   |
| Fractional Bandwidth             | 1         | %     |
| Filter order                     | 5         |       |
| Filter type                      | Chebshyev |       |
| Passband ripple                  | 0.1       | dB    |
| Input/output impedance           | 50        | ohm   |
| Insertion loss target            | &ge;1     | dB    |
| Return loss target               | &le;20    | dB    |


The center frequency was chosen because I have the equipment to test it. In addition, the geometries are larger and will be easier to trim/modify if necessary.

The fractional bandwidth was chosen to be 1% because this is meant to be a narrowband filter. Thus, the cutoff frequencies are as follows:

$$FBW*f_0 = BW$$
$$BW = 12.4MHz$$
$$f_{low} = f_0 - \frac{BW}{2} = 1233.8$$
$$f_{high} = f_0 + \frac{BW}{2} = 1246.2$$

