function geometry = parse_kicad_layout(kicad_file)
%PARSE_KICAD_LAYOUT Parse KiCad PCB file and extract geometry
%
%   geometry = parse_kicad_layout(kicad_file)
%
%   Parses a KiCad PCB file (.kicad_pcb) and extracts geometric information
%   including copper traces, vias, and substrate stackup.
%
%   Inputs:
%       kicad_file - Path to KiCad PCB file (.kicad_pcb)
%
%   Outputs:
%       geometry - Structure containing:
%           .conductors - Array of conductor structures
%           .substrate - Substrate properties
%           .ports - Port locations and properties
%           .bounds - Bounding box [xmin xmax ymin ymax]
%
%   Author: Generated for Interdigital Bandpass Filter Project

    if ~exist(kicad_file, 'file')
        error('KiCad file not found: %s', kicad_file);
    end
    
    fprintf('Parsing KiCad PCB: %s\n', kicad_file);
    
    % Initialize geometry structure
    geometry = struct();
    geometry.conductors = [];
    geometry.substrate = struct();
    geometry.ports = [];
    geometry.bounds = [inf -inf inf -inf]; % [xmin xmax ymin ymax]
    
    % Read the entire file (KiCad files are S-expressions)
    fid = fopen(kicad_file, 'r');
    if fid == -1
        error('Cannot open KiCad file: %s', kicad_file);
    end
    
    try
        % Read all content
        content = fread(fid, inf, 'char')';
        fclose(fid);
        content = char(content);
        
        % Parse S-expressions
        geometry = parse_kicad_content(content);
        
    catch ME
        if fid ~= -1
            fclose(fid);
        end
        rethrow(ME);
    end
    
    % Set default substrate properties if not found
    if isempty(fieldnames(geometry.substrate))
        fprintf('Warning: No substrate definition found, using FR4 defaults\n');
        geometry.substrate.er = 4.3;      % Relative permittivity
        geometry.substrate.h = 1.6;       % Height in mm
        geometry.substrate.t = 0.035;     % Copper thickness in mm
        geometry.substrate.tand = 0.02;   % Loss tangent
    end
    
    % Ensure valid bounds
    if any(isinf(geometry.bounds)) || geometry.bounds(1) >= geometry.bounds(2) || geometry.bounds(3) >= geometry.bounds(4)
        fprintf('Warning: Could not determine geometry bounds from KiCad, using defaults\n');
        geometry.bounds = [-10 10 -10 10]; % Default 20x20mm
    end
    
    fprintf('KiCad parsing complete:\n');
    fprintf('  - Conductors found: %d\n', length(geometry.conductors));
    fprintf('  - Ports found: %d\n', length(geometry.ports));
    fprintf('  - Bounds: [%.2f %.2f %.2f %.2f] mm\n', geometry.bounds);
end

function geometry = parse_kicad_content(content)
    % Parse KiCad S-expression content
    geometry = struct();
    geometry.conductors = [];
    geometry.substrate = struct();
    geometry.ports = [];
    geometry.bounds = [inf -inf inf -inf];
    
    conductor_count = 0;
    port_count = 0;
    
    % Split content into lines for processing
    lines = splitlines(content);
    
    % State variables
    in_stackup = false;
    current_layer = '';
    
    for i = 1:length(lines)
        line = strtrim(lines{i});
        
        if isempty(line)
            continue;
        end
        
        % Parse stackup information
        if ~isempty(strfind(line, '(stackup'))
            in_stackup = true;
            continue;
        elseif in_stackup && ~isempty(strfind(line, ')'))
            in_stackup = false;
            continue;
        end
        
        if in_stackup
            geometry.substrate = parse_kicad_stackup(line, geometry.substrate);
        end
        
        % Parse copper layers
        if ~isempty(strfind(line, '(layers'))
            % Parse layer definitions - not fully implemented
        end
        
        % Parse segments (traces)
        if ~isempty(strfind(line, '(segment'))
            conductor = parse_kicad_segment(line);
            if ~isempty(conductor)
                conductor_count = conductor_count + 1;
                conductor.id = conductor_count;
                geometry.conductors(end+1) = conductor;
                geometry.bounds = update_bounds_kicad(geometry.bounds, conductor);
            end
        end
        
        % Parse vias
        if ~isempty(strfind(line, '(via'))
            conductor = parse_kicad_via(line);
            if ~isempty(conductor)
                conductor_count = conductor_count + 1;
                conductor.id = conductor_count;
                geometry.conductors(end+1) = conductor;
                geometry.bounds = update_bounds_kicad(geometry.bounds, conductor);
            end
        end
        
        % Parse polygons/zones
        if ~isempty(strfind(line, '(polygon')) || ~isempty(strfind(line, '(zone'))
            conductor = parse_kicad_polygon(line, lines, i);
            if ~isempty(conductor)
                conductor_count = conductor_count + 1;
                conductor.id = conductor_count;
                geometry.conductors(end+1) = conductor;
                geometry.bounds = update_bounds_kicad(geometry.bounds, conductor);
            end
        end
        
        % Parse footprints (which may contain connectors/ports)
        if ~isempty(strfind(line, '(footprint')) && (~isempty(strfind(line, 'Connector')) || ~isempty(strfind(line, 'SMA')))
            port = parse_kicad_footprint_port(line, lines, i);
            if ~isempty(port)
                port_count = port_count + 1;
                port.id = port_count;
                geometry.ports(end+1) = port;
            end
        end
    end
end

function substrate = parse_kicad_stackup(line, substrate)
    % Parse stackup information
    if ~isempty(strfind(line, 'dielectric'))
        % Extract dielectric constant
        er_match = regexp(line, 'dielectric\s+([\d.]+)', 'tokens');
        if ~isempty(er_match)
            substrate.er = str2double(er_match{1}{1});
        end
    elseif ~isempty(strfind(line, 'thickness'))
        % Extract thickness
        thickness_match = regexp(line, 'thickness\s+([\d.]+)', 'tokens');
        if ~isempty(thickness_match)
            substrate.h = str2double(thickness_match{1}{1});
        end
    end
    
    % Set defaults if not specified
    if ~isfield(substrate, 'er') || isempty(substrate.er)
        substrate.er = 4.3;
    end
    if ~isfield(substrate, 'h') || isempty(substrate.h)
        substrate.h = 1.6;
    end
    if ~isfield(substrate, 't') || isempty(substrate.t)
        substrate.t = 0.035;
    end
    if ~isfield(substrate, 'tand') || isempty(substrate.tand)
        substrate.tand = 0.02;
    end
end

function conductor = parse_kicad_segment(line)
    % Parse segment (trace) from KiCad
    conductor = struct();
    
    % Extract coordinates and parameters
    % Example: (segment (start 100 50) (end 150 50) (width 0.25) (layer "F.Cu"))
    
    % Extract start coordinates
    start_match = regexp(line, '\(start\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\)', 'tokens');
    end_match = regexp(line, '\(end\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\)', 'tokens');
    width_match = regexp(line, '\(width\s+([-+]?\d*\.?\d+)\)', 'tokens');
    layer_match = regexp(line, '\(layer\s+"([^"]+)"\)', 'tokens');
    
    if ~isempty(start_match) && ~isempty(end_match) && ~isempty(width_match)
        conductor.type = 'trace';
        conductor.x1 = str2double(start_match{1}{1});
        conductor.y1 = str2double(start_match{1}{2});
        conductor.x2 = str2double(end_match{1}{1});
        conductor.y2 = str2double(end_match{1}{2});
        conductor.width = str2double(width_match{1}{1});
        
        if ~isempty(layer_match)
            conductor.layer = layer_match{1}{1};
        else
            conductor.layer = 'F.Cu';
        end
        
        % Calculate length
        conductor.length = sqrt((conductor.x2 - conductor.x1)^2 + (conductor.y2 - conductor.y1)^2);
        
        % Calculate center point
        conductor.x = (conductor.x1 + conductor.x2) / 2;
        conductor.y = (conductor.y1 + conductor.y2) / 2;
    else
        conductor = [];
    end
end

function conductor = parse_kicad_via(line)
    % Parse via from KiCad
    conductor = struct();
    
    % Extract via parameters
    % Example: (via (at 100 50) (size 0.8) (drill 0.4) (layers "F.Cu" "B.Cu"))
    
    at_match = regexp(line, '\(at\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\)', 'tokens');
    size_match = regexp(line, '\(size\s+([-+]?\d*\.?\d+)\)', 'tokens');
    
    if ~isempty(at_match) && ~isempty(size_match)
        conductor.type = 'via';
        conductor.x = str2double(at_match{1}{1});
        conductor.y = str2double(at_match{1}{2});
        conductor.diameter = str2double(size_match{1}{1});
        conductor.width = conductor.diameter; % For consistency
    else
        conductor = [];
    end
end

function conductor = parse_kicad_polygon(line, lines, start_idx)
    % Parse polygon/zone from KiCad (simplified)
    conductor = struct();
    conductor.type = 'polygon';
    conductor.vertices = [];
    
    % This is a simplified implementation
    % Full polygon parsing would require more sophisticated S-expression parsing
    conductor = [];
end

function port = parse_kicad_footprint_port(line, lines, start_idx)
    % Parse footprint that might be a port/connector
    port = struct();
    
    % Extract position
    at_match = regexp(line, '\(at\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)', 'tokens');
    
    if ~isempty(at_match)
        port.x = str2double(at_match{1}{1});
        port.y = str2double(at_match{1}{2});
        port.impedance = 50; % Default
        port.type = 'connector';
        
        % Extract footprint name for port numbering
        fp_match = regexp(line, '\(footprint\s+"([^"]+)"', 'tokens');
        if ~isempty(fp_match)
            port.name = fp_match{1}{1};
        else
            port.name = 'Port';
        end
    else
        port = [];
    end
end

function bounds = update_bounds_kicad(bounds, conductor)
    % Update bounding box with conductor geometry
    if isfield(conductor, 'x') && isfield(conductor, 'y')
        margin = 0;
        if isfield(conductor, 'width')
            margin = conductor.width / 2;
        elseif isfield(conductor, 'diameter')
            margin = conductor.diameter / 2;
        end
        
        bounds(1) = min(bounds(1), conductor.x - margin);
        bounds(2) = max(bounds(2), conductor.x + margin);
        bounds(3) = min(bounds(3), conductor.y - margin);
        bounds(4) = max(bounds(4), conductor.y + margin);
        
        % Handle traces with start/end points
        if isfield(conductor, 'x1') && isfield(conductor, 'x2')
            bounds(1) = min(bounds(1), min(conductor.x1, conductor.x2) - margin);
            bounds(2) = max(bounds(2), max(conductor.x1, conductor.x2) + margin);
            bounds(3) = min(bounds(3), min(conductor.y1, conductor.y2) - margin);
            bounds(4) = max(bounds(4), max(conductor.y1, conductor.y2) + margin);
        end
    end
end