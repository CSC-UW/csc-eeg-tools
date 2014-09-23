function session_breaks = mff_map_session_breaks(meta_file)
    sessions       = mff_import_sessions(meta_file);
    num_sessions   = length(sessions.start_time);
    session_breaks = struct('time', zeros(num_sessions - 1, 1), 'duration', zeros(num_sessions - 1, 1));
	
	if num_sessions > 1
        session_breaks.onset(1)    = sessions.end_time(1);
        session_breaks.duration(1) = sessions.start_time(2) - sessions.end_time(1);
        
        for session_num = 2:num_sessions - 1
            session_breaks.onset(session_num)    = sessions.end_time(session_num) - session_breaks.duration(session_num - 1);
            session_breaks.duration(session_num) = session_breaks.duration(session_num - 1) + sessions.start_time(session_num + 1) - sessions.end_time(session_num);
        end
    else
        session_breaks = struct([]);
	end
end
