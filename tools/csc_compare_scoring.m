function marked_epochs = csc_compare_scoring(EEG, event_data, flag_type, flag_plot)

% check event_data
if isa(event_data, 'cell')
    error('Error: incorrect information for the event_data')
end
if numel(event_data) ~= 2
    error('Error: incorrect information for the event_data')
end
    
%% load the 2 scoring files
if nargin < 1

    % initialise event_data
    event_data = cell(0);
    
    [file_name, file_path] = uigetfile('*.mat', 'MultiSelect', 'on');
    if length(file_name) == 2
        event_data{1} = importdata(fullfile(file_path, file_name{1}));
        event_data{2} = importdata(fullfile(file_path, file_name{2}));
    else
        error('must select 2 files');
    end
end

%% classic scoring
if flag_type == 0
    % compare lengths
    event_sizes = cellfun(@length, event_data);
    
    % extract event numbers
    num_stages = length(event_data{1});
    stages = nan(num_stages, 2);
    
    for m = 1 : 2
        for n = 1 : num_stages
            stages(n, m) = event_data{m}{n, 3};
        end
    end
    
    % find differences
    stage_diff = stages(:, 1) ~= stages(:, 2);
    num_diff = sum(stage_diff);
    marked_epochs = find(stage_diff);
    
    fprintf(1, 'There are %i epochs scored differently; %01.f%% of the data \n', num_diff, num_diff/num_stages*100);
    pie(categorical(stages(marked_epochs, 2)));
end

%% continuous scoring
if flag_type == 1
    EEG.csc_event_data = event_data{1};
    [EEG, table_data, handles] = csc_events_to_hypnogram(EEG, 0, 1, 0);
    
    % get hypnogram
    hypnogram(1, :) = EEG.swa_scoring.stages;
    
    % compare two sleep scoring files
    EEG.csc_event_data = event_data{2};
    [EEG, table_data, handles] =  csc_events_to_hypnogram(EEG, 0, 1, 0);
    
    % get hypnogram
    hypnogram(2, :) = EEG.swa_scoring.stages;
    
    if flag_plot
        % plot both
        handles.fig = figure('color', 'w');
        handles.ax = axes('nextplot', 'add', ...
            'yDir', 'reverse');
        
        plot(hypnogram(2, :)', ...
            'color', [0.7, 0.7, 0.7], ...
            'lineWidth', 3);
        plot(single(hypnogram(1, :))' + 0.1, ...
            'color', [0.3, 0.3, 0.3], ...
            'lineWidth', 1);
        
        title(EEG.filename);
        legend(file_name, 'Interpreter', 'none');
    end    
end
