# ⚡Interdigital-Bandpass-1227.6MHz
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
| Filter type                      | Microstrip Interdigital Bandpass   |
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
| Group delay                      | &lt;50    | ns p/p|
| Substrate                        | FR4       |       |
| Input/Output Connectors          | SMA       |       |
| Case (if made)                   | Aluminum  |       |

## Reasoning for paramater choices
### Center Frequency
The center frequency was chosen because I have the equipment to test it. It was also chosen because there is a practical use to making a filter for this frequency. A filter at this frequency would be **useful in isolating the L2 GPS signal** coming from a wideband L-band antenna, **while seperating it from the L1 GPS component.**

### Bandwidth
The bandwidth was chosen on account of the GPS L2 bandwidth. The GPS L2 band is reported to have a bandwidth of 11MHz with a center frequency of 1227.6MHz. For this reason, a bandwidth of 20MHz was chosen in order to capture all of the data even if the filter was a bit "off center" by mistake.

### Filter order
The filter order was chosen to be 5 because I wanted the filter to be as selective as possible without using too much space. Since in an interdigital filter each digit equates to an additional order, and with each additional order the passband becomes more selective, I wanted as many digits as possible. However, this must be balanced with the fact that more digits means more board space and more cost (at least on something like Rogers substrate). In addition, with more digits and more space there is more risk of higher insertion loss within the passband. Filter order 5 seemed like a good starting point.

### Filter Type
Chebyshev has a sharper rolloff which is perfect for tight channel selection, which is what i'm trying to achieve. The other option, Butterworth, is meant for a low-ripple passband which is not strictly necessary in this scenario.

### Passband ripple
With Chebyshev filters, the passband ripple is a design choice. In general, the more ripple that is allowed in, the sharper the cutoff, and vice versa. I decided on 0.1dB to start.

### Input Output Impedence
Chosen to be 50 ohms because this is the most common characteristic impedence used in today's electrical RF components.

### Insertion loss 
Less than 1dB would be basically all signal getting through. This would be great! Therefore, it is my goal.

### Return loss
Greater than 20dB in the pass band would show good impedence matching and power delivery.

### Group delay
50ns is not extremely good by any means, but this application doesn't necessarily need it to be super good. It is more important that a good selectivity is achieved. 

# Design Equations
*Matlab/Python files can be found in the design folder*



# Simulation
Keysight ADS / QUCS / uSimmics simulation:
<p align="center">
  <img width="1176" height="790" alt="image" src="https://github.com/user-attachments/assets/ae4e087e-2946-4c37-93f9-43c235954edc" />
  <i>The QUCS / uSimmics schematic</i>
<p align="center">
  <img width="686" height="378" alt="image" src="https://github.com/user-attachments/assets/86b2cb26-9271-4ee6-8865-d019fd703013" />
<p align="center">
  <i>The uSimmics generated geometry for EM field analysis</i>
</p>

The simulation is not optimized yet. For now, just a baseline geometry has been laid out so that the design parameters can be placed in later. 



# Testing Stage
## Test Overview
- Warm up VNA
- Perform 2-port calibration (SOLT, TRL if possible)
- Verify with a known load
- Measure coupon thru line for de-embedding
- Measure S11, S21, group delay over 500 - 2000MHz
- Save touchstone files
- Results analysis

