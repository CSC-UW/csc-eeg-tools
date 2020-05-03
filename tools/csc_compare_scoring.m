function [agreement, marked_epochs, confusion_matrix] = csc_compare_scoring(EEG, event_data, flag_type, flag_plot)
    
% need the EEG structure for total file length
if nargin < 1
   [file_name, file_path] = uigetfile('*.set');
   load(fullfile(file_path, file_name), '-mat');
end

%% load the 2 scoring files
if nargin < 2
    
    % ask user for the files 
    % NOTE: in case the order should be reversed "file_name = fliplr(file_name)"
    [file_name, file_path] = uigetfile('*.mat', 'MultiSelect', 'on');
    
    % initialise event_data
    event_data = cell(0);
    if length(file_name) == 2
        event_data{1} = importdata(fullfile(file_path, file_name{1}));
        event_data{2} = importdata(fullfile(file_path, file_name{2}));
    else
        error('must select 2 files');
    end
end

if nargin < 4
    flag_type = 1;
    flag_plot = 0;
end

% check event_data
if ~isa(event_data, 'cell')
    error('Error: incorrect information for the event_data')
end
if numel(event_data) ~= 2
    error('Error: incorrect information for the event_data')
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
    agreement = 100 - num_diff/num_stages*100;
    
    fprintf(1, 'There are %i epochs scored differently; %01.f%% of the data \n', num_diff, num_diff/num_stages*100);
    pie(categorical(stages(marked_epochs, 2)));
end

%% continuous scoring
if flag_type == 1
    % calculate the hypnogram from first file...
    EEG.csc_event_data = event_data{1};
    [EEG, table_data, handles] = csc_events_to_hypnogram(EEG, 0, 1, 0);
    
    % get continuous hypnogram
    hypnogram(1, :) = EEG.swa_scoring.stages;
    % get classic hypnogram
    classic_hypnogram = nan(size(hypnogram));
    [~, classic_hypnogram(1, :)] = csc_convert_to_classic(EEG, 0);
   
    % calculate the hypnogram from second file...
    EEG.csc_event_data = event_data{2};
    [EEG, table_data, handles] =  csc_events_to_hypnogram(EEG, 0, 1, 0);
    
    % get hypnogram
    hypnogram(2, :) = EEG.swa_scoring.stages;
    [~, classic_hypnogram(2, :)] = csc_convert_to_classic(EEG, 0);

    % in case of -1
    hypnogram(hypnogram == -1) = 0;
    
    % make all N3 = N2
    % hypnogram(hypnogram == 3) = 2;
    
    % find differences
    stage_diff = hypnogram(1, :) ~= hypnogram(2, :);
    num_diff = sum(stage_diff);
    marked_epochs = find(stage_diff);
    agreement = 100 - num_diff/length(stage_diff)*100;

    fprintf(1, 'There are %i epochs scored differently; %01.f%% of the data \n', num_diff, num_diff/length(stage_diff)*100);
    
    
    % calculate total overlap
%     different_stages = 
    
    % calculate confusion matrix
    [confusion_matrix, order] = confusionmat(hypnogram(1, :), hypnogram(2, :), ...
        'order', [0, 1, 2, 3, 5]);
    
    
    if flag_plot

        % plot confusion matrix
        h_fig = figure('color', 'w');
        
        [confusion_chart] = confusionchart(confusion_matrix, ...
            {'wake', 'N1', 'N2', 'N3', 'REM'}, ...
            'normalization', 'row-normalized', ...
            'RowSummary', 'row-normalized', ...
            'ColumnSummary', 'column-normalized', ...
            'xlabel', file_name{2}, ...
            'ylabel', file_name{1});

        % plot both hypnograms
        handles.fig = figure('color', 'w');
        handles.ax = axes('nextplot', 'add', ...
            'yDir', 'reverse', ...
            'ylim', [-0.5, 5.5]);
        
        plot(hypnogram(1, :)', ...
            'color', [0.1, 0.7, 0.7], ...
            'lineWidth', 1);
        plot(single(hypnogram(2, :))' + 0.1, ...
            'color', [0.3, 0.3, 1], ...
            'lineWidth', 1);
        
        yticklabels({'wake'; 'N1'; 'N2'; 'N3'; ' '; 'REM'})
        title(EEG.filename, 'Interpreter', 'none');
        legend(file_name, 'Interpreter', 'none');
    end    
end
