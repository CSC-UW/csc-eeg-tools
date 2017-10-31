function handles = csc_subplot(n_rows, n_columns, axes_space)

if nargin < 3
    axes_space = 0.05;
end

% open a figure
handles.fig = figure('color', 'w', 'units', 'norm');

% determine axes spacing (normalised units)
axes_space = 0.05;
axes_width = 1 / n_columns - axes_space * 1.5;
axes_height = 1 / n_rows - axes_space * 1.5;

% determine axes positions
axes_x_s = linspace(axes_width + axes_space, 1 - axes_space, n_columns) - axes_width;
axes_y_s = linspace(axes_height + axes_space, 1 - axes_space, n_rows) - axes_height;

% create all axes
for h = 1 : n_columns
    for v = 1 : n_rows

        handles.axes(v, h) = axes(...
            'position', [...
                axes_x_s(h), axes_y_s(n_rows - v + 1), ...
                axes_width, axes_height], ...
                'nextplot', 'add');
    end
end