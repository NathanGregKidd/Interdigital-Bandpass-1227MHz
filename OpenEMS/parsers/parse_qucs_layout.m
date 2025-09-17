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
            if ~isempty(strfind(line, 'MLIN'))
                conductor = parse_qucs_mlin(line);
                if ~isempty(conductor)
                    conductor_count = conductor_count + 1;
                    conductor.id = conductor_count;
                    geometry.conductors(end+1) = conductor;
                    
                    % Update bounding box
                    geometry.bounds = update_bounds(geometry.bounds, conductor);
                end
                
            % Parse coupled microstrip lines (MCOUPLED components)
            elseif ~isempty(strfind(line, 'MCOUPLED'))
                conductors = parse_qucs_mcoupled(line);
                for j = 1:length(conductors)
                    if ~isempty(conductors{j})
                        conductor_count = conductor_count + 1;
                        conductors{j}.id = conductor_count;
                        geometry.conductors(end+1) = conductors{j};
                        
                        % Update bounding box
                        geometry.bounds = update_bounds(geometry.bounds, conductors{j});
                    end
                end
                
            % Parse microstrip stubs (MSTUB components)
            elseif ~isempty(strfind(line, 'MSTUB'))
                conductor = parse_qucs_mstub(line);
                if ~isempty(conductor)
                    conductor_count = conductor_count + 1;
                    conductor.id = conductor_count;
                    geometry.conductors(end+1) = conductor;
                    
                    % Update bounding box
                    geometry.bounds = update_bounds(geometry.bounds, conductor);
                end
                
            % Parse ports (Pac components)
            elseif ~isempty(strfind(line, 'Pac'))
                port = parse_qucs_port(line);
                if ~isempty(port)
                    port_count = port_count + 1;
                    port.id = port_count;
                    geometry.ports(end+1) = port;
                end
                
            % Parse substrate properties (SUBST components)
            elseif ~isempty(strfind(line, 'SUBST'))
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
    % Example: MLIN MS25 1 -70 350 -44 -102 0 "Subst1"1"3.104 mm"1"5 mm"1"26.85"0
    conductor = struct();
    
    % Split by spaces and quotes to extract parameters
    parts = strsplit(line);
    
    if length(parts) >= 8 && strcmp(parts{1}, 'MLIN')
        conductor.type = 'mline';
        conductor.name = parts{2};
        
        % Extract coordinates (positions 4,5) and rotation (position 6)
        conductor.x = str2double(parts{4});
        conductor.y = str2double(parts{5});
        conductor.rotation = str2double(parts{7}); % rotation in degrees
        
        % Extract quoted parameters - substrate, width, length
        quoted_params = {};
        in_quote = false;
        current_param = '';
        
        for i = 8:length(parts)
            part = parts{i};
            if startsWith(part, '"')
                in_quote = true;
                current_param = part(2:end);
                if endsWith(part, '"') && length(part) > 1
                    current_param = current_param(1:end-1);
                    quoted_params{end+1} = current_param;
                    in_quote = false;
                    current_param = '';
                end
            elseif in_quote
                if endsWith(part, '"')
                    current_param = [current_param ' ' part(1:end-1)];
                    quoted_params{end+1} = current_param;
                    in_quote = false;
                    current_param = '';
                else
                    current_param = [current_param ' ' part];
                end
            end
        end
        
        if length(quoted_params) >= 3
            conductor.substrate_ref = quoted_params{1};
            conductor.width = parse_dimension(quoted_params{2});
            conductor.length = parse_dimension(quoted_params{3});
        else
            % Default values if parsing fails
            conductor.substrate_ref = 'Subst1';
            conductor.width = 1.0; % mm
            conductor.length = 5.0; % mm
        end
        
        % Calculate end coordinates based on rotation
        angle_rad = conductor.rotation * pi / 180;
        conductor.x2 = conductor.x + conductor.length * cos(angle_rad);
        conductor.y2 = conductor.y + conductor.length * sin(angle_rad);
    else
        conductor = [];
    end
end

function conductors = parse_qucs_mcoupled(line)
    % Parse MCOUPLED (coupled microstrip lines) component
    % Example: MCOUPLED MS6 1 340 100 -6 -141 1 "Subst1"1"3.104 mm"1"30.741 mm"1"9.473 mm"1"26.85"0
    conductors = {};
    
    parts = strsplit(line);
    
    if length(parts) >= 8 && strcmp(parts{1}, 'MCOUPLED')
        % Extract quoted parameters
        quoted_params = {};
        in_quote = false;
        current_param = '';
        
        for i = 8:length(parts)
            part = parts{i};
            if startsWith(part, '"')
                in_quote = true;
                current_param = part(2:end);
                if endsWith(part, '"') && length(part) > 1
                    current_param = current_param(1:end-1);
                    quoted_params{end+1} = current_param;
                    in_quote = false;
                    current_param = '';
                end
            elseif in_quote
                if endsWith(part, '"')
                    current_param = [current_param ' ' part(1:end-1)];
                    quoted_params{end+1} = current_param;
                    in_quote = false;
                    current_param = '';
                else
                    current_param = [current_param ' ' part];
                end
            end
        end
        
        if length(quoted_params) >= 4
            base_name = parts{2};
            x = str2double(parts{4});
            y = str2double(parts{5});
            rotation = str2double(parts{7});
            
            substrate_ref = quoted_params{1};
            width = parse_dimension(quoted_params{2});
            length = parse_dimension(quoted_params{3});
            spacing = parse_dimension(quoted_params{4});
            
            % Create two coupled conductors
            angle_rad = rotation * pi / 180;
            
            % Conductor 1 (offset by -spacing/2 in perpendicular direction)
            offset_x1 = -(spacing/2) * sin(angle_rad);
            offset_y1 = (spacing/2) * cos(angle_rad);
            
            conductor1 = struct();
            conductor1.type = 'mline_coupled';
            conductor1.name = [base_name '_1'];
            conductor1.x = x + offset_x1;
            conductor1.y = y + offset_y1;
            conductor1.x2 = conductor1.x + length * cos(angle_rad);
            conductor1.y2 = conductor1.y + length * sin(angle_rad);
            conductor1.width = width;
            conductor1.length = length;
            conductor1.rotation = rotation;
            conductor1.substrate_ref = substrate_ref;
            conductor1.coupling_spacing = spacing;
            
            % Conductor 2 (offset by +spacing/2 in perpendicular direction)
            offset_x2 = (spacing/2) * sin(angle_rad);
            offset_y2 = -(spacing/2) * cos(angle_rad);
            
            conductor2 = struct();
            conductor2.type = 'mline_coupled';
            conductor2.name = [base_name '_2'];
            conductor2.x = x + offset_x2;
            conductor2.y = y + offset_y2;
            conductor2.x2 = conductor2.x + length * cos(angle_rad);
            conductor2.y2 = conductor2.y + length * sin(angle_rad);
            conductor2.width = width;
            conductor2.length = length;
            conductor2.rotation = rotation;
            conductor2.substrate_ref = substrate_ref;
            conductor2.coupling_spacing = spacing;
            
            conductors = {conductor1, conductor2};
        end
    end
end

function conductor = parse_qucs_mstub(line)
    % Parse MSTUB (microstrip stub) component
    conductor = struct();
    
    % Similar to MLIN but for stub - placeholder implementation
    parts = strsplit(line);
    
    if length(parts) >= 8 && strcmp(parts{1}, 'MSTUB')
        conductor.type = 'mstub';
        conductor.name = parts{2};
        conductor.x = str2double(parts{4});
        conductor.y = str2double(parts{5});
        conductor.rotation = str2double(parts{7});
        
        % For now, treat as short line segment
        conductor.width = 1.0; % Default width
        conductor.length = 2.0; % Default stub length
        
        angle_rad = conductor.rotation * pi / 180;
        conductor.x2 = conductor.x + conductor.length * cos(angle_rad);
        conductor.y2 = conductor.y + conductor.length * sin(angle_rad);
    else
        conductor = [];
    end
end

function port = parse_qucs_port(line)
    % Parse Pac (port) component  
    % Example: Pac P1 1 -160 410 18 -26 0 "1"1"50 Ω"1"0 dBm"0"1 GHz"0"26.85"0"con_2"0
    port = struct();
    
    parts = strsplit(line);
    
    if length(parts) >= 8 && strcmp(parts{1}, 'Pac')
        port.name = parts{2};
        port.x = str2double(parts{4});
        port.y = str2double(parts{5});
        
        % Extract quoted parameters
        quoted_params = {};
        in_quote = false;
        current_param = '';
        
        for i = 8:length(parts)
            part = parts{i};
            if startsWith(part, '"')
                in_quote = true;
                current_param = part(2:end);
                if endsWith(part, '"') && length(part) > 1
                    current_param = current_param(1:end-1);
                    quoted_params{end+1} = current_param;
                    in_quote = false;
                    current_param = '';
                end
            elseif in_quote
                if endsWith(part, '"')
                    current_param = [current_param ' ' part(1:end-1)];
                    quoted_params{end+1} = current_param;
                    in_quote = false;
                    current_param = '';
                else
                    current_param = [current_param ' ' part];
                end
            end
        end
        
        if length(quoted_params) >= 2
            port.number = str2double(quoted_params{1});
            port.impedance = parse_dimension(quoted_params{2});
        else
            port.number = 1;
            port.impedance = 50;
        end
        
        port.type = 'lumped';
    else
        port = [];
    end
end

function substrate = parse_qucs_msub(line)
    % Parse SUBST (substrate) component
    % Example: SUBST Subst1 1 730 890 -30 24 0 "9.8"1"1 mm"1"35 µm"1"2e-4"1"1.72e-8"1"0"0"Metal"0"Hammerstad"0"Kirschning"0
    substrate = struct();
    
    parts = strsplit(line);
    
    if length(parts) >= 8 && strcmp(parts{1}, 'SUBST')
        % Extract quoted parameters
        quoted_params = {};
        in_quote = false;
        current_param = '';
        
        for i = 8:length(parts)
            part = parts{i};
            if startsWith(part, '"')
                in_quote = true;
                current_param = part(2:end);
                if endsWith(part, '"') && length(part) > 1
                    current_param = current_param(1:end-1);
                    quoted_params{end+1} = current_param;
                    in_quote = false;
                    current_param = '';
                end
            elseif in_quote
                if endsWith(part, '"')
                    current_param = [current_param ' ' part(1:end-1)];
                    quoted_params{end+1} = current_param;
                    in_quote = false;
                    current_param = '';
                else
                    current_param = [current_param ' ' part];
                end
            end
        end
        
        if length(quoted_params) >= 4
            substrate.er = str2double(quoted_params{1});     % Relative permittivity
            substrate.h = parse_dimension(quoted_params{2});  % Height
            substrate.t = parse_dimension(quoted_params{3});  % Metal thickness 
            substrate.tand = str2double(quoted_params{4});    % Loss tangent
        else
            % Default FR4 properties
            substrate.er = 4.3;
            substrate.h = 1.6;
            substrate.t = 0.035;
            substrate.tand = 0.02;
        end
        
        % Ensure reasonable values
        if substrate.er < 1 || substrate.er > 100
            substrate.er = 4.3;
        end
        if substrate.h <= 0
            substrate.h = 1.6;
        end
        if substrate.t <= 0
            substrate.t = 0.035;
        end
        if substrate.tand < 0 || substrate.tand > 1
            substrate.tand = 0.02;
        end
    else
        % Default FR4 properties
        substrate.er = 4.3;
        substrate.h = 1.6;
        substrate.t = 0.035;
        substrate.tand = 0.02;
    end
end

function value = parse_dimension(dim_str)
    % Parse dimension string with units (e.g., "10 mm", "50 Ω", "35 µm")
    if isempty(dim_str)
        value = 0;
        return;
    end
    
    % Handle different units
    if ~isempty(strfind(dim_str, 'mm'))
        value = str2double(strrep(dim_str, 'mm', ''));
    elseif ~isempty(strfind(dim_str, 'mil'))
        value = str2double(strrep(dim_str, 'mil', '')) * 0.0254; % Convert mil to mm
    elseif ~isempty(strfind(dim_str, 'µm')) || ~isempty(strfind(dim_str, 'um'))
        % Micrometers to mm
        clean_str = strrep(strrep(dim_str, 'µm', ''), 'um', '');
        value = str2double(clean_str) / 1000;
    elseif ~isempty(strfind(dim_str, 'Ω')) || ~isempty(strfind(dim_str, 'ohm'))
        value = str2double(regexp(dim_str, '\d*\.?\d+', 'match', 'once'));
    elseif ~isempty(strfind(dim_str, 'GHz'))
        value = str2double(strrep(dim_str, 'GHz', '')) * 1e9;
    elseif ~isempty(strfind(dim_str, 'MHz'))
        value = str2double(strrep(dim_str, 'MHz', '')) * 1e6;
    elseif ~isempty(strfind(dim_str, 'e-')) || ~isempty(strfind(dim_str, 'E-'))
        % Scientific notation
        value = str2double(dim_str);
    else
        % Try direct conversion
        value = str2double(dim_str);
    end
    
    if isnan(value)
        value = 0;
        fprintf('Warning: Could not parse dimension "%s", using 0\n', dim_str);
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