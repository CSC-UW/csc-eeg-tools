function mff_mark_bad_channels(meta_file, bad_channels)
    info_file        = [meta_file filesep 'info1.xml'];
    info_file_backup = [info_file '.bak'];
    
    if exist(info_file_backup, 'file')
        delete(info_file_backup);
    end
    
    movefile(info_file, info_file_backup);
    
    file_id_backup = fopen(info_file_backup, 'r');
    file_id        = fopen(info_file, 'w');
    
    while ~feof(file_id_backup)
        line = fgetl(file_id_backup);
        
        fprintf(file_id, '%s\n', line);
        
        if ~isempty(strfind(line, '</generalInformation>'))
            bad_channels_list = sprintf('%d ', bad_channels);
            
            fprintf(file_id, '    <channels exclusion="badChannels">%s\n', bad_channels_list);
            fprintf(file_id, '    </channels>\n');
        end
    end
    
    fclose(file_id_backup);
    fclose(file_id);
end
