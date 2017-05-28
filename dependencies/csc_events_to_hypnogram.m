function [EEG, table_data, handles] = csc_events_to_hypnogram(EEG, flag_plot)
% turns event data from the csc_eeg_plotter into sleep stages and plots data

handles = [];

% Notes
% ^^^^^
% ignores event 4 labels

% pre-allocate to wake
stages = single(zeros(1, EEG.pnts));

% convert event timing from seconds to samples
event_timing = floor([EEG.csc_event_data{:, 2}] * EEG.srate);

% loop over each event
for n = 1 : length(EEG.csc_event_data)
    
    % ignore "event 4" (artefacts) for basic sleep analysis
    if EEG.csc_event_data{n, 3} == 4
        continue
    end
    
    if n ~= length(EEG.csc_event_data)
        stages(event_timing(n) : event_timing(n + 1)) = ...
            EEG.csc_event_data{n, 3};
    else
        stages(event_timing(n) : end) = ...
        EEG.csc_event_data{n, 3};
    end
    
end

% convert 6 to wake
stages(stages == 6) = 0;

% put back in EEG
EEG.swa_scoring.stages = stages;

% get the sleep stats
table_data = swa_sleep_statistics(EEG, 0, 'deutsch');


if flag_plot
    
    % add 1 to all stages except wake
    stages(stages > 0) = stages(stages > 0) + 1;
    
    % convert REM (now 6 after previous line) to 1
    stages(stages == 6) = 1;
    
    % convert time to hours for plot
    time_range = EEG.times / 1000 / 60 / 60;
    REM_range = stages; REM_range(REM_range ~= 1) = NaN;
    
    % plot hypnogram
    handles.fig = figure('color', 'w');
    handles.ax = axes('nextplot', 'add', ...
        'ytick', 0:4, ...
        'yticklabel', {'WACH', 'REM', 'N1', 'N2', 'N3'}, ...
        'yDir', 'reverse', ...
        'ylim', [-0.5, 4.5]);
    handles.hypno = plot(time_range, stages, ...
        'lineWidth', 1);
    handles.REM_plot =  plot(time_range, REM_range, ...
        'lineWidth', 4, ...
        'color', 'r');
    % label axes
    xlabel('time (hours)')
    ylabel('sleep stage')
        
    % make a pie chart
    pie_data = cell2mat(table_data(3:7, 4));
%     pie_labels = {'wake', 'N1', 'N2', 'N3', 'REM'};
    figure('color', 'w');
%     handles.pie = pie(pie_data, pie_labels);
    handles.pie = pie(pie_data, {'', '', '', '', ''});
end