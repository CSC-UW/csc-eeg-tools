function marked_epochs = csc_compare_scoring(event_data)

if nargin < 1
    [file_name, file_path] = uigetfile('*.mat', 'MultiSelect', 'on');
    if length(file_name) == 2
        event_data{1} = importdata(fullfile(file_path, file_name{1}));
        event_data{2} = importdata(fullfile(file_path, file_name{2}));
    else
        error('must select 2 files');
    end
end

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