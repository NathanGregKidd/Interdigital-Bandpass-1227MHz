function [CSX, port, mesh] = setup_openems_simulation(geometry, params)
%SETUP_OPENEMS_SIMULATION Setup OpenEMS simulation from parsed geometry
%
%   [CSX, port, mesh] = setup_openems_simulation(geometry, params)
%
%   Creates OpenEMS CSX structure, ports, and mesh from parsed geometry.
%   Automatically determines appropriate mesh resolution and simulation parameters.
%
%   Inputs:
%       geometry - Parsed geometry structure from layout parsers
%       params - Simulation parameters structure
%
%   Outputs:
%       CSX - OpenEMS CSX structure
%       port - Array of port structures
%       mesh - Mesh information structure
%
%   Author: Generated for Interdigital Bandpass Filter Project

    fprintf('Setting up OpenEMS simulation...\n');
    
    % Initialize OpenEMS
    CSX = InitCSX();
    
    % Setup frequency
    freq_center = (params.freq_start + params.freq_stop) / 2;
    freq_span = params.freq_stop - params.freq_start;
    
    % Calculate simulation domain based on geometry bounds
    margin_factor = 0.3; % 30% margin around geometry
    width = geometry.bounds(2) - geometry.bounds(1);
    height = geometry.bounds(4) - geometry.bounds(3);
    margin_x = width * margin_factor;
    margin_y = height * margin_factor;
    
    % Simulation domain (convert to mm)
    sim_bounds = [geometry.bounds(1) - margin_x, geometry.bounds(2) + margin_x, ...
                  geometry.bounds(3) - margin_y, geometry.bounds(4) + margin_y];
    
    % Z-direction bounds (substrate + air)
    z_sub_bottom = -params.substrate_h;
    z_sub_top = 0;
    z_air_top = params.substrate_h * 3; % Air region above substrate
    
    fprintf('Simulation domain: [%.2f %.2f %.2f %.2f %.2f %.2f] mm\n', ...
            sim_bounds(1), sim_bounds(2), sim_bounds(3), sim_bounds(4), z_sub_bottom, z_air_top);
    
    %% Setup Materials
    
    % Air material
    CSX = AddMaterial(CSX, 'air');
    CSX = SetMaterialProperty(CSX, 'air', 'Epsilon', 1, 'Mue', 1);
    
    % Substrate material
    CSX = AddMaterial(CSX, 'substrate');
    CSX = SetMaterialProperty(CSX, 'substrate', 'Epsilon', params.substrate_er, 'Mue', 1);
    if isfield(params, 'substrate_tand')
        CSX = SetMaterialProperty(CSX, 'substrate', 'Kappa', ...
                                params.substrate_tand * params.substrate_er * 8.854e-12 * 2*pi*freq_center);
    end
    
    % Conductor material (PEC - Perfect Electric Conductor)
    CSX = AddMetal(CSX, 'metal');
    
    %% Create Geometry
    
    % Substrate box
    start = [sim_bounds(1), sim_bounds(3), z_sub_bottom];
    stop = [sim_bounds(2), sim_bounds(4), z_sub_top];
    CSX = AddBox(CSX, 'substrate', 10, start, stop);
    
    % Add conductors
    conductor_height = params.substrate_h * 0.001; % Thin conductor above substrate
    
    for i = 1:length(geometry.conductors)
        conductor = geometry.conductors(i);
        
        switch conductor.type
            case {'trace', 'mline'}
                % Add trace as a box
                if isfield(conductor, 'x1') && isfield(conductor, 'x2')
                    % Line segment
                    start_trace = [min(conductor.x1, conductor.x2) - conductor.width/2, ...
                                   min(conductor.y1, conductor.y2) - conductor.width/2, ...
                                   z_sub_top];
                    stop_trace = [max(conductor.x1, conductor.x2) + conductor.width/2, ...
                                  max(conductor.y1, conductor.y2) + conductor.width/2, ...
                                  z_sub_top + conductor_height];
                else
                    % Point-based conductor
                    start_trace = [conductor.x - conductor.width/2, ...
                                   conductor.y - conductor.width/2, ...
                                   z_sub_top];
                    stop_trace = [conductor.x + conductor.width/2, ...
                                  conductor.y + conductor.width/2, ...
                                  z_sub_top + conductor_height];
                end
                CSX = AddBox(CSX, 'metal', 10, start_trace, stop_trace);
                
            case 'via'
                % Add via as a cylinder
                if isfield(conductor, 'diameter')
                    radius = conductor.diameter / 2;
                    start_via = [conductor.x, conductor.y, z_sub_bottom];
                    stop_via = [conductor.x, conductor.y, z_sub_top + conductor_height];
                    CSX = AddCylinder(CSX, 'metal', 10, start_via, stop_via, radius);
                end
                
            case 'polygon'
                % Add polygon (simplified as bounding box for now)
                if isfield(conductor, 'bounds')
                    start_poly = [conductor.bounds(1), conductor.bounds(3), z_sub_top];
                    stop_poly = [conductor.bounds(2), conductor.bounds(4), z_sub_top + conductor_height];
                    CSX = AddBox(CSX, 'metal', 10, start_poly, stop_poly);
                end
        end
    end
    
    %% Setup Mesh
    
    % Determine mesh resolution
    lambda_min = 3e8 / params.freq_stop; % Minimum wavelength in air
    lambda_sub = lambda_min / sqrt(params.substrate_er); % Wavelength in substrate
    
    if strcmp(params.mesh_res, 'auto')
        % Automatic mesh resolution
        mesh_res = lambda_sub / 20; % Lambda/20 resolution
    else
        mesh_res = params.mesh_res;
    end
    
    fprintf('Mesh resolution: %.3f mm (λ/%.1f)\n', mesh_res, lambda_sub/mesh_res);
    
    % Create mesh lines
    mesh.x = sim_bounds(1) : mesh_res : sim_bounds(2);
    mesh.y = sim_bounds(3) : mesh_res : sim_bounds(4);
    
    % Z-mesh with finer resolution near interfaces
    mesh_z_fine = mesh_res / 4;
    mesh.z = [z_sub_bottom : mesh_res : z_sub_bottom + mesh_res, ...
              z_sub_top - mesh_z_fine : mesh_z_fine : z_sub_top + mesh_z_fine, ...
              z_sub_top + mesh_res : mesh_res : z_air_top];
    
    % Add mesh lines at conductor edges for better accuracy
    for i = 1:length(geometry.conductors)
        conductor = geometry.conductors(i);
        if isfield(conductor, 'x')
            mesh.x = [mesh.x, conductor.x - conductor.width/2, conductor.x + conductor.width/2];
        end
        if isfield(conductor, 'y')
            mesh.y = [mesh.y, conductor.y - conductor.width/2, conductor.y + conductor.width/2];
        end
        if isfield(conductor, 'x1')
            mesh.x = [mesh.x, conductor.x1, conductor.x2];
            mesh.y = [mesh.y, conductor.y1, conductor.y2];
        end
    end
    
    % Remove duplicates and sort
    mesh.x = unique(mesh.x);
    mesh.y = unique(mesh.y);
    mesh.z = unique(mesh.z);
    
    % Apply mesh to CSX
    CSX = DefineRectGrid(CSX, 1e-3, [mesh.x; mesh.y; mesh.z]);
    
    fprintf('Mesh size: %d x %d x %d = %d cells\n', ...
            length(mesh.x)-1, length(mesh.y)-1, length(mesh.z)-1, ...
            (length(mesh.x)-1)*(length(mesh.y)-1)*(length(mesh.z)-1));
    
    %% Setup Ports
    
    port = {};
    port_impedance = 50; % Default port impedance
    
    % If ports are defined in geometry, use them
    if ~isempty(geometry.ports)
        for i = 1:length(geometry.ports)
            geo_port = geometry.ports(i);
            port_width = 2; % Default port width
            
            % Port 1 (usually on left)
            if i == 1
                start_port = [sim_bounds(1), geo_port.y - port_width/2, z_sub_top];
                stop_port = [sim_bounds(1) + mesh_res, geo_port.y + port_width/2, z_sub_top + conductor_height];
                direction = [1, 0, 0]; % X-direction
            else
                % Port 2 (usually on right)
                start_port = [sim_bounds(2) - mesh_res, geo_port.y - port_width/2, z_sub_top];
                stop_port = [sim_bounds(2), geo_port.y + port_width/2, z_sub_top + conductor_height];
                direction = [-1, 0, 0]; % Negative X-direction
            end
            
            [CSX, port{i}] = AddMSLPort(CSX, 999+i, i, 'metal', 'substrate', direction, ...
                                        start_port, stop_port, 'ExcitePort', i==1, 'FeedShift', 10*mesh_res, 'MeasPlaneShift', mesh_res/3);
        end
    else
        % Default ports at simulation boundaries
        port_width = min(width, height) * 0.1; % 10% of smaller dimension
        port_center_y = (geometry.bounds(3) + geometry.bounds(4)) / 2;
        
        % Port 1 (left side)
        start_port1 = [sim_bounds(1), port_center_y - port_width/2, z_sub_top];
        stop_port1 = [sim_bounds(1) + mesh_res, port_center_y + port_width/2, z_sub_top + conductor_height];
        [CSX, port{1}] = AddMSLPort(CSX, 999, 1, 'metal', 'substrate', [1,0,0], ...
                                   start_port1, stop_port1, 'ExcitePort', true, 'FeedShift', 10*mesh_res, 'MeasPlaneShift', mesh_res/3);
        
        % Port 2 (right side)  
        start_port2 = [sim_bounds(2) - mesh_res, port_center_y - port_width/2, z_sub_top];
        stop_port2 = [sim_bounds(2), port_center_y + port_width/2, z_sub_top + conductor_height];
        [CSX, port{2}] = AddMSLPort(CSX, 1000, 2, 'metal', 'substrate', [-1,0,0], ...
                                   start_port2, stop_port2, 'ExcitePort', false, 'FeedShift', 10*mesh_res, 'MeasPlaneShift', mesh_res/3);
    end
    
    %% Boundary Conditions
    
    % PML (Perfectly Matched Layer) absorbing boundaries
    BC = {'PML_8', 'PML_8', 'PML_8', 'PML_8', 'PML_8', 'PML_8'};
    CSX = AddBoundCond(CSX, BC);
    
    %% Excitation
    
    % Gaussian pulse excitation
    f_max = params.freq_stop * 1.2; % 20% higher than max frequency
    CSX = AddExcitation(CSX, 'excite', 0, [1, 0, 0]);
    CSX = SetGaussExcite(CSX, 'excite', freq_center, f_max - params.freq_start);
    
    % Write CSX file
    WriteOpenEMS('simulation.xml', CSX);
    
    fprintf('OpenEMS setup complete!\n');
    fprintf('- Materials: air, substrate (εr=%.1f), metal\n', params.substrate_er);
    fprintf('- Ports: %d\n', length(port));
    fprintf('- Boundary conditions: PML absorbing\n');
    
    % Store mesh information
    mesh.info = struct();
    mesh.info.resolution = mesh_res;
    mesh.info.cells_total = (length(mesh.x)-1)*(length(mesh.y)-1)*(length(mesh.z)-1);
    mesh.info.domain_size = [sim_bounds(2)-sim_bounds(1), sim_bounds(4)-sim_bounds(3), z_air_top-z_sub_bottom];
end