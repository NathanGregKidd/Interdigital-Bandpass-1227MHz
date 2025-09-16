function format_type = detect_layout_format(layout_file)
%DETECT_LAYOUT_FORMAT Automatically detect the layout file format
%
%   format_type = detect_layout_format(layout_file)
%
%   Detects whether a layout file is in QUCS (.sch), Sonnet (.son), 
%   or KiCad (.kicad_pcb) format based on file extension and content.
%
%   Inputs:
%       layout_file - Path to layout file
%
%   Outputs:
%       format_type - String: 'qucs', 'sonnet', or 'kicad'
%
%   Author: Generated for Interdigital Bandpass Filter Project

    [~, ~, ext] = fileparts(layout_file);
    
    % First check by file extension
    switch lower(ext)
        case '.sch'
            % Could be QUCS schematic, verify by content
            format_type = 'qucs';
            try
                fid = fopen(layout_file, 'r');
                if fid == -1
                    error('Cannot open file: %s', layout_file);
                end
                first_line = fgetl(fid);
                fclose(fid);
                
                if ~contains(first_line, 'QucsStudio') && ~contains(first_line, 'Qucs Schematic')
                    error('File appears to be schematic but not QUCS format');
                end
            catch ME
                warning('Could not verify QUCS format: %s', ME.message);
            end
            
        case '.son'
            % Sonnet project file
            format_type = 'sonnet';
            try
                fid = fopen(layout_file, 'r');
                if fid == -1
                    error('Cannot open file: %s', layout_file);
                end
                first_line = fgetl(fid);
                fclose(fid);
                
                if ~contains(first_line, 'FTYP SONPROJ') && ~contains(first_line, 'SONNET')
                    warning('File extension is .son but content may not be Sonnet format');
                end
            catch ME
                warning('Could not verify Sonnet format: %s', ME.message);
            end
            
        case '.kicad_pcb'
            % KiCad PCB file
            format_type = 'kicad';
            try
                fid = fopen(layout_file, 'r');
                if fid == -1
                    error('Cannot open file: %s', layout_file);
                end
                first_line = fgetl(fid);
                fclose(fid);
                
                if ~contains(first_line, 'kicad_pcb')
                    error('File appears to be KiCad but not PCB format');
                end
            catch ME
                warning('Could not verify KiCad PCB format: %s', ME.message);
            end
            
        otherwise
            % Try to detect by content
            try
                fid = fopen(layout_file, 'r');
                if fid == -1
                    error('Cannot open file: %s', layout_file);
                end
                
                % Read first few lines to detect format
                content = '';
                for i = 1:5
                    line = fgetl(fid);
                    if ischar(line)
                        content = [content, ' ', line];
                    else
                        break;
                    end
                end
                fclose(fid);
                
                % Check content patterns
                if contains(content, 'QucsStudio') || contains(content, 'Qucs Schematic')
                    format_type = 'qucs';
                elseif contains(content, 'FTYP SONPROJ') || contains(content, 'SONNET')
                    format_type = 'sonnet';
                elseif contains(content, 'kicad_pcb')
                    format_type = 'kicad';
                else
                    error('Unknown file format: %s', layout_file);
                end
                
            catch ME
                error('Could not detect file format for %s: %s', layout_file, ME.message);
            end
    end
    
    fprintf('Format detection: %s -> %s\n', ext, format_type);
end