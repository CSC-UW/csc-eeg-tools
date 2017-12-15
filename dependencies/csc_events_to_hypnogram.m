function [EEG, table_data, handles] = csc_events_to_hypnogram(EEG, flag_plot, flag_mode, flag_type)
% turns event data from the csc_eeg_plotter into sleep stages and plots data

% [EEG, table_data, handles] = csc_events_to_hypnogram(EEG, ...
%     flag_plot, ... % [0/1] whether to plot the hypnogram or not
%     flag_mode, ... % [0/1] whether classic [0] or continuous [1] scoring was used... or basically whether arousals have two 4 events [0] or artefacts have a single event 4 at the start [1]
%     flag_type) % [0/1] whether to output the long table [0] with lots of accurate parameters (for research purposes), or the nice summary table for patient reports [1]

handles = [];

% Notes
% ^^^^^
% flag_mode denotes whether its classical (0) or transitional scoring (1)
% the essential distinction is how to treat "event 4": in classical scoring this
% is used to mark arousals (one at the start and end of the arousal), in 
% transitional scoring arousals are marked simply as brief wake periods and 
% "event 4" is used to denote signal artefacts (and ignored for scoring)

% custom options
if nargin < 2
    flag_plot = false;
end
if nargin < 3
    flag_mode = 0; % default to classical sleep scoring
end
if nargin < 4
    flag_type = 0; % default to csc table
end

% remove all event 4 and save in separate arousal/artefact table
% ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
% find event 4s
event4_logical = [EEG.csc_event_data{:, 3}] == 4;
event4_ind = find(event4_logical);

% create new table of only event 4s
event4_table = [EEG.csc_event_data(event4_logical, :)];

% pre-allocate arousal logical
EEG.swa_scoring.arousals = false(EEG.pnts, 1);

% loop over each event 4
if flag_mode == 0 && sum(event4_logical) > 0
    % there should be an even number of event 4s since each marks start and end
    % of an arousal
    if mod(sum(event4_logical), 2)
        error('There is an odd number of event 4s, check your events')
    end
    
    for n = 1 : 2 : sum(event4_logical)
        % find samples
        start_sample = floor(event4_table{n, 2} + 0.000001 * EEG.srate) + 1;
        end_sample = floor(event4_table{n + 1, 2} * EEG.srate);
        % mark the interval samples as true
        EEG.swa_scoring.arousals(start_sample : end_sample) = true;
    end
    
elseif flag_mode == 1
    % each artefact's end is simply marked by the next stage
    for n = 1 : sum(event4_logical)
        % find samples
        start_sample = floor(event4_table{n, 2} * EEG.srate) + 1;
        
        % check that last event is a 4
        if EEG.csc_event_data{end, 3} == 4
            end_sample = EEG.pnts;
        else
            end_sample = floor(EEG.csc_event_data{event4_ind(n) + 1, 2} * EEG.srate);
        end
        % mark the interval samples as true
        EEG.swa_scoring.arousals(start_sample : end_sample) = true;
    end
end


% produce the sleep scoring stages %
% '''''''''''''''''''''''''''''''' %
% create a temporary table without event 4
tmp_events = EEG.csc_event_data(~event4_logical, :);

% convert event timing from seconds to samples
event_timing = ceil([tmp_events{:, 2}] * EEG.srate);

% check that first event sample is not 0
if event_timing(1) == 0
    event_timing(1) = 1;
end

% pre-allocate to wake
stages = int8(ones(1, EEG.pnts) * -1);

% loop over each scoring event
for n = 1 : length(tmp_events)
       
    % check for last event
    if n ~= length(tmp_events)
        stages(event_timing(n) : event_timing(n + 1)) = ...
            tmp_events{n, 3};
    else
        stages(event_timing(n) : end) = ...
        tmp_events{n, 3};
    end
    
end

% convert 6 to wake
stages(stages == 6) = 0;

% put back in EEG
EEG.swa_scoring.stages = stages;

% get the sleep stats
if flag_type == 0
    table_data = csc_sleep_statistics(EEG, flag_mode);
else
    table_data = swa_sleep_statistics(EEG, 0, 'deutsch', flag_mode);
end

% plot classic hypnogram and stage pie chart
if flag_plot
    
    % add 1 to all stages except wake
    stages(stages > 0) = stages(stages > 0) + 1;
    
    % convert REM (now 6 after previous line) to 1
    stages(stages == 6) = 1;
    
    % convert time to hours for plot
    time_range = EEG.times / 1000 / 60 / 60;
    
    % create a new range to colour REM in red
    REM_range = double(stages); REM_range(REM_range ~= 1) = NaN;
    
    % plot hypnogram
    handles.fig = figure('color', 'w');
    handles.ax = axes('nextplot', 'add', ...
        'xlim', [0, time_range(end)], ...
        'ytick', 0:4, ...
        'yticklabel', {'WACH', 'REM', 'N1', 'N2', 'N3'}, ...
        'yDir', 'reverse', ...
        'ylim', [-0.5, 4.5]);
    handles.hypno = plot(time_range, stages, ...
        'lineWidth', 1);
    handles.REM_plot =  plot(time_range, REM_range, ...
        'lineWidth', 4, ...
        'color', 'r');
    
    % plot arousals/artefacts
    arousal_range = double(EEG.swa_scoring.arousals);
    arousal_range(arousal_range == 0) = NaN;
    handles.arousals =  plot(time_range, arousal_range - 1.2, ...
        'lineWidth', 3, ...
        'color', 'k');
    
    % label axes
    xlabel('time (hours)')
    ylabel('sleep stage')
    
    % make a pie chart
    % TODO: make pie chart with csc table output
    if flag_type
        pie_data = cell2mat(table_data(3:7, 4));
        figure('color', 'w');
        handles.pie = pie(pie_data, {'', '', '', '', ''});
    end
end