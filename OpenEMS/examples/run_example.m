%% OpenEMS Layout Import Example
% Demonstrates usage of the OpenEMS import and simulation tool
% for the 1227MHz Interdigital Bandpass Filter

clear all; close all; clc;

%% Add OpenEMS and utility paths
addpath(genpath('.')); % Add current directory and subdirectories to path

% Note: Ensure OpenEMS is installed and in your MATLAB path
% OpenEMS can be downloaded from: https://www.openems.de

%% Define simulation parameters
params = struct();
params.freq_start = 1e9;      % 1 GHz
params.freq_stop = 1.5e9;     % 1.5 GHz  
params.freq_points = 101;     % Number of frequency points
params.substrate_er = 4.3;    % FR4 relative permittivity
params.substrate_h = 1.6;     % Substrate height in mm
params.mesh_res = 'auto';     % Automatic mesh resolution
params.output_dir = './results'; % Output directory

%% Example 1: Import and simulate QUCS layout
fprintf('=== Example 1: QUCS Layout ===\n');
qucs_file = '../QUCS-uSimmics/Interdigital-Bandpass-1227.sch';

if exist(qucs_file, 'file')
    try
        results_qucs = openems_import_simulate(qucs_file, ...
                                              'freq_start', params.freq_start, ...
                                              'freq_stop', params.freq_stop, ...
                                              'freq_points', params.freq_points, ...
                                              'substrate_er', params.substrate_er, ...
                                              'substrate_h', params.substrate_h, ...
                                              'output_dir', fullfile(params.output_dir, 'qucs'));
        
        fprintf('QUCS simulation completed successfully!\n\n');
    catch ME
        fprintf('QUCS simulation failed: %s\n\n', ME.message);
    end
else
    fprintf('QUCS file not found: %s\n\n', qucs_file);
end

%% Example 2: Import and simulate Sonnet layout
fprintf('=== Example 2: Sonnet Layout ===\n');
sonnet_file = '../Sonnet/1227MHz_Interdigital_Bandpass.son';

if exist(sonnet_file, 'file')
    try
        results_sonnet = openems_import_simulate(sonnet_file, ...
                                                'freq_start', params.freq_start, ...
                                                'freq_stop', params.freq_stop, ...
                                                'freq_points', params.freq_points, ...
                                                'substrate_er', params.substrate_er, ...
                                                'substrate_h', params.substrate_h, ...
                                                'output_dir', fullfile(params.output_dir, 'sonnet'));
        
        fprintf('Sonnet simulation completed successfully!\n\n');
    catch ME
        fprintf('Sonnet simulation failed: %s\n\n', ME.message);
    end
else
    fprintf('Sonnet file not found: %s\n\n', sonnet_file);
end

%% Example 3: Import and simulate KiCad layout
fprintf('=== Example 3: KiCad Layout ===\n');
kicad_file = '../KiCad/Interdigital-Bandpass-1227MHz/Interdigital-Bandpass-1227MHz.kicad_pcb';

if exist(kicad_file, 'file')
    try
        results_kicad = openems_import_simulate(kicad_file, ...
                                               'freq_start', params.freq_start, ...
                                               'freq_stop', params.freq_stop, ...
                                               'freq_points', params.freq_points, ...
                                               'substrate_er', params.substrate_er, ...
                                               'substrate_h', params.substrate_h, ...
                                               'output_dir', fullfile(params.output_dir, 'kicad'));
        
        fprintf('KiCad simulation completed successfully!\n\n');
    catch ME
        fprintf('KiCad simulation failed: %s\n\n', ME.message);
    end
else
    fprintf('KiCad file not found: %s\n\n', kicad_file);
end

%% Compare results if multiple simulations were successful
fprintf('=== Results Comparison ===\n');

available_results = {};
if exist('results_qucs', 'var')
    available_results{end+1} = 'QUCS';
end
if exist('results_sonnet', 'var')
    available_results{end+1} = 'Sonnet';
end
if exist('results_kicad', 'var')
    available_results{end+1} = 'KiCad';
end

if length(available_results) > 1
    figure('Position', [100, 100, 1200, 600]);
    
    % Plot S21 comparison
    subplot(1, 2, 1);
    hold on;
    colors = {'b', 'r', 'g'};
    
    for i = 1:length(available_results)
        switch available_results{i}
            case 'QUCS'
                freq = results_qucs.frequency / 1e9;
                s21_db = 20*log10(abs(results_qucs.S21));
            case 'Sonnet'
                freq = results_sonnet.frequency / 1e9;
                s21_db = 20*log10(abs(results_sonnet.S21));
            case 'KiCad'
                freq = results_kicad.frequency / 1e9;
                s21_db = 20*log10(abs(results_kicad.S21));
        end
        
        plot(freq, s21_db, colors{i}, 'LineWidth', 2, 'DisplayName', available_results{i});
    end
    
    grid on;
    xlabel('Frequency (GHz)');
    ylabel('|S21| (dB)');
    title('S21 Comparison - Different Layout Formats');
    legend('show');
    
    % Plot S11 comparison
    subplot(1, 2, 2);
    hold on;
    
    for i = 1:length(available_results)
        switch available_results{i}
            case 'QUCS'
                freq = results_qucs.frequency / 1e9;
                s11_db = 20*log10(abs(results_qucs.S11));
            case 'Sonnet'
                freq = results_sonnet.frequency / 1e9;
                s11_db = 20*log10(abs(results_sonnet.S11));
            case 'KiCad'
                freq = results_kicad.frequency / 1e9;
                s11_db = 20*log10(abs(results_kicad.S11));
        end
        
        plot(freq, s11_db, colors{i}, 'LineWidth', 2, 'DisplayName', available_results{i});
    end
    
    grid on;
    xlabel('Frequency (GHz)');
    ylabel('|S11| (dB)');
    title('S11 Comparison - Different Layout Formats');
    legend('show');
    
    sgtitle('OpenEMS Layout Format Comparison', 'FontSize', 14, 'FontWeight', 'bold');
    
    fprintf('Comparison plot created for %d layout formats\n', length(available_results));
else
    fprintf('Only %d layout format available for comparison\n', length(available_results));
end

%% Performance metrics
fprintf('\n=== Performance Summary ===\n');

% Calculate metrics for each available result
for i = 1:length(available_results)
    fprintf('\n%s Layout Results:\n', available_results{i});
    
    switch available_results{i}
        case 'QUCS'
            results = results_qucs;
        case 'Sonnet'
            results = results_sonnet;
        case 'KiCad'
            results = results_kicad;
    end
    
    % Find center frequency response
    center_idx = round(length(results.frequency)/2);
    
    fprintf('  Geometry: %d conductors, %.1f x %.1f mm\n', ...
            length(results.geometry.conductors), ...
            results.geometry.bounds(2) - results.geometry.bounds(1), ...
            results.geometry.bounds(4) - results.geometry.bounds(3));
    
    fprintf('  |S11| at 1.227 GHz: %.2f dB\n', 20*log10(abs(results.S11(center_idx))));
    fprintf('  |S21| at 1.227 GHz: %.2f dB\n', 20*log10(abs(results.S21(center_idx))));
    
    % Find minimum S11 (best return loss)
    [min_s11_db, min_idx] = min(20*log10(abs(results.S11)));
    fprintf('  Best return loss: %.2f dB at %.3f GHz\n', ...
            min_s11_db, results.frequency(min_idx)/1e9);
    
    % Find maximum S21 (best insertion loss)
    [max_s21_db, max_idx] = max(20*log10(abs(results.S21)));
    fprintf('  Best insertion loss: %.2f dB at %.3f GHz\n', ...
            max_s21_db, results.frequency(max_idx)/1e9);
    
    fprintf('  Mesh cells: %d\n', results.mesh_info.info.cells_total);
end

fprintf('\nExample script completed!\n');
fprintf('Results saved in: %s\n', params.output_dir);

%% Cleanup
% Note: Simulation files (*.xml, field dumps, etc.) are left in current directory
% You may want to move them to results folder for organization