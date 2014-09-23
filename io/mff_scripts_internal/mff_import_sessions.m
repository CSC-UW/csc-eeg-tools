function sessions = mff_import_sessions(meta_file)
    sessions_file    = [meta_file filesep 'epochs.xml'];
    sessions_file_id = fopen(sessions_file, 'r');
    sessions         = '';
    session_num      = 0;
    
    while ~feof(sessions_file_id)
        line = fgetl(sessions_file_id);
        
        if ~isempty(strfind(line, '<epoch>'))
            session_num = session_num + 1;
            
            continue
        end
        
        [session] = regexp(line, '<beginTime>(?<start_time>[0-9]+)</beginTime>', 'names');
        
        if ~isempty(session)
            sessions.start_time(session_num) = str2double(session.start_time) / 1000000000;
            
            continue
        end
        
        [session] = regexp(line, '<endTime>(?<end_time>[0-9]+)</endTime>', 'names');
        
        if ~isempty(session)
            sessions.end_time(session_num) = str2double(session.end_time) / 1000000000;
            
            continue
        end
    end
    
    fclose(sessions_file_id);
end
