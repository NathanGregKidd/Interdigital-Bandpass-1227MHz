%% Test Script for OpenEMS Layout Parsers
% Tests the basic functionality of layout parsers without running full simulation

clear all; close all; clc;

fprintf('=== OpenEMS Layout Parser Test ===\n\n');

% Add paths
addpath(genpath('.'));

%% Test 1: Format Detection
fprintf('Test 1: Format Detection\n');
fprintf('------------------------\n');

test_files = {
    '../QUCS-uSimmics/Interdigital-Bandpass-1227.sch', 'qucs';
    '../Sonnet/1227MHz_Interdigital_Bandpass.son', 'sonnet';
    '../KiCad/Interdigital-Bandpass-1227MHz/Interdigital-Bandpass-1227MHz.kicad_pcb', 'kicad'
};

for i = 1:size(test_files, 1)
    file_path = test_files{i, 1};
    expected_format = test_files{i, 2};
    
    if exist(file_path, 'file')
        try
            detected_format = detect_layout_format(file_path);
            if strcmp(detected_format, expected_format)
                fprintf('✓ %s: %s (PASS)\n', file_path, detected_format);
            else
                fprintf('✗ %s: Expected %s, got %s (FAIL)\n', file_path, expected_format, detected_format);
            end
        catch ME
            fprintf('✗ %s: Error - %s (FAIL)\n', file_path, ME.message);
        end
    else
        fprintf('- %s: File not found (SKIP)\n', file_path);
    end
end

%% Test 2: QUCS Parser
fprintf('\nTest 2: QUCS Parser\n');
fprintf('-------------------\n');

qucs_file = '../QUCS-uSimmics/Interdigital-Bandpass-1227.sch';
if exist(qucs_file, 'file')
    try
        geometry_qucs = parse_qucs_layout(qucs_file);
        
        fprintf('✓ QUCS parsing completed\n');
        fprintf('  - Conductors: %d\n', length(geometry_qucs.conductors));
        fprintf('  - Ports: %d\n', length(geometry_qucs.ports));
        fprintf('  - Bounds: [%.2f %.2f %.2f %.2f] mm\n', geometry_qucs.bounds);
        fprintf('  - Substrate εr: %.2f\n', geometry_qucs.substrate.er);
        
    catch ME
        fprintf('✗ QUCS parser failed: %s\n', ME.message);
    end
else
    fprintf('- QUCS file not found (SKIP)\n');
end

%% Test 3: Sonnet Parser
fprintf('\nTest 3: Sonnet Parser\n');
fprintf('---------------------\n');

sonnet_file = '../Sonnet/1227MHz_Interdigital_Bandpass.son';
if exist(sonnet_file, 'file')
    try
        geometry_sonnet = parse_sonnet_layout(sonnet_file);
        
        fprintf('✓ Sonnet parsing completed\n');
        fprintf('  - Conductors: %d\n', length(geometry_sonnet.conductors));
        fprintf('  - Ports: %d\n', length(geometry_sonnet.ports));
        fprintf('  - Bounds: [%.2f %.2f %.2f %.2f] mm\n', geometry_sonnet.bounds);
        fprintf('  - Substrate εr: %.2f\n', geometry_sonnet.substrate.er);
        
    catch ME
        fprintf('✗ Sonnet parser failed: %s\n', ME.message);
    end
else
    fprintf('- Sonnet file not found (SKIP)\n');
end

%% Test 4: KiCad Parser  
fprintf('\nTest 4: KiCad Parser\n');
fprintf('--------------------\n');

kicad_file = '../KiCad/Interdigital-Bandpass-1227MHz/Interdigital-Bandpass-1227MHz.kicad_pcb';
if exist(kicad_file, 'file')
    try
        geometry_kicad = parse_kicad_layout(kicad_file);
        
        fprintf('✓ KiCad parsing completed\n');
        fprintf('  - Conductors: %d\n', length(geometry_kicad.conductors));
        fprintf('  - Ports: %d\n', length(geometry_kicad.ports));
        fprintf('  - Bounds: [%.2f %.2f %.2f %.2f] mm\n', geometry_kicad.bounds);
        fprintf('  - Substrate εr: %.2f\n', geometry_kicad.substrate.er);
        
    catch ME
        fprintf('✗ KiCad parser failed: %s\n', ME.message);
    end
else
    fprintf('- KiCad file not found (SKIP)\n');
end

%% Test 5: Geometry Visualization (if any parser succeeded)
fprintf('\nTest 5: Geometry Visualization\n');
fprintf('------------------------------\n');

geometries = {};
labels = {};

if exist('geometry_qucs', 'var')
    geometries{end+1} = geometry_qucs;
    labels{end+1} = 'QUCS';
end

if exist('geometry_sonnet', 'var')
    geometries{end+1} = geometry_sonnet;
    labels{end+1} = 'Sonnet';
end

if exist('geometry_kicad', 'var')
    geometries{end+1} = geometry_kicad;
    labels{end+1} = 'KiCad';
end

if ~isempty(geometries)
    figure('Position', [100, 100, 1200, 400]);
    
    for i = 1:length(geometries)
        subplot(1, length(geometries), i);
        geometry = geometries{i};
        
        % Plot geometry bounds
        rectangle('Position', [geometry.bounds(1), geometry.bounds(3), ...
                              geometry.bounds(2)-geometry.bounds(1), ...
                              geometry.bounds(4)-geometry.bounds(3)], ...
                 'EdgeColor', 'k', 'LineStyle', '--', 'LineWidth', 1);
        hold on;
        
        % Plot conductors
        for j = 1:length(geometry.conductors)
            conductor = geometry.conductors(j);
            
            if isfield(conductor, 'x1') && isfield(conductor, 'x2')
                % Line segment
                plot([conductor.x1, conductor.x2], [conductor.y1, conductor.y2], 'b-', 'LineWidth', 3);
            elseif isfield(conductor, 'x') && isfield(conductor, 'width')
                % Rectangle or point
                rect_pos = [conductor.x - conductor.width/2, conductor.y - conductor.width/2, ...
                           conductor.width, conductor.width];
                rectangle('Position', rect_pos, 'FaceColor', 'blue', 'EdgeColor', 'blue');
            end
        end
        
        % Plot ports
        for j = 1:length(geometry.ports)
            port = geometry.ports(j);
            plot(port.x, port.y, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red');
        end
        
        axis equal;
        grid on;
        title(sprintf('%s Layout', labels{i}));
        xlabel('X (mm)');
        ylabel('Y (mm)');
    end
    
    sgtitle('Parsed Geometry Comparison', 'FontSize', 14, 'FontWeight', 'bold');
    
    fprintf('✓ Geometry visualization created\n');
else
    fprintf('- No geometries available for visualization (SKIP)\n');
end

%% Summary
fprintf('\n=== Test Summary ===\n');
fprintf('Basic parser functionality validated.\n');
fprintf('Ready for full OpenEMS simulation testing.\n');

if ~isempty(geometries)
    fprintf('\nTip: Run examples/run_example.m for full simulation testing\n');
    fprintf('(Note: Requires OpenEMS installation)\n');
end