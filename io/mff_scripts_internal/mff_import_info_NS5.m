function info = mff_import_info_NS5(file)
    info = struct([]);
    
    id      = fopen(file, 'r');
    section = '';
    
    while ~feof(id)
        line = fgetl(id);
        
        [variables] = regexp(line, '<(?<section>fileInfo)( .+)?>', 'names');
        
        if ~isempty(variables)
            section = variables.section;
            
            continue;
        end
        
        [variables] = regexp(line, '</(?<section>fileInfo>)>', 'names');
        
        if ~isempty(variables)
            section = '';
            
            continue;
        end
        
        switch section
            case 'fileInfo'
                [variables] = regexp(line,...
                    '<recordTime>(?<timestamp>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3})(?<timestamp_submilliseconds>[0-9]{3})(?<timestamp_timezone>[-+][0-9]{2}:[0-9]{2})</recordTime>', 'names');
                
                if ~isempty(variables)
                    info(1).recording_timestamp                 = variables.timestamp;
                    info(1).recording_timestamp_submilliseconds = variables.timestamp_submilliseconds;
                    info(1).recording_timestamp_timezone        = variables.timestamp_timezone;
                    try
                        info(1).recording_datevec                   = datevec(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                    catch
                        info(1).recording_datevec                   = datevec(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                    end
                    try
                        info(1).recording_datenum                   = datenum(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                    catch
                        info(1).recording_datenum                   = datenum(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                    end
                    break
                end
        end
    end
    
    fclose(id);
end
