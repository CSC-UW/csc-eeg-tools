function [handles, Results] = csc_topography_analysis(data1, data2, eloc, stat_option, stat_type)
% plot topography comparison of two data sets with the option of running 
% statistical analysis

% defaults
SIGNIFICANCE_THRESHOLD = 0.1;

if nargin < 4
    stat_option = [];
    stat_type = 'i';
end

% assign empty output
Results = [];

% define number of plots
no_plots = 3;
if isempty(stat_option)
    no_plots = 2;
end

% define axes start
axes_start = linspace(0, 1, no_plots + 1);
axes_width = diff(axes_start(1:2));

data(:, 1) = mean(data1, 2);
data(:, 2) = mean(data2, 2);

% open new figure
handles.fig = figure('color', 'w', ...
    'position', [100, 100, 500*no_plots, 500]);

for n = 1 : 2
    
    handles.ax(n) = axes('position', [axes_start(n), 0, axes_width, 1]);
    
    topo_handle(n) = csc_Topoplot(data(:, n), eloc, ...
        'axes', handles.ax(n));

end

% equalise the colorbars
set(handles.ax([1,2]), 'clim', [min(data(:)), max(data(:))])

% do the statistics
if isempty(stat_option)
    return
end

switch stat_option
    case 'tfce'
        
        Results = ept_TFCE(...
            repmat(data1', [1, 1, 2]), ...
            repmat(data2', [1, 1, 2]), ...
            eloc, ...
            'nPerm', 1000, ...
            'type', stat_type, ...
            'E_H', [0.66, 2], ...
            'flag_save', false);
        
        handles.ax(3) = axes('position', [axes_start(3), 0, axes_width, 1]);
        
        csc_Topoplot(Results.Obs(:, 1), eloc, ...
            'axes', handles.ax(3),...
            'markedChannels', Results.P_Values(:, 1) < SIGNIFICANCE_THRESHOLD, ...
            'markedColor', 'w');
end