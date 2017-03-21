function EEG = csc_import_events_from_EEG(EEG, event_names)
% function used to create the event_table from the handle structure

% pull out the events from the handles structure
relevant_events = find(cellfun(@(x) any(strcmp(x, event_names)), {EEG.event.type}));

% calculate the number of unique events
no_events = length(relevant_events);

% pre-allocate the event data
event_data = cell(no_events, 3);

% loop for each event type
for n = 1 : no_events
      
    % event type into the event_data
    event_data(n, 1) = {EEG.event(relevant_events(n)).type};
    
    % event latency (converto seconds)
    event_data(n, 2) = {EEG.event(relevant_events(n)).latency / EEG.srate};
    
    % add the event type number in case labels are changed
    event_data(n, 3) = {find(strcmp(event_data(n, 1), event_names))};
    
end

% sort the events by latency
[~, sort_ind] = sort([event_data{:, 2}]);
EEG.csc_event_data = event_data(sort_ind, :);