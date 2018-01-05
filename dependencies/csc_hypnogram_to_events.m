% hypnogram to events

% find all the transitions
transitions = [0, find(diff(int8(EEG.swa_scoring.stages)) ~= 0)] + 1;

% what stage did it transition to?
events = EEG.swa_scoring.stages(transitions);

% change stage 0 to event 6
events(events==0) = 6;
% change stage 255 to 4
events(events==255) = 4;

% plot found transitions
figure('color', 'w');
axes('nextplot', 'add', ...
    'ylim', [-0.5, 5.5]);
plot(EEG.swa_scoring.stages);
plot(transitions, events, 'linestyle', 'none', 'marker', 'v', ...
    'markerFaceColor', 'k');


% create event_data for csc_eeg_plotter
% pre-allocate the event data
event_data = cell(length(events), 3);

% insert latencies
event_data(:, 2) = num2cell(transitions / EEG.srate);

% insert type
event_data(:, 3) = num2cell(events);

% insert event labels
% NOTE: no one ever changes the event labels from default so this might be deletable
all_labels = cellfun(@(x) ['event ', num2str(x)], event_data(:, 3), 'uni', 0);
event_data(:, 1) = all_labels;

% sort the events by latency
[~, sort_ind] = sort([event_data{:, 2}]);
EEG.csc_event_data = event_data(sort_ind, :);