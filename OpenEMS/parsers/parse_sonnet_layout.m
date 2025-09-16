function geometry = parse_sonnet_layout(sonnet_file)
%PARSE_SONNET_LAYOUT Parse Sonnet project file and extract geometry
%
%   geometry = parse_sonnet_layout(sonnet_file)
%
%   Parses a Sonnet project file (.son) and extracts geometric information
%   including metal polygons, substrate stack, and ports.
%
%   Inputs:
%       sonnet_file - Path to Sonnet project file (.son)
%
%   Outputs:
%       geometry - Structure containing:
%           .conductors - Array of conductor structures
%           .substrate - Substrate properties
%           .ports - Port locations and properties
%           .bounds - Bounding box [xmin xmax ymin ymax]
%
%   Author: Generated for Interdigital Bandpass Filter Project

    if ~exist(sonnet_file, 'file')
        error('Sonnet file not found: %s', sonnet_file);
    end
    
    fprintf('Parsing Sonnet project: %s\n', sonnet_file);
    
    % Initialize geometry structure
    geometry = struct();
    geometry.conductors = [];
    geometry.substrate = struct();
    geometry.ports = [];
    geometry.bounds = [inf -inf inf -inf]; % [xmin xmax ymin ymax]
    
    % Read the file
    fid = fopen(sonnet_file, 'r');
    if fid == -1
        error('Cannot open Sonnet file: %s', sonnet_file);
    end
    
    try
        % State variables for parsing
        in_geo_section = false;
        in_dielectric_section = false;
        in_metal_section = false;
        in_port_section = false;
        current_metal_level = 0;
        conductor_count = 0;
        port_count = 0;
        
        % Parse file line by line
        while ~feof(fid)
            line = fgetl(fid);
            
            if ~ischar(line)
                break;
            end
            
            % Remove leading/trailing whitespace
            line = strtrim(line);
            
            % Skip empty lines
            if isempty(line)
                continue;
            end
            
            % Parse section headers
            if strcmp(line, 'GEO')
                in_geo_section = true;
                continue;
            elseif strcmp(line, 'END GEO')
                in_geo_section = false;
                continue;
            end
            
            if in_geo_section
                % Parse geometry section
                if startsWith(line, 'DIM')
                    % Parse dimensions and units
                    geometry = parse_sonnet_dimensions(line, geometry);
                    
                elseif startsWith(line, 'TMET')
                    % Parse top metal definition
                    in_metal_section = true;
                    current_metal_level = parse_sonnet_metal_level(line);
                    
                elseif startsWith(line, 'BOX')
                    % Parse simulation box
                    geometry.bounds = parse_sonnet_box(line);
                    
                elseif in_metal_section && (startsWith(line, 'POL') || startsWith(line, 'POLY'))
                    % Parse polygon/conductor
                    conductor = parse_sonnet_polygon(line, current_metal_level);
                    if ~isempty(conductor)
                        conductor_count = conductor_count + 1;
                        conductor.id = conductor_count;
                        geometry.conductors(end+1) = conductor;
                    end
                    
                elseif startsWith(line, 'LORGN')
                    % Parse local origin
                    geometry.origin = parse_sonnet_origin(line);
                    
                elseif startsWith(line, 'SUBDIV')
                    % Parse subdivisions (meshing info)
                    geometry.mesh_info = parse_sonnet_subdivision(line);
                    
                elseif contains(line, 'BMET')
                    % Bottom metal - end of current metal level
                    in_metal_section = false;
                end
            end
            
            % Parse dielectric layers
            if startsWith(line, 'DIE')
                geometry.substrate = parse_sonnet_dielectric(line);
            end
            
            % Parse ports
            if contains(line, 'PORT') || contains(line, 'TPORT')
                port = parse_sonnet_port(line);
                if ~isempty(port)
                    port_count = port_count + 1;
                    port.id = port_count;
                    geometry.ports(end+1) = port;
                end
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
    
    fprintf('Sonnet parsing complete:\n');
    fprintf('  - Conductors found: %d\n', length(geometry.conductors));
    fprintf('  - Ports found: %d\n', length(geometry.ports));
    fprintf('  - Bounds: [%.2f %.2f %.2f %.2f] mm\n', geometry.bounds);
end

function geometry = parse_sonnet_dimensions(line, geometry)
    % Parse DIM line to get units
    % Example: DIM
    geometry.units = 'MIL'; % Default Sonnet unit
    if contains(line, 'MM')
        geometry.units = 'MM';
    elseif contains(line, 'MIL')
        geometry.units = 'MIL';
    end
end

function level = parse_sonnet_metal_level(line)
    % Parse TMET line to get metal level
    % Example: TMET "Metal" 1 SUP 0 0 0 1
    tokens = strsplit(line);
    if length(tokens) >= 3
        level = str2double(tokens{3});
    else
        level = 1;
    end
end

function bounds = parse_sonnet_box(line)
    % Parse BOX line to get simulation boundaries
    % Example: BOX 1 100 200 1000 1000 20 20 0
    tokens = strsplit(line);
    if length(tokens) >= 8
        % Convert from Sonnet units to mm if needed
        xmin = str2double(tokens{2});
        ymin = str2double(tokens{3});
        xmax = str2double(tokens{4});
        ymax = str2double(tokens{5});
        bounds = [xmin xmax ymin ymax];
        
        % Convert from mils to mm if necessary
        if abs(bounds(2) - bounds(1)) > 1000 % Assume mils if > 1000 units
            bounds = bounds * 0.0254;
        end
    else
        bounds = [inf -inf inf -inf];
    end
end

function conductor = parse_sonnet_polygon(line, metal_level)
    % Parse polygon/conductor definition
    % Example: POL 1 1 4 1 0 0 100 0 100 100 0 100 0 0
    conductor = struct();
    
    tokens = strsplit(line);
    if length(tokens) >= 6 && strcmp(tokens{1}, 'POL')
        conductor.type = 'polygon';
        conductor.metal_level = metal_level;
        
        num_vertices = str2double(tokens{4});
        if length(tokens) >= 6 + 2*num_vertices
            % Extract vertex coordinates
            vertices = zeros(num_vertices, 2);
            for i = 1:num_vertices
                vertices(i, 1) = str2double(tokens{6 + 2*i - 1});
                vertices(i, 2) = str2double(tokens{6 + 2*i});
            end
            
            conductor.vertices = vertices;
            
            % Calculate bounding box
            conductor.bounds = [min(vertices(:,1)) max(vertices(:,1)) ...
                               min(vertices(:,2)) max(vertices(:,2))];
            
            % Estimate width and length for rectangular conductors
            width = conductor.bounds(4) - conductor.bounds(3);
            length = conductor.bounds(2) - conductor.bounds(1);
            conductor.width = min(width, length);
            conductor.length = max(width, length);
        else
            conductor = [];
        end
    else
        conductor = [];
    end
end

function origin = parse_sonnet_origin(line)
    % Parse local origin
    origin = [0 0];
    tokens = strsplit(line);
    if length(tokens) >= 3
        origin = [str2double(tokens{2}) str2double(tokens{3})];
    end
end

function mesh_info = parse_sonnet_subdivision(line)
    % Parse subdivision/meshing information
    mesh_info = struct();
    mesh_info.auto_mesh = true; % Default
end

function substrate = parse_sonnet_dielectric(line)
    % Parse dielectric layer information
    % Example: DI 1 4.3 0 0 0 0.02
    substrate = struct();
    
    tokens = strsplit(line);
    if length(tokens) >= 6 && strcmp(tokens{1}, 'DI')
        substrate.er = str2double(tokens{3});     % Relative permittivity
        substrate.tand = str2double(tokens{6});   % Loss tangent
        substrate.h = 1.6;                        % Default height in mm
        substrate.t = 0.035;                      % Default copper thickness
    else
        % Default FR4 properties
        substrate.er = 4.3;
        substrate.h = 1.6;
        substrate.t = 0.035;
        substrate.tand = 0.02;
    end
end

function port = parse_sonnet_port(line)
    % Parse port definition
    port = struct();
    
    % This would need to be implemented based on specific Sonnet port format
    % For now, return empty
    port = [];
end