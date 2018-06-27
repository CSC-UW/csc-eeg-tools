%%written by Brady Riedner 07/23/2012 adapted from scripts by some one
%%better at code writing
%%% University of wisconsin
%%% 10/8/2014 added several lines to deal with description in keys
%%% 
function events = mff_import_eventsNS5(meta_file)
eventtracks = dir([meta_file,filesep,'Events_*.xml']);
events = struct([]);

for t = 1:length(eventtracks)
    num_events = 0;
    events(1).(genvarname(strtok(eventtracks(t).name,'.'))) = [];
    event_file = [meta_file filesep eventtracks(t).name];
    
    id            = fopen(event_file, 'r');
    section_name  = {20}; %20 is abritrary
    section_index = 0;
    
    while ~feof(id)
        line = fgetl(id);
        % checks if it is a section start
        [variables] = regexp(line, '<(?<section>eventTrack|event|keys)( .+)?>', 'names');
        
        if ~isempty(variables)
            section_index               = section_index + 1;
            section_name{section_index} = variables.section;
            
            continue;
        end
        % checks if it is a section end
        [variables] = regexp(line, '</(?<section>eventTrack|event|keys)>', 'names');
        
        if ~isempty(variables)
            section_name{section_index} = '';
            section_index               = section_index - 1;
            
            continue;
        end
        
        if section_index > 0
            switch section_name{section_index}
                case 'eventTrack'
                    [variables] = regexp(line, '<name>(?<name>.*)</name>', 'names');
                    
                    if ~isempty(variables)
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).TrackName = variables.name;
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<trackType>(?<trackType>.*)</trackType>', 'names');
                    
                    if ~isempty(variables)
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).trackType = variables.trackType;
                        
                        continue;
                    end
                    
                    
                    
                    
                case 'event'
                    num_keys = 0;
                    
                %    [variables] = regexp(line, '<beginTime>(?<timestamp>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3})(?<timestamp_submilliseconds>[0-9]{6})(?<timestamp_timezone>[-+][0-9]{2}:[0-9]{2})</beginTime>', 'names'); %could read in as one big datetime in matlab
                    [variables] = regexp(line, '<beginTime>(?<timestamp>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3})(?<timestamp_submilliseconds>[0-9]{3})(?<timestamp_timezone>[-+][0-9]{2}:[0-9]{2})</beginTime>', 'names'); %could read in as one big datetime in matlab
                    
                    if ~isempty(variables)
                        num_events = num_events + 1;
                        
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).recording_timestamp{num_events}                     = variables.timestamp;
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).recording_timestamp_submilliseconds{num_events}     = variables.timestamp_submilliseconds;
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).recording_timestamp_timezone{num_events}            = variables.timestamp_timezone;
                        try
                            events(1).(genvarname(strtok(eventtracks(t).name,'.'))).recording_datevec(num_events,:)                   = datevec(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                        catch
                            events(1).(genvarname(strtok(eventtracks(t).name,'.'))).recording_datevec(num_events,:)                   = datevec(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                        end
                        try
                            events(1).(genvarname(strtok(eventtracks(t).name,'.'))).recording_datenum(num_events,:)                   = datenum(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                        catch
                            events(1).(genvarname(strtok(eventtracks(t).name,'.'))).recording_datenum(num_events,:)                   = datenum(variables.timestamp, 'yyyy-mm-ddTHH:MM:SS.FFF');
                        end
                        continue;
                    end
                    
                    
                    [variables] = regexp(line, '<duration>(?<duration>[0-9]+)</duration>', 'names');
                    
                    if ~isempty(variables)
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).duration(num_events) = str2double(variables.duration);
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<code>(?<code>.*)</code>', 'names');
                    
                    if ~isempty(variables)
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).code{num_events} = variables.code;
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<label>(?<label>.*)</label>', 'names');
                    
                    if ~isempty(variables)
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).label{num_events} = variables.label;
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<description>(?<description>.*)</description>', 'names');
                    
                    if ~isempty(variables)
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).description{num_events} = variables.description;
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<sourceDevice>(?<sourceDevice>.*)</sourceDevice>', 'names');
                    
                    if ~isempty(variables)
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).sourceDevice{num_events} = variables.sourceDevice;
                        
                        continue;
                    end
                    
                case 'keys'
                    [variables] = regexp(line, '<key>', 'names');
   
                    if ~isempty(variables)
                        num_keys = num_keys + 1;
                        %
                        %                         sensorLayout(1).name{num_sensors}               = [];
                        %                         sensorLayout(1).number(num_sensors)             = NaN;
                        %                         sensorLayout(1).type(num_sensors)               = NaN;
                        %                         sensorLayout(1).x(num_sensors)                  = NaN;
                        %                         sensorLayout(1).y(num_sensors)                  = NaN;
                        %                         sensorLayout(1).z(num_sensors)                  = NaN;
                        %                         sensorLayout(1).originalNumber(num_sensors)     = NaN;
                        continue;
                    end
                    
                    [variables] = regexp(line, '<keyCode>(?<keyCode>.*)</keyCode>', 'names');
                    if ~isempty(variables)
                        
                        currKeycode = variables(1).keyCode;
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).keys(num_events).keyCode{num_keys} =currKeycode;
                        
                        continue;
                    end
                    
                    [variables] = regexp(line, '<description>(?<description>.*)</description>', 'names');
                    if ~isempty(variables)
                        
                        currdescription= variables(1).description;
                        events(1).(genvarname(strtok(eventtracks(t).name,'.'))).keys(num_events).description{num_keys} = currdescription;
                        
                        continue;
                    end
                    
                    variables = [];
                    [variables.dataType] = regexp(line, '(?<=")[^"]+(?=")', 'match');
                    [variables.data] = regexp(line, '(?<=>)[^]+(?=<)', 'match');
                    
                    
                    if ~isempty(variables.data)
                        switch variables.dataType{1}
                            case 'string'
                                events(1).(genvarname(strtok(eventtracks(t).name,'.'))).keys(num_events).dataType{num_keys} = variables.dataType{1};
                                events(1).(genvarname(strtok(eventtracks(t).name,'.'))).keys(num_events).data{num_keys} = variables.data{1};
                            case 'long'
                                events(1).(genvarname(strtok(eventtracks(t).name,'.'))).keys(num_events).dataType{num_keys} = variables.dataType{1};
                                events(1).(genvarname(strtok(eventtracks(t).name,'.'))).keys(num_events).data{num_keys} = str2double(variables.data{1});
                        end
                        continue;
                    end
                    
            end
            continue;
        end
    end
fclose(id);
end


end

