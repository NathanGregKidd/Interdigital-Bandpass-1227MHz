function geometry = parse_qucs_layout(qucs_file)
%PARSE_QUCS_LAYOUT Parse QUCS schematic file and extract geometry
%
%   geometry = parse_qucs_layout(qucs_file)
%
%   Parses a QUCS schematic file (.sch) and extracts geometric information
%   for microstrip structures, including conductor traces and substrate.
%
%   Inputs:
%       qucs_file - Path to QUCS schematic file (.sch)
%
%   Outputs:
%       geometry - Structure containing:
%           .conductors - Array of conductor structures
%           .substrate - Substrate properties
%           .ports - Port locations and properties
%           .bounds - Bounding box [xmin xmax ymin ymax]
%
%   Author: Generated for Interdigital Bandpass Filter Project

    if ~exist(qucs_file, 'file')
        error('QUCS file not found: %s', qucs_file);
    end
    
    fprintf('Parsing QUCS schematic: %s\n', qucs_file);
    
    % Initialize geometry structure
    geometry = struct();
    geometry.conductors = [];
    geometry.substrate = struct();
    geometry.ports = [];
    geometry.bounds = [inf -inf inf -inf]; % [xmin xmax ymin ymax]
    
    % Read the file
    fid = fopen(qucs_file, 'r');
    if fid == -1
        error('Cannot open QUCS file: %s', qucs_file);
    end
    
    try
        % Parse file line by line
        line_num = 0;
        conductor_count = 0;
        port_count = 0;
        
        while ~feof(fid)
            line = fgetl(fid);
            line_num = line_num + 1;
            
            if ~ischar(line)
                break;
            end
            
            % Remove leading/trailing whitespace
            line = strtrim(line);
            
            % Skip empty lines and comments
            if isempty(line) || line(1) == '%'
                continue;
            end
            
            % Parse microstrip lines (MLIN components)
            if contains(line, 'MLIN')
                conductor = parse_qucs_mlin(line);
                if ~isempty(conductor)
                    conductor_count = conductor_count + 1;
                    conductor.id = conductor_count;
                    geometry.conductors(end+1) = conductor;
                    
                    % Update bounding box
                    geometry.bounds = update_bounds(geometry.bounds, conductor);
                end
                
            % Parse microstrip stubs (MSTUB components)
            elseif contains(line, 'MSTUB')
                conductor = parse_qucs_mstub(line);
                if ~isempty(conductor)
                    conductor_count = conductor_count + 1;
                    conductor.id = conductor_count;
                    geometry.conductors(end+1) = conductor;
                    
                    % Update bounding box
                    geometry.bounds = update_bounds(geometry.bounds, conductor);
                end
                
            % Parse ports (Pac components)
            elseif contains(line, 'Pac')
                port = parse_qucs_port(line);
                if ~isempty(port)
                    port_count = port_count + 1;
                    port.id = port_count;
                    geometry.ports(end+1) = port;
                end
                
            % Parse substrate properties (MSUB components)
            elseif contains(line, 'MSUB')
                geometry.substrate = parse_qucs_msub(line);
            end
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
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
    if any(isinf(geometry.bounds))
        fprintf('Warning: Could not determine geometry bounds, using defaults\n');
        geometry.bounds = [-10 10 -10 10]; % Default 20x20mm
    end
    
    fprintf('QUCS parsing complete:\n');
    fprintf('  - Conductors found: %d\n', length(geometry.conductors));
    fprintf('  - Ports found: %d\n', length(geometry.ports));
    fprintf('  - Bounds: [%.2f %.2f %.2f %.2f] mm\n', geometry.bounds);
    
end

function conductor = parse_qucs_mlin(line)
    % Parse MLIN (microstrip line) component
    conductor = struct();
    
    % Extract parameters using regex
    % Example: MLIN Line1 1 100 200 -26 0 "MSUB1" "50 Ω" "10 mm" "0 °" "26.85" "0"
    tokens = regexp(line, '(\w+)\s+(\w+)\s+(\d+)\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\s+(\d+)\s+"([^"]*)".*?"([^"]*)".*?"([^"]*)".*?"([^"]*)"', 'tokens');
    
    if ~isempty(tokens)
        token = tokens{1};
        conductor.type = 'mline';
        conductor.name = token{2};
        conductor.x = str2double(token{4});
        conductor.y = str2double(token{5});
        conductor.angle = str2double(token{6});
        conductor.substrate_ref = token{8};
        
        % Parse width and length with units
        width_str = token{9};
        length_str = token{10};
        
        conductor.width = parse_dimension(width_str);
        conductor.length = parse_dimension(length_str);
        
        % Calculate end coordinates
        angle_rad = conductor.angle * pi / 180;
        conductor.x2 = conductor.x + conductor.length * cos(angle_rad);
        conductor.y2 = conductor.y + conductor.length * sin(angle_rad);
    else
        conductor = [];
    end
end

function conductor = parse_qucs_mstub(line)
    % Parse MSTUB (microstrip stub) component
    conductor = struct();
    
    % Similar parsing for stubs - implementation would depend on QUCS stub format
    conductor = []; % Placeholder - implement based on actual QUCS stub format
end

function port = parse_qucs_port(line)
    % Parse Pac (port) component
    port = struct();
    
    % Extract port parameters
    % Example: Pac P1 1 -160 410 18 -26 0 "1"1"50 Ω"1"0 dBm"0"1 GHz"0"26.85"0"con_2"0
    tokens = regexp(line, 'Pac\s+(\w+)\s+(\d+)\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\s+([-+]?\d*\.?\d+)\s+(\d+)\s+"([^"]*)".*?"([^"]*)"', 'tokens');
    
    if ~isempty(tokens)
        token = tokens{1};
        port.name = token{1};
        port.number = str2double(token{8});
        port.x = str2double(token{3});
        port.y = str2double(token{4});
        port.impedance = parse_dimension(token{9});
        port.type = 'lumped';
    else
        port = [];
    end
end

function substrate = parse_qucs_msub(line)
    % Parse MSUB (substrate) component
    substrate = struct();
    
    % Extract substrate parameters - implementation depends on QUCS MSUB format
    % Set defaults for now
    substrate.er = 4.3;      % Relative permittivity
    substrate.h = 1.6;       % Height in mm
    substrate.t = 0.035;     % Copper thickness in mm
    substrate.tand = 0.02;   % Loss tangent
end

function value = parse_dimension(dim_str)
    % Parse dimension string with units (e.g., "10 mm", "50 Ω")
    if contains(dim_str, 'mm')
        value = str2double(strrep(dim_str, 'mm', ''));
    elseif contains(dim_str, 'mil')
        value = str2double(strrep(dim_str, 'mil', '')) * 0.0254; % Convert mil to mm
    elseif contains(dim_str, 'Ω') || contains(dim_str, 'ohm')
        value = str2double(regexp(dim_str, '\d*\.?\d+', 'match', 'once'));
    else
        value = str2double(dim_str);
    end
    
    if isnan(value)
        value = 0;
    end
end

function bounds = update_bounds(bounds, conductor)
    % Update bounding box with conductor geometry
    if isfield(conductor, 'x') && isfield(conductor, 'y')
        bounds(1) = min(bounds(1), conductor.x - conductor.width/2);
        bounds(2) = max(bounds(2), conductor.x + conductor.width/2);
        bounds(3) = min(bounds(3), conductor.y - conductor.width/2);
        bounds(4) = max(bounds(4), conductor.y + conductor.width/2);
        
        if isfield(conductor, 'x2') && isfield(conductor, 'y2')
            bounds(1) = min(bounds(1), conductor.x2 - conductor.width/2);
            bounds(2) = max(bounds(2), conductor.x2 + conductor.width/2);
            bounds(3) = min(bounds(3), conductor.y2 - conductor.width/2);
            bounds(4) = max(bounds(4), conductor.y2 + conductor.width/2);
        end
    end
end