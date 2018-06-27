function eventstruct = convert_mffevents_to_eeglab_eventsNS5(mffevents,properties,sampling_rate)
eventstruct = struct('type',{},'latency',{},'duration',{},'code',{});

mffevent_fields = fieldnames(mffevents);
for mefi = 1:length(mffevent_fields)
    % latency in samples, duration in seconds
    fieldstruct = struct('type',mffevents.(mffevent_fields{mefi}).label,...
        'latency',num2cell(round(seconds(datetime(mffevents.(mffevent_fields{mefi}).recording_datenum,'ConvertFrom','datenum')' - ...
        properties.recording_start_datetime(1))).*sampling_rate),...
        'duration',num2cell(round(mffevents.(mffevent_fields{mefi}).duration./1e3,3)),...
        'code',mffevents.(mffevent_fields{mefi}).code);
    
    eventstruct = [eventstruct fieldstruct]; %#ok<AGROW>
end
% replace empty labels with their code (just in case)
emptytype_index = find(cellfun(@isempty,{eventstruct.type}));
% must be a better way
for ei = emptytype_index
    eventstruct(ei).type =  eventstruct(ei).code;
end
eventstruct = rmfield(eventstruct,'code');
end