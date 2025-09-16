% Quick parser test
clear all; close all; clc;
addpath(genpath('.'));

% Test detection
fprintf('Testing format detection...\n');
files = {
    '../QUCS-uSimmics/Interdigital-Bandpass-1227.sch';
    '../Sonnet/1227MHz_Interdigital_Bandpass.son';
    '../KiCad/Interdigital-Bandpass-1227MHz/Interdigital-Bandpass-1227MHz.kicad_pcb'
};

for i = 1:length(files)
    if exist(files{i}, 'file')
        fmt = detect_layout_format(files{i});
        fprintf('%s: %s\n', files{i}, fmt);
    end
end

% Test QUCS parser
fprintf('\nTesting QUCS parser...\n');
try
    geom = parse_qucs_layout('../QUCS-uSimmics/Interdigital-Bandpass-1227.sch');
    fprintf('QUCS: %d conductors, %d ports, er=%.1f\n', ...
            length(geom.conductors), length(geom.ports), geom.substrate.er);
catch ME
    fprintf('QUCS error: %s\n', ME.message);
end

% Test Sonnet parser  
fprintf('\nTesting Sonnet parser...\n');
try
    geom = parse_sonnet_layout('../Sonnet/1227MHz_Interdigital_Bandpass.son');
    fprintf('Sonnet: %d conductors, %d ports, er=%.1f\n', ...
            length(geom.conductors), length(geom.ports), geom.substrate.er);
catch ME
    fprintf('Sonnet error: %s\n', ME.message);
end

fprintf('\nBasic tests complete!\n');