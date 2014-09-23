function [signal_info, num_calibrations, calibrations] = mff_import_signal_info(file)
    signal_info      = struct([]);
    num_calibrations = 0;
    calibrations     = struct([]);
    
    id      = fopen(file, 'r');
    section = '';
    
    while ~feof(id)
        line = fgetl(id);
        
        [variables] = regexp(line, '<(?<section>EEG|spectral|sourceData|PNSData|JTF|tValues|calibrations)( .+)?>', 'names');
        
        if ~isempty(variables)
            section = variables.section;
            
            continue;
        end
        
        [variables] = regexp(line, '</(?<section>EEG|spectral|sourceData|PNSData|JTF|tValues|calibrations)>', 'names');
        
        if ~isempty(variables)
            section = '';
            
            continue;
        end
        
        switch section
            case 'EEG'
                if isempty(signal_info)
                    signal_info(1).type               = 'eeg';
                    signal_info(1).sensor_layout_name = '';
                    signal_info(1).montage_name       = '';
                end
                
                [variables] = regexp(line, '<sensorLayoutName>(?<sensor_layout_name>.+)</sensorLayoutName>', 'names');
                
                if ~isempty(variables)
                    signal_info.sensor_layout_name = variables.sensor_layout_name;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<montageName>(?<montage_name>.+)</montageName>', 'names');
                
                if ~isempty(variables)
                    signal_info.montage_name = variables.montage_name;
                    
                    continue;
                end
                
            case 'sourceData'
                if isempty(signal_info)
                    signal_info(1).type            = 'source_localization';
                    signal_info(1).dipole_set_name = '';
                end
                
                [variables] = regexp(line, '<dipoleSetName>(?<dipole_set_name>.+)</dipoleSetName>', 'names');
                
                if ~isempty(variables)
                    signal_info.dipole_set_name = variables.dipole_set_name;
                    
                    continue;
                end
                
            case 'calibrations'
                [variables] = regexp(line, '<calibration>', 'names');
                
                if ~isempty(variables)
                    num_calibrations = num_calibrations + 1;
                    
                    calibrations(1).time_from(num_calibrations) = NaN;
                    calibrations(1).time_to(num_calibrations)   = NaN;
                    calibrations(1).type(num_calibrations, :)   = '    ';
                    calibrations(1).values(num_calibrations, :) = NaN;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<beginTime>(?<time_from>[0-9]+)</beginTime>', 'names');
                
                if ~isempty(variables)
                    calibrations(1).time_from(num_calibrations) = str2double(variables.time_from) / 1000000000;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<endTime>(?<time_to>[0-9]+)</endTime>', 'names');
                
                if ~isempty(variables)
                    calibrations(1).time_to(num_calibrations) = str2double(variables.time_to) / 1000000000;
                    
                    continue;
                end
                
                [variables] = regexp(line, '<type>(?<type>[GZI]CAL)</type>', 'names');
                
                if ~isempty(variables)
                    calibrations(1).type(num_calibrations, :) = variables.type(:);
                    
                    continue;
                end
                
                [variables] = regexp(line, '<ch n="(?<channel_num>[0-9]+)">(?<value>[-0-9.]+)</ch>', 'names');
                
                if ~isempty(variables)
                    channel_num = str2double(variables.channel_num);
                    value       = str2double(variables.value);
                    
                    calibrations(1).values(num_calibrations, channel_num) = value;
                    
                    continue;
                end
        end
    end
    
    fclose(id);
end
