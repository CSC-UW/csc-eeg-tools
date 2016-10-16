function [H, group_n] = csc_group_time_series(data, trial_labels, epoch_length, flag_patch, axes_handle)

if nargin < 4
   flag_patch = true;
   axes_handle = [];
end

% ignore nan in trial_labels
nan_ind = isnan(trial_labels);
trial_labels(nan_ind) = [];
data(nan_ind, :) =  [];

% get basic structure
group_labels = unique(trial_labels);
n_groups = length(group_labels);

% pre-allocate
group_n = nan(1, n_groups);
group_mean = nan(n_groups, size(data, 2));
group_error = nan(n_groups, size(data, 2));

% calculate each group mean and standard error
for n = 1 : n_groups
    
    group_n(n) = sum(trial_labels == group_labels(n));
    
    group_mean(n,:) = mean(data(trial_labels == group_labels(n), :), 1);
    group_error(n,:) = std(data(trial_labels == group_labels(n), :), 1) ...  
        / sqrt(group_n(n));
%     group_error(n,:) = std(data(trial_labels == group_labels(n), :), 1);
    
end

% specify the time range to plot
time_range = linspace(epoch_length(1), epoch_length(2), size(data, 2));
time_range = repmat(time_range, n_groups, 1);

% define error bar patch
upper_limit = group_mean + group_error; 
lower_limit = group_mean - group_error;

patch_yData = [lower_limit, fliplr(upper_limit)];
patch_xData = [time_range, fliplr(time_range)];


% Actual ERP Plotting
if isempty(axes_handle)
    H.Figure = figure('color', 'w' , ...
        'position', [200, 200, 800, 400]);
    H.Axes = axes('nextPlot', 'add' , ...
        'xlim', [epoch_length(1), epoch_length(2)]);
else
    H.Axes = axes_handle;
end

set(H.Axes, 'colorOrder', hsv(n_groups));

if flag_patch
    H.Patch = patch(patch_xData',patch_yData',1);
    set(H.Patch,...
        'parent',           H.Axes             ,...
        'EdgeColor',        'none'              ,...
        'FaceColor',        'flat'              ,...
        'FaceVertexCData',  hsv(n_groups)       ,...
        'CDataMapping',     'direct'            ,...
        'FaceAlpha',        0.2                );
end

% plot the line over the patch
H.Line = plot(H.Axes, time_range', group_mean' , ...
    'lineWidth', 2);

% label the axes
% xlabel(H.Axes, 'time');
% ylabel(H.Axes, 'intensity');

Y_Lim = get(H.Axes, 'YLim');
line([0,0],Y_Lim, 'Color', [0 0 0], 'LineStyle', '--')

