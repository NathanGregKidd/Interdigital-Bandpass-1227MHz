% Simple QUCS parser test
clear all; close all; clc;

% Add path
addpath(genpath('.'));

% Test the QUCS parser directly
qucs_file = '../QUCS-uSimmics/Interdigital-Bandpass-1227.sch';

if exist(qucs_file, 'file')
    fprintf('Testing QUCS parser with file: %s\n', qucs_file);
    
    try
        geometry = parse_qucs_layout(qucs_file);
        
        fprintf('\nResults:\n');
        fprintf('- Conductors found: %d\n', length(geometry.conductors));
        fprintf('- Ports found: %d\n', length(geometry.ports));
        fprintf('- Substrate εr: %.2f, h: %.2f mm\n', geometry.substrate.er, geometry.substrate.h);
        fprintf('- Geometry bounds: [%.1f %.1f %.1f %.1f] mm\n', geometry.bounds);
        
        if ~isempty(geometry.conductors)
            fprintf('\nFirst few conductors:\n');
            for i = 1:min(5, length(geometry.conductors))
                c = geometry.conductors(i);
                fprintf('  %d: %s, type=%s, pos=(%.1f,%.1f), size=%.2fx%.2f mm\n', ...
                        i, c.name, c.type, c.x, c.y, c.width, c.length);
            end
        end
        
        if ~isempty(geometry.ports)
            fprintf('\nPorts:\n');
            for i = 1:length(geometry.ports)
                p = geometry.ports(i);
                fprintf('  %s: pos=(%.1f,%.1f), Z=%.1f Ω\n', p.name, p.x, p.y, p.impedance);
            end
        end
        
    catch ME
        fprintf('Error: %s\n', ME.message);
        for i = 1:length(ME.stack)
            fprintf('  at %s:%d in %s\n', ME.stack(i).file, ME.stack(i).line, ME.stack(i).name);
        end
    end
else
    fprintf('QUCS file not found: %s\n', qucs_file);
end