# OpenEMS Layout Import and Simulation Tool

This MATLAB toolbox provides automatic import and simulation capabilities for RF/microwave layouts using OpenEMS. It can automatically detect and import layouts from QUCS-uSimmics, Sonnet, and KiCad formats, then perform full-wave electromagnetic simulation to extract S-parameters.

## Features

- **Multi-format support**: Automatically detects and imports QUCS (.sch), Sonnet (.son), and KiCad (.kicad_pcb) layouts
- **Automatic meshing**: Intelligent mesh generation based on geometry and frequency
- **Full-wave simulation**: Uses OpenEMS for accurate electromagnetic simulation  
- **S-parameter extraction**: Calculates and exports 2-port S-parameters
- **Comprehensive plotting**: Generates magnitude, phase, Smith chart, and performance plots
- **Touchstone export**: Saves results in standard .s2p format for other tools

## Installation

1. **Install OpenEMS**: Download and install OpenEMS from https://www.openems.de
2. **Add to MATLAB path**: Ensure OpenEMS MATLAB interface is in your MATLAB path
3. **Copy files**: Place this OpenEMS folder in your project directory

## Quick Start

```matlab
% Basic usage - automatic parameter detection
results = openems_import_simulate('layout_file.sch');

% Custom parameters
results = openems_import_simulate('layout_file.son', ...
                                 'freq_start', 1e9, ...
                                 'freq_stop', 1.5e9, ...
                                 'substrate_er', 4.3, ...
                                 'substrate_h', 1.6);
```

## File Structure

```
OpenEMS/
├── openems_import_simulate.m     % Main simulation function
├── parsers/                      % Layout format parsers
│   ├── parse_qucs_layout.m      % QUCS schematic parser
│   ├── parse_sonnet_layout.m    % Sonnet project parser
│   └── parse_kicad_layout.m     % KiCad PCB parser
├── utils/                        % Utility functions
│   ├── detect_layout_format.m   % Format detection
│   ├── setup_openems_simulation.m % OpenEMS setup
│   ├── write_touchstone.m       % Touchstone file writer
│   └── plot_sparameters.m       % Results plotting
├── examples/                     % Example scripts
│   └── run_example.m            % Usage demonstration
└── results/                      % Output directory
```

## Supported Layout Formats

### QUCS-uSimmics (.sch)
- Microstrip line components (MLIN)
- Microstrip stub components (MSTUB)  
- Port components (Pac)
- Substrate definitions (MSUB)

### Sonnet (.son)
- Metal polygons and traces
- Dielectric layer stack
- Simulation box definition
- Port definitions

### KiCad (.kicad_pcb)
- Copper traces and segments
- Via structures
- PCB stackup information
- Connector footprints (as ports)

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `freq_start` | 1e9 | Start frequency (Hz) |
| `freq_stop` | 1.5e9 | Stop frequency (Hz) |
| `freq_points` | 101 | Number of frequency points |
| `substrate_er` | 4.3 | Relative permittivity |
| `substrate_h` | 1.6 | Substrate height (mm) |
| `mesh_res` | 'auto' | Mesh resolution (mm or 'auto') |
| `output_dir` | './results' | Output directory |

## Output Structure

The simulation returns a results structure containing:

```matlab
results = struct(
    'frequency',   % Frequency vector [Hz]
    'S11',         % S11 parameters [complex]
    'S21',         % S21 parameters [complex] 
    'S12',         % S12 parameters [complex]
    'S22',         % S22 parameters [complex]
    'geometry',    % Parsed geometry information
    'mesh_info',   % Mesh generation details
    'format_type'  % Detected format ('qucs', 'sonnet', 'kicad')
);
```

## Examples

### Example 1: Basic Simulation
```matlab
% Simulate QUCS layout with default parameters
results = openems_import_simulate('filter.sch');
```

### Example 2: Custom Frequency Range
```matlab
% Simulate over GPS L-band frequencies
results = openems_import_simulate('filter.son', ...
                                 'freq_start', 1.2e9, ...
                                 'freq_stop', 1.3e9, ...
                                 'freq_points', 201);
```

### Example 3: Different Substrate
```matlab
% Use Rogers RO4003C substrate
results = openems_import_simulate('filter.kicad_pcb', ...
                                 'substrate_er', 3.38, ...
                                 'substrate_h', 0.508);
```

### Example 4: Custom Mesh Resolution
```matlab
% Use fine mesh for accuracy
results = openems_import_simulate('filter.sch', ...
                                 'mesh_res', 0.1);  % 0.1mm resolution
```

## Performance Tips

1. **Mesh Resolution**: Use 'auto' for initial runs, then refine with specific values
2. **Frequency Points**: Start with 101 points, increase for smoother curves
3. **Simulation Domain**: The tool automatically adds margins around geometry
4. **Memory Usage**: Fine meshes require significant RAM - monitor system resources

## Validation

The tool has been tested with:
- 1227MHz Interdigital Bandpass Filter layouts
- FR4 substrate (εr = 4.3, h = 1.6mm)
- Frequency range 1-1.5 GHz
- Various mesh resolutions from λ/10 to λ/30

## Troubleshooting

### Common Issues:

1. **"OpenEMS not found"**: Ensure OpenEMS is installed and in MATLAB path
2. **"Layout file not found"**: Check file path and permissions  
3. **"Memory error"**: Reduce mesh resolution or frequency points
4. **"Simulation failed"**: Check geometry bounds and port placement

### Debug Mode:
```matlab
% Enable verbose output
results = openems_import_simulate('filter.sch', 'debug', true);
```

## Contributing

To add support for new layout formats:

1. Create parser function in `parsers/` directory
2. Add format detection in `detect_layout_format.m`
3. Update main function `openems_import_simulate.m`
4. Add test cases and documentation

## References

- [OpenEMS Documentation](https://openems.de/start/index.html)
- [OpenEMS MATLAB Interface](https://github.com/thliebig/openEMS)
- [Touchstone Format Specification](https://www.vascop.de/touchstone_file_format.pdf)

## License

This tool is provided under the same license as the parent project (GPL v3).

---
*Generated for the 1227MHz Interdigital Bandpass Filter Project*