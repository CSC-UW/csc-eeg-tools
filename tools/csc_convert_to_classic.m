function [classic_events, classic_hypnogram, classic_list] = csc_convert_to_classic(EEG, flag_plot)
% convert (down-sample) from continuous scoring to classic windows

if nargin < 2
    flag_plot = true;
end

% window size to convert to (in seconds)
epoch_length_sec = 30;

%% get the sample-by-sample hypnogram
[EEG, table_data, handles] = csc_events_to_hypnogram(EEG, 0, 1, 0);
% extract from EEG
continuous_hypnogram(1, :) = EEG.swa_scoring.stages;

%% examine each epoch and convert
% TODO: currently simple majority score, implement better rules

% pre-allocate new hypnogram
classic_hypnogram = nan(size(continuous_hypnogram));

% calculate number of windows
epoch_length = epoch_length_sec * EEG.srate;
num_epochs = floor(length(continuous_hypnogram) / epoch_length);

for n_e = 1 : num_epochs
   
    % calculate samples
    current_segment = (n_e - 1) * epoch_length + 1 : n_e * epoch_length;
    
    % find mode of hypnogram
    segment_mode = mode(continuous_hypnogram(1, current_segment));
    
    % put mode in the new scoring
    classic_hypnogram(1, current_segment) = segment_mode;
    
end

if flag_plot
    handles.fig = figure('color', 'w');
    handles.ax = axes('nextplot', 'add', ...
        'yDir', 'reverse');
    
    plot(classic_hypnogram(1, :)', ...
        'color', [0.7, 0.7, 0.7], ...
        'lineWidth', 6);
    plot(continuous_hypnogram(1, :)', ...
        'color', [0.3, 0.3, 0.3], ...
        'lineWidth', 1);
    
    title(EEG.filename);
    legend({'classic', 'continuous'}, 'Interpreter', 'none');
end

%% create a list of epoch stages

epoch_starts = 1 : epoch_length : epoch_length * num_epochs;
classic_list = classic_hypnogram (epoch_starts);

%% create an event list (for csc_eeg_plotter)
temp_list = classic_list;
temp_list(temp_list == -1 | temp_list == 0) = 6; 

num_events = size(temp_list, 2);
classic_events = cell(num_events, 4);
classic_events(:, 2) = num2cell(0 : epoch_length_sec : num_events * epoch_length_sec - 1); % event number
classic_events(:, 3) = num2cell(temp_list); % event number
% add labels to the events
labels = {'N1', 'N2', 'N3', 'artifact', 'REM', 'wake', 'check_next'};
classic_events(:, 1) = {labels{[classic_events{:, 3}]}};