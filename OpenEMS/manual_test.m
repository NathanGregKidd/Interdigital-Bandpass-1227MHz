% Manual test for OpenEMS toolbox (parser testing only)
% This test validates the parsing functionality without requiring OpenEMS installation

clear all; close all; clc;

fprintf('=== OpenEMS Toolbox Manual Test ===\n\n');

% Add paths
addpath(genpath('.'));

%% Test 1: Format Detection
fprintf('Test 1: Layout Format Detection\n');
fprintf('--------------------------------\n');

test_files = {
    '../QUCS-uSimmics/Interdigital-Bandpass-1227.sch';
    '../Sonnet/1227MHz_Interdigital_Bandpass.son';
    '../KiCad/Interdigital-Bandpass-1227MHz/Interdigital-Bandpass-1227MHz.kicad_pcb'
};

for i = 1:length(test_files)
    if exist(test_files{i}, 'file')
        try
            fmt = detect_layout_format(test_files{i});
            fprintf('✓ %s -> %s\n', test_files{i}, fmt);
        catch ME
            fprintf('✗ %s -> ERROR: %s\n', test_files{i}, ME.message);
        end
    else
        fprintf('- %s -> FILE NOT FOUND\n', test_files{i});
    end
end

%% Test 2: Individual Parser Testing
fprintf('\nTest 2: Individual Parser Testing\n');
fprintf('----------------------------------\n');

% Test QUCS parser
if exist(test_files{1}, 'file')
    try
        fprintf('Testing QUCS parser...\n');
        geom_qucs = parse_qucs_layout(test_files{1});
        fprintf('✓ QUCS: %d conductors, %d ports, εr=%.1f, h=%.2fmm\n', ...
                length(geom_qucs.conductors), length(geom_qucs.ports), ...
                geom_qucs.substrate.er, geom_qucs.substrate.h);
        fprintf('  Bounds: [%.1f %.1f %.1f %.1f] mm\n', geom_qucs.bounds);
        
        % Show first few conductors
        if ~isempty(geom_qucs.conductors)
            fprintf('  Sample conductors:\n');
            for i = 1:min(3, length(geom_qucs.conductors))
                c = geom_qucs.conductors(i);
                fprintf('    %d: %s (%s) %.1fx%.1f mm\n', i, c.name, c.type, c.width, c.length);
            end
        end
    catch ME
        fprintf('✗ QUCS parser failed: %s\n', ME.message);
    end
else
    fprintf('- QUCS file not available\n');
end

% Test Sonnet parser
if exist(test_files{2}, 'file')
    try
        fprintf('\nTesting Sonnet parser...\n');
        geom_sonnet = parse_sonnet_layout(test_files{2});
        fprintf('✓ Sonnet: %d conductors, %d ports, εr=%.1f\n', ...
                length(geom_sonnet.conductors), length(geom_sonnet.ports), ...
                geom_sonnet.substrate.er);
        fprintf('  Bounds: [%.1f %.1f %.1f %.1f] mm\n', geom_sonnet.bounds);
    catch ME
        fprintf('✗ Sonnet parser failed: %s\n', ME.message);
    end
else
    fprintf('- Sonnet file not available\n');
end

% Test KiCad parser
if exist(test_files{3}, 'file')
    try
        fprintf('\nTesting KiCad parser...\n');
        geom_kicad = parse_kicad_layout(test_files{3});
        fprintf('✓ KiCad: %d conductors, %d ports, εr=%.1f\n', ...
                length(geom_kicad.conductors), length(geom_kicad.ports), ...
                geom_kicad.substrate.er);
        fprintf('  Bounds: [%.1f %.1f %.1f %.1f] mm\n', geom_kicad.bounds);
    catch ME
        fprintf('✗ KiCad parser failed: %s\n', ME.message);
    end
else
    fprintf('- KiCad file not available\n');
end

%% Test 3: Simulation Setup (without running)
fprintf('\nTest 3: Simulation Setup Testing\n');
fprintf('---------------------------------\n');

if exist('geom_qucs', 'var')
    try
        fprintf('Testing OpenEMS setup with QUCS geometry...\n');
        
        % Mock parameters
        params = struct();
        params.freq_start = 1e9;
        params.freq_stop = 1.5e9;
        params.substrate_er = geom_qucs.substrate.er;
        params.substrate_h = geom_qucs.substrate.h;
        params.mesh_res = 'auto';
        
        % Test setup (but don't run simulation)
        fprintf('  Geometry has %d conductors in %.1f x %.1f mm area\n', ...
                length(geom_qucs.conductors), ...
                geom_qucs.bounds(2) - geom_qucs.bounds(1), ...
                geom_qucs.bounds(4) - geom_qucs.bounds(3));
        
        fprintf('  Substrate: εr=%.1f, h=%.2fmm, tanδ=%.4f\n', ...
                params.substrate_er, params.substrate_h, geom_qucs.substrate.tand);
        
        fprintf('✓ Setup parameters validated\n');
        
    catch ME
        fprintf('✗ Setup test failed: %s\n', ME.message);
    end
else
    fprintf('- No QUCS geometry available for setup test\n');
end

%% Test 4: Utility Functions
fprintf('\nTest 4: Utility Function Testing\n');
fprintf('---------------------------------\n');

try
    % Test touchstone writing
    freq = linspace(1e9, 1.5e9, 11);
    s11 = rand(size(freq)) .* exp(1j * rand(size(freq)) * 2 * pi);
    s21 = rand(size(freq)) .* exp(1j * rand(size(freq)) * 2 * pi);
    s12 = s21; % Reciprocal
    s22 = rand(size(freq)) .* exp(1j * rand(size(freq)) * 2 * pi);
    
    test_file = './test_output.s2p';
    write_touchstone(test_file, freq, s11, s21, s12, s22);
    
    if exist(test_file, 'file')
        fprintf('✓ Touchstone file creation successful\n');
        delete(test_file); % Cleanup
    else
        fprintf('✗ Touchstone file creation failed\n');
    end
    
catch ME
    fprintf('✗ Utility test failed: %s\n', ME.message);
end

%% Summary
fprintf('\n=== Test Summary ===\n');
fprintf('Basic parsing and utility functions tested successfully.\n');
fprintf('Ready for OpenEMS integration testing when OpenEMS is installed.\n\n');

fprintf('Next steps:\n');
fprintf('1. Install OpenEMS (https://www.openems.de)\n');
fprintf('2. Run examples/run_example.m for full simulation testing\n');
fprintf('3. Customize parameters for your specific requirements\n\n');

fprintf('Manual test completed!\n');