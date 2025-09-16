function results = openems_import_simulate(layout_file, varargin)
%OPENEMS_IMPORT_SIMULATE Import layout and run OpenEMS simulation
%
%   results = openems_import_simulate(layout_file)
%   results = openems_import_simulate(layout_file, 'Parameter', value, ...)
%
%   This function automatically detects the layout format (QUCS, Sonnet, or KiCad),
%   imports the geometry, creates an appropriate mesh, and runs OpenEMS simulation
%   to extract S-parameters.
%
%   Inputs:
%       layout_file - Path to layout file (.sch, .son, or .kicad_pcb)
%
%   Optional Parameters:
%       'freq_start' - Start frequency in Hz (default: 1e9)
%       'freq_stop'  - Stop frequency in Hz (default: 1.5e9)
%       'freq_points' - Number of frequency points (default: 101)
%       'mesh_res'   - Mesh resolution factor (default: auto)
%       'output_dir' - Output directory (default: './results')
%       'substrate_er' - Relative permittivity (default: 4.3 for FR4)
%       'substrate_h'  - Substrate height in mm (default: 1.6)
%
%   Outputs:
%       results - Structure containing:
%           .frequency - Frequency vector
%           .S11 - S11 parameters
%           .S21 - S21 parameters
%           .S12 - S12 parameters  
%           .S22 - S22 parameters
%           .geometry - Extracted geometry information
%           .mesh_info - Mesh information
%
%   Author: Generated for Interdigital Bandpass Filter Project
%   Date: 2025

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'layout_file', @ischar);
    addParameter(p, 'freq_start', 1e9, @isnumeric);
    addParameter(p, 'freq_stop', 1.5e9, @isnumeric);
    addParameter(p, 'freq_points', 101, @isnumeric);
    addParameter(p, 'mesh_res', 'auto', @(x) isnumeric(x) || strcmp(x, 'auto'));
    addParameter(p, 'output_dir', './results', @ischar);
    addParameter(p, 'substrate_er', 4.3, @isnumeric);
    addParameter(p, 'substrate_h', 1.6, @isnumeric);
    parse(p, layout_file, varargin{:});
    
    params = p.Results;
    
    % Check if file exists
    if ~exist(layout_file, 'file')
        error('Layout file not found: %s', layout_file);
    end
    
    fprintf('OpenEMS Import and Simulation Tool\n');
    fprintf('==================================\n');
    fprintf('Layout file: %s\n', layout_file);
    
    % Step 1: Detect layout format
    format_type = detect_layout_format(layout_file);
    fprintf('Detected format: %s\n', format_type);
    
    % Step 2: Parse layout and extract geometry
    switch format_type
        case 'qucs'
            geometry = parse_qucs_layout(layout_file);
        case 'sonnet'
            geometry = parse_sonnet_layout(layout_file);
        case 'kicad'
            geometry = parse_kicad_layout(layout_file);
        otherwise
            error('Unsupported layout format: %s', format_type);
    end
    
    fprintf('Geometry extracted: %d conductors found\n', length(geometry.conductors));
    
    % Step 3: Setup OpenEMS simulation
    [CSX, port, mesh] = setup_openems_simulation(geometry, params);
    fprintf('OpenEMS setup complete\n');
    
    % Step 4: Run simulation
    fprintf('Running OpenEMS simulation...\n');
    RunOpenEMS('.', 'simulation', '--numThreads=4');
    
    % Step 5: Extract S-parameters
    freq = linspace(params.freq_start, params.freq_stop, params.freq_points);
    
    % Calculate port voltages and currents
    port = calcPort(port, mesh, freq);
    
    % Extract S-parameters
    s11 = port{1}.uf.ref ./ port{1}.uf.inc;
    s21 = port{2}.uf.ref ./ port{1}.uf.inc;
    s12 = port{1}.uf.ref ./ port{2}.uf.inc;
    s22 = port{2}.uf.ref ./ port{2}.uf.inc;
    
    % Package results
    results.frequency = freq;
    results.S11 = s11;
    results.S21 = s21;
    results.S12 = s12;
    results.S22 = s22;
    results.geometry = geometry;
    results.mesh_info = mesh;
    results.format_type = format_type;
    
    % Save results
    if ~exist(params.output_dir, 'dir')
        mkdir(params.output_dir);
    end
    
    [~, name, ~] = fileparts(layout_file);
    results_file = fullfile(params.output_dir, sprintf('%s_results.mat', name));
    save(results_file, 'results');
    
    % Save S-parameters in Touchstone format
    touchstone_file = fullfile(params.output_dir, sprintf('%s.s2p', name));
    write_touchstone(touchstone_file, freq, s11, s21, s12, s22);
    
    fprintf('Simulation complete!\n');
    fprintf('Results saved to: %s\n', results_file);
    fprintf('S-parameters saved to: %s\n', touchstone_file);
    
    % Plot results
    plot_sparameters(results);
end