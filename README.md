# ⚡Interdigital-Bandpass-1240MHz
An interdigital microstrip bandpass filter with a center frequency of 1227.60MHz. Kicad design files, Electromagnetic Simulations, fabrication files, and test data. 

This filter seperates out the L2 signal from L1 and L5 signals coming from GPS transmitters.

### Objective
This project will showcase my ability to design, fabricate, and test a 1227.6MHz microwave structure. The design stage will start with calculations. Simulations will be done in QUCS (an open-source version of Keysight ADS) and Sonnet Lite (a free 2.5D Method of Moments EM solver). If possible, a free evaluation license will be acquired for ADS and HFSS in order to validate QUCS and Sonnet Lite as well as build skills. The fabrication stage will be done with KiCad and whichever fab-house works the best. Right now I am expecting to use JLCPCB, with FR4 substrate. A test coupon will also be made to de-embed connector launch effects. The testing stage will be done with a NanoVNA (VNA with LO up to 2GHz) and the VNA results will be compared with the simulation results.

Despite not *technically* being microwave frequency, this microwave structure still applies to S, X, Ku, etc. bands. I used this frequency because I only have a NanoVNA which can measure up to 2GHz. It was also chosen because GPS L2 operates at this carrier.

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

# Mock Scenario:
L-band signal from a wideband antenna is coming and it includes GPS data L1, L2, and L3, and there is a need to seperate out L2 (1227.6MHz) from L1 (1575.42MHz) and L5 (1176.45MHz). 

# ✅ Design Requirements 📖✏️

| Parameter                        | Value     | Units |
|----------------------------------|-----------|-------|
| Center Frequency, f<sub>0</sub>  | 1227.60   | MHz   |
| Passband bandwidth               | 20        | MHz   |
| Lower Cutoff Frequency, f<sub>low</sub>  | 1217.60   | MHz   |
| Upper Cutoff Frequency, f<sub>high</sub>  | 1237.60  | MHz   |
| Filter order                     | 5         |       |
| Filter type                      | Chebshyev |       |
| Passband ripple                  | 0.1       | dB    |
| Input/output impedance           | 50        | ohm   |
| Insertion loss target            | &ge;1     | dB    |
| Return loss target               | &le;20    | dB    |

## Reasoning for paramater choices
### Center Frequency
The center frequency was chosen because I have the equipment to test it. It was also chosen because there is a practical use to making a filter for this frequency. A filter at this frequency would be **useful in isolating the L2 GPS signal** coming from a wideband L-band antenna, **while seperating it from the L1 GPS component.**

### Bandwidth
The bandwidth was chosen on account of the GPS L2 bandwidth. The GPS L2 band is reported to have a bandwidth of 11MHz with a center frequency of 1227.6MHz. For this reason, a bandwidth of 20MHz was chosen in order to capture all of the data even if the filter was a bit "off center" by mistake.

### Filter order
The filter order was chosen to be 5 because I wanted the filter to be as selective as possible without using too much space. Since in an interdigital filter each digit equates to an additional order, and with each additional order the passband becomes more selective, I wanted as many digits as possible. However, this must be balanced with the fact that more digits means more board space and more cost (at least on something like Rogers substrate). In addition, with more digits and more space there is more risk of higher insertion loss within the passband. Therefore, 5 was chosen because it had

# Test Overview
- Warm up VNA
- Perform 2-port calibration (SOLT, TRL if possible)
- Verify with a known load
- Measure coupon thru line for de-embedding
- Measure S11, S21, group delay over 500 - 2000MHz
- Save touchstone files
- Results analysis
