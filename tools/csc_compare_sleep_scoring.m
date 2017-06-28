% load EEG and scoring and rename scoring variables

% compare two sleep scoring files
EEG.csc_event_data = event_data_AM;
[EEG, table_data, handles] = csc_events_to_hypnogram(EEG, 0);

% get hypnogram
hypnogram(1, :) = EEG.swa_scoring.stages;

% compare two sleep scoring files
EEG.csc_event_data = event_data_NH;
[EEG, table_data, handles] = csc_events_to_hypnogram(EEG, 0);

% get hypnogram
hypnogram(2, :) = EEG.swa_scoring.stages;

% plot both
handles.fig = figure('color', 'w');
handles.ax = axes('nextplot', 'add', ...
    'yDir', 'reverse');

plot(hypnogram(2, :)', ...
    'color', [0.7, 0.7, 0.7], ...
    'lineWidth', 6);
plot(hypnogram(1, :)', ...
    'color', [0.3, 0.3, 0.3], ...
    'lineWidth', 1);

% compare both
length(find(diff(hypnogram)))/length(hypnogram) * 100;

% which states have the most disagreements
diff_ind = find(diff(hypnogram));
diff_stages = hypnogram(1, diff_ind);
pie(diff_stages);

% - normalise the transitions to 30s windows - %
% pre-allocate new hypnogram
transformed_hypnogram = nan(size(hypnogram));

% calculate number of windows
epoch_length = 30 * EEG.srate;
num_epochs = floor(length(hypnogram) / epoch_length);
scoring_round = 2;

for n_e = 1 : num_epochs
   
    % calculate samples
    current_segment = (n_e - 1) * epoch_length + 1 : n_e * epoch_length;
    
    % find mode of hypnogram
    segment_mode = mode(hypnogram(scoring_round, current_segment));
    
    % put mode in the new scoring
    transformed_hypnogram(scoring_round, current_segment) = segment_mode;
    
end

% plot both
handles.fig = figure('color', 'w');
handles.ax = axes('nextplot', 'add', ...
    'yDir', 'reverse');

plot(transformed_hypnogram(2, :)', ...
    'color', [0.7, 0.7, 0.7], ...
    'lineWidth', 6);
plot(transformed_hypnogram(1, :)', ...
    'color', [0.3, 0.3, 0.3], ...
    'lineWidth', 1);

length(find(diff(transformed_hypnogram)))/length(transformed_hypnogram) * 100;
