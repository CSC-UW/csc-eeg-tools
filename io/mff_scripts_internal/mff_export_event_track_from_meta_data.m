function mff_export_event_track(meta_data, event_track_name, events)
    % events is a structure that has the event info
    event_track_file = [meta_data.meta_file filesep sprintf('Events_%s.xml', strrep(event_track_name, ' ', '_'))];
    
    id = fopen(event_track_file, 'w');
    
    fprintf(id, '<?xml version="1.0" encoding="iso-8859-1" standalone="yes"?>\n');
    fprintf(id, '<eventTrack xmlns="http://www.egi.com/event_mff" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n');
    fprintf(id, '\t<name>%s</name>\n', event_track_name);
    fprintf(id, '\t<trackType>EVNT</trackType>\n');
    
    num_events = length(events.code);
    
    for event_num = 1:num_events
        onset    = round(1000 * events.onset(event_num));
        duration = round(1000000000 * events.duration(event_num));
        
        fprintf(id, '\t<event>\n');
        fprintf(id, '\t\t<beginTime>%s%s%s</beginTime>\n', datestr(addtodate(meta_data.info.recording_datenum, onset, 'millisecond'), 'yyyy-mm-ddTHH:MM:SS.FFF'), meta_data.info.recording_timestamp_submilliseconds, meta_data.info.recording_timestamp_timezone);
        fprintf(id, '\t\t<duration>%lu</duration>\n', duration);
        fprintf(id, '\t\t<code>%s</code>\n', events.code{event_num});
        fprintf(id, '\t\t<label>%s</label>\n', events.label{event_num});
        fprintf(id, '\t\t<description>%s</description>\n', events.description{event_num});
        fprintf(id, '\t\t<sourceDevice>%s</sourceDevice>\n', events.source{event_num});
        
        num_keys = length(events.keys(event_num).code);
        
        if num_keys > 0
            fprintf(id, '\t\t<keys>\n');
            
            for key_num = 1:num_keys
                fprintf(id, '\t\t\t<key>\n');
                fprintf(id, '\t\t\t\t<keyCode>%s</keyCode>\n', events.keys(event_num).code{key_num});
                fprintf(id, '\t\t\t\t<data dataType=\"%s\">%s</data>\n', events.keys(event_num).data_type{key_num}, events.keys(event_num).data{key_num});
                fprintf(id, '\t\t\t</key>\n');
            end
            
            fprintf(id, '\t\t</keys>\n');
        end
        
        fprintf(id, '\t</event>\n');
    end
    
    fprintf(id, '</eventTrack>\n');
    
    fclose(id);
end
