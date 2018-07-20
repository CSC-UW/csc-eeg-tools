function EEG = csc_artefacts_from_events(EEG)
% after using the csc_eeg_plotter to mark artefacts with events 1 and 2
% this script can be used to create a good_samples field

% pre-allocate
EEG.good_samples = true(EEG.pnts, 1);

% check if there are even events
if ~isfield(EEG, 'csc_event_data')
   fprintf(1, 'Info: No events found in the data, returned all good data\n');
   return
elseif isempty(EEG.csc_event_data)
    fprintf(1, 'Info: No events found in the data, returned all good data\n');
    return
end

% get all event 1s
event_starts = cellfun(@(x) strcmp(x, 'event 1'), EEG.csc_event_data(:, 1));

% sanity check for artifact event markers
if sum(event_starts) ~= sum(~event_starts)
   fprintf('\nWarning: uneven number of events, check event_data\n');
   return
end

% create a good_time list
for n = 1 : 2 : size(EEG.csc_event_data, 1)
    
    current_range = floor(EEG.csc_event_data{n, 2} * EEG.srate) : ...
        ceil(EEG.csc_event_data{n + 1, 2} * EEG.srate);
    
    EEG.good_samples(current_range) = false;
end

if isfield(EEG, 'csc_log')
    EEG.csc_log{end+1} = ['mark artefacts in good_samples']; % update log
end