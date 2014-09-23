function absolute_timestamp = mff_find_absolute_timestamp(meta_file)
    info_file    = [meta_file filesep 'info.xml'];
    info_file_id = fopen(info_file, 'r');
    
    absolute_timestamp = '';
    
    while ~feof(info_file_id)
        line = fgetl(info_file_id);
        
        if ischar(line)
            [absolute_timestamp] = regexp(line, '<recordTime>(?<timestamp>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3})(?<offset>[0-9]{6})(?<timezone>[-+][0-9]{2}:[0-9]{2})</recordTime>', 'names');
            
            if ~isempty(absolute_timestamp)
                absolute_timestamp.datevec = datevec(absolute_timestamp.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                absolute_timestamp.datenum = datenum(absolute_timestamp.datevec);
                
                break
            end
        end
    end
    
    fclose(info_file_id);
end
