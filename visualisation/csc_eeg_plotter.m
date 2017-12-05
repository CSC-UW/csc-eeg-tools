function EEG = csc_eeg_plotter(varargin)
% visualisation and event editor for time series data
% Author: Armand Mensen

% TODO:
% Fix ugly default setting style (e.g. handles.options...)    

% declare defaults
handles.filter_options = [0.7 40; 10 40; 0.3 10; 0.1 10]; % default filter bands
handles.epoch_length = 30; % default viewing window
handles.n_disp_chans = 12; % number of initial channels to display
handles.v_grid_spacing = 1; % vertical grid default spacing (s)
handles.h_grid_spacing = 75; % horizontal grid default spacing (uV)
handles.plot_hgrid = 1; % plot the horizontal grid
handles.plot_vgrid = 1; % plot the vertical grid
handles.plotICA = false; % plot components by default
handles.negative_up = false; % negative up by default (for clinicians)
handles.number_of_event_types = 6; % how many event types do you want

% sleep scoring options
handles.scoring_mode = false; % sleep scoring off by default
handles.scoring_window = handles.epoch_length; % how far window scrolls
handles.scoring_offset = 0; % where (in window) to place event marker

handles.component_projection = false; % viewing the difference between the data and remaining ica component projections

% define the default colorscheme to use
handles.colorscheme = struct(...
    'fg_col_1',     [0.9, 0.9, 0.9] , ...     
    'fg_col_2',     [0.8, 0.8, 0.8] , ...    
    'fg_col_3',     [0.5, 0.5, 0.5] , ...        
    'bg_col_1',     [0.1, 0.1, 0.1] , ...
    'bg_col_2',     [0.2, 0.2, 0.2] , ...
    'bg_col_3',     [0.15, 0.15, 0.15] );

% Set initial display channels
handles.disp_chans = [1 : handles.n_disp_chans];

% Undisplayed channels are off the plot entirely. Hidden channels reserve space
% on the plot, but are invisible. 
handles.hidden_chans = [];

% make a window
% ~~~~~~~~~~~~~
handles.fig = figure(...
    'name',         'csc EEG Plotter',...
    'numberTitle',  'off',...
    'color',         handles.colorscheme.bg_col_1,...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.04 .5 0.96]);

% make the axes
% ~~~~~~~~~~~~~
% main axes
handles.main_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.025 0.2, 0.95, 0.75]   ,...
    'nextPlot',     'add'                   ,...
    'color',        handles.colorscheme.bg_col_2 ,...
    'xcolor',       handles.colorscheme.fg_col_1 ,...
    'ycolor',       handles.colorscheme.fg_col_1 ,...  
    'ytick',        []                      ,...
    'fontName',     'Century Gothic'        ,...
    'fontSize',     8                       );

% navigation/spike axes
handles.spike_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.025 0.075, 0.95, 0.05] ,...
    'ylim',         [0, handles.number_of_event_types], ... % events are indicated by vertical position
    'ydir',         'reverse'               , ... 
    'nextPlot',     'add'                   ,...
    'color',        handles.colorscheme.bg_col_2 ,...
    'xcolor',       handles.colorscheme.fg_col_1 ,...
    'ycolor',       handles.colorscheme.fg_col_1 ,...  
    'ytick',        []                      ,...   
    'fontName',     'Century Gothic'        ,...
    'fontSize',     8                       );
set(handles.spike_ax, 'buttondownfcn', {@fcn_time_select});

% invisible name axis
handles.name_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0 0.2, 0.1, 0.75]   ,...
    'visible',      'off');

% invisible axis for lower event labels
% NOTE: otherwise constantly have to change ydata with each axes change
handles.ax_lower_event = axes(...
    'parent',       handles.fig, ...
    'position',     [0.025 0.2, 0.95, 0.1], ...
    'nextPlot',     'add', ...
    'ylim',         [0, 1], ...
    'visible',      'off');


% create the uicontextmenu for the main axes
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
handles.selection.menu = uicontextmenu;
set(handles.main_ax, 'uicontextmenu', handles.selection.menu);
% TODO: move to loading stage and read from file or create these defaults
for n = 1 : handles.number_of_event_types
    handles.selection.item(n) = uimenu(handles.selection.menu,...
        'label', ['event ', num2str(n)], 'userData', n);
    set(handles.selection.item(n),...
        'callback',     {@cb_event_selection, n});
end

% create cell array of the valid numbers for keyboard shortcuts
handles.valid_event_keys = cellfun(@num2str, num2cell(1:handles.number_of_event_types), ...
    'uniformoutput', 0);

% create the menu bar
% ~~~~~~~~~~~~~~~~~~~
handles.menu.file = uimenu(handles.fig, 'label', 'file');
handles.menu.load = uimenu(handles.menu.file ,...
    'Label', 'load eeg' ,...
    'Accelerator', 'l' );
handles.menu.save = uimenu(handles.menu.file ,...
    'Label', 'save eeg' ,...
    'Accelerator', 's' );

handles.menu.montage = uimenu(handles.fig, 'label', 'montage', 'enable', 'off');
handles.menu.events = uimenu(handles.fig, 'label', 'events', 'accelerator', 'v');

% options menu
handles.menu.options = uimenu(handles.fig, 'label', 'options');
handles.menu.filter_toggle = uimenu(handles.menu.options,...
    'label', 'filter toggle',...
    'checked', 'on' ,...
    'callback', {@fcn_options, 'filter_toggle'});
handles.menu.filter_settings = uimenu(handles.menu.options,...
    'label', 'filter settings',...
    'accelerator', 'f' ,...
    'callback', {@fcn_filter_settings});
handles.menu.icatoggle = uimenu(handles.menu.options,...
    'label', 'toggle channels/components',...
    'checked', 'off' ,...
    'accelerator', 't', ...
    'callback', {@fcn_options, 'icatoggle'});
handles.menu.export_hidden_chans = uimenu(handles.menu.options,...
    'label', 'export hidden channels',...
    'callback', {@fcn_options, 'export_hidden_chans'});
handles.menu.export_marked_trials = uimenu(handles.menu.options,...
    'label', 'export marked trials',...
    'callback', {@fcn_options, 'export_marked_trials'});
handles.menu.export_axes = uimenu(handles.menu.options,...
    'label', 'export current axes',...
    'callback', {@fcn_options, 'export_axes'});
handles.menu.scoring_toggle = uimenu(handles.menu.options,...
    'label', 'sleep scoring mode',...
    'checked', 'off' ,...
    'callback', {@fcn_options, 'scoring_mode'});

% view menu
handles.menu.view = uimenu(handles.fig, 'label', 'view');
handles.menu.disp_chans = uimenu(handles.menu.view,...
    'label', 'display channels',...
    'accelerator', 'd', ...
    'callback', {@fcn_options, 'disp_chans'});
handles.menu.epoch_length = uimenu(handles.menu.view,...
    'label', 'epoch length',...
    'accelerator', 'e',...
    'callback', {@fcn_options, 'epoch_length'});
handles.menu.colorscheme = uimenu(handles.menu.view ,...
    'label', 'color scheme', ...
    'callback', {@fcn_options, 'color_scheme'});
handles.menu.hgrid_spacing = uimenu(handles.menu.view ,...
    'label', 'horizontal grid', ...
    'accelerator', 'h' ,...
    'callback', {@fcn_options, 'hgrid_spacing'});
handles.menu.vgrid_spacing = uimenu(handles.menu.view ,...
    'label', 'vertical grid', ...
    'accelerator', 'g' ,...
    'callback', {@fcn_options, 'vgrid_spacing'});
handles.menu.negative_toggle = uimenu(handles.menu.view,...
    'label', 'negative up',...
    'accelerator', 'n' ,...
    'checked', 'off' ,...
    'callback', {@fcn_options, 'negative_toggle'});

% scale indicator
% ~~~~~~~~~~~~~~~
handles.txt_scale = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'text',...
    'String',   '100',...
    'Visible',  'off',...
    'Value',    100);


% hidden epoch tracker
% ````````````````````
handles.cPoint = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'text',...
    'Visible',  'off',...
    'Value',    1);

% set the callbacks
% ~~~~~~~~~~~~~~~~~
set(handles.fig, 'closeRequestFcn', {@fcn_close_window});

set(handles.menu.load,      'callback', {@fcn_load_eeg});
set(handles.menu.save,      'callback', {@fcn_save_eeg});
set(handles.menu.montage,   'callback', {@fcn_montage_setup});
set(handles.menu.events,    'callback', {@fcn_event_browser});

set(handles.fig,...
    'KeyPressFcn', {@cb_key_pressed,});

% put update axes function handles in handles
handles.update_axes = @update_main_plot;

% update the figure handles
guidata(handles.fig, handles)

% Look for input arguments
switch nargin
    case 0
        % wait for user input
    case 1
        
        % get the EEG from the input
        EEG = varargin{1};
        
        % check for previously epoched data
        if EEG.trials > 1
            % flatten the third dimension into the second
            eegData = reshape(EEG.data, size(EEG.data, 1), []);
            setappdata(handles.fig, 'EEG', EEG);
            setappdata(handles.fig, 'eegData', eegData);
            
            % change the epoch length to match trial length by default
            handles.epoch_length = EEG.pnts / EEG.srate;
            
        else
            eegData = EEG.data;
            
            setappdata(handles.fig, 'EEG', EEG);
            setappdata(handles.fig, 'eegData', EEG.data);
        end
        
        EEG = initialize_loaded_eeg(handles.fig, EEG, eegData);
        setappdata(handles.fig, 'EEG', EEG);
               
        % update the plot to draw current EEG
        update_main_plot(handles.fig);
        
        % redraw event triangles if present
        if isfield(EEG, 'csc_event_data')
            fcn_redraw_events(handles.fig, []);
        end
        
        % draw trial borders on the main axes
        fcn_plot_trial_borders(handles.fig)
        
    otherwise
        error('Either 0 or 1 arguments expected.');
end

% if an output is expected, wait for the figure to close
if nargout > 0
    uiwait(handles.fig);
    
    % get the handles structure
    handles = guidata(handles.fig);
    
    % get the metadata
    EEG = getappdata(handles.fig, 'EEG');

    % add the event table to the EEG struct
    if isfield(handles, 'events')
        EEG.csc_event_data = fcn_compute_events(handles);
    end
    
    % just add the hidden channels and trials to the data
    EEG.marked_trials = handles.trials;
    % TODO: won't work with different montages just yet
    EEG.hidden_channels = handles.hidden_chans;
        
    % close the figure
    delete(handles.fig);
    
else
    % return an empty variable
    EEG = [];
end
 
% File Loading and Saving
% ^^^^^^^^^^^^^^^^^^^^^^^
function fcn_load_eeg(object, ~)
% get the handles structure
handles = guidata(object);

% load dialog box with file type
[dataFile, dataPath] = uigetfile('*.set', 'Please Select Sleep Data');

% just return if no datafile was actually selected
if dataFile == 0
    fprintf(1, 'Warning: No file selected \n');
    return;
end

% load the files
% ``````````````
% load the struct to the workspace
load([dataPath, dataFile], '-mat');
if ~exist('EEG', 'var')
    fprintf('Warning: No EEG structure found in file\n');
    return;
end

% memory map the actual data...
tmp = memmapfile([dataPath EEG.data],...
                'Format', {'single', [EEG.nbchan EEG.pnts EEG.trials], 'eegData'});
eegData = tmp.Data.eegData;

EEG = initialize_loaded_eeg(handles.fig, EEG, eegData);

% set the name
set(handles.fig, 'name', ['csc: ', dataFile]);

% use setappdata for data storage to avoid passing it around in handles when not necessary
setappdata(handles.fig, 'EEG', EEG);

% check for previously epoched data
if ndims(EEG.data) == 3
    % flatten the third dimension into the second
    eegData = reshape(EEG.data, size(EEG.data, 1), []);
    setappdata(handles.fig, 'eegData', eegData);
else
    setappdata(handles.fig, 'eegData', eegData);
end
    
% plot the initial data
update_main_plot(handles.fig);

% redraw event triangles if present
if isfield(EEG, 'csc_event_data')
    fcn_redraw_events(handles.fig, []);
end

function fcn_save_eeg(object, ~)
% get the handles from the figure
handles = guidata(object);

% get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% add the event table to the EEG struct
if isfield(handles, 'events')
    EEG.csc_event_data = fcn_compute_events(handles);
end

% Ask where to put file...
[saveFile, savePath] = uiputfile('*.set');

% since the data has not changed we can just save the EEG part, not the data
save(fullfile(savePath, saveFile), 'EEG', '-mat');

function update_main_plot(object, flag_replot)
% main function for plotting channels in main axis

% check input
if nargin < 2
    flag_replot = true;
end

% get the handles structure
handles = guidata(object);

% get the data
EEG = getappdata(handles.fig, 'EEG');

% select the plotting data
current_point = get(handles.cPoint, 'value');
range = current_point : ...
    current_point + handles.epoch_length * EEG.srate - 1;

% check for ica flag plot and get if there
if handles.plotICA == 1
    title(handles.main_ax, 'Component Activations', 'Color', 'w');
    icaData = getappdata(handles.fig, 'icaData');
    data_to_plot = icaData(EEG.csc_montage.channels(handles.disp_chans, 1), range);
else % normal plotting of activity
    title(handles.main_ax, 'Channel Activations', 'Color', 'w');
    eegData = getappdata(handles.fig, 'eegData');
    
    % check the reference type
    switch EEG.csc_montage.reference
        case 'inherent'
         
            % check for component projections
            if ~handles.component_projection
                
                % keep the reference inherent to how data was loaded
                data_to_plot = eegData(EEG.csc_montage.channels(handles.disp_chans, 1), range);
   
            elseif handles.component_projection
                % get the ica time series
                icaData = getappdata(handles.fig, 'icaData');
                
                % recalculate data based on projections
                projection_data = EEG.icawinv(:, EEG.good_components) ...
                    * icaData(EEG.good_components, range);
                
                % subselect displayed channels
                data_to_plot = projection_data(...
                    EEG.csc_montage.channels(handles.disp_chans, 1), :);
                
            end
                
        case 'custom'
            % use the reference stated in the montage
            data_to_plot = eegData(EEG.csc_montage.channels(handles.disp_chans, 1), range)...
                - eegData(EEG.csc_montage.channels(handles.disp_chans, 2), range);
            
        case 'average'
            % use the average activty of the channels in the montage
            % calculate the average activity
            mean_activity = mean(eegData(EEG.csc_montage.channels(:, 1), :), 1);
            data_to_plot = eegData(EEG.csc_montage.channels(handles.disp_chans, 1), range)...
                - ones(handles.n_disp_chans, 1) * mean_activity(:, range);
    end
    
    % add the scaling to the channels
    data_to_plot = data_to_plot .* ...
        [EEG.csc_montage.scaling(handles.disp_chans, 1) * ones(1, length(range))];
    
    % reverse data is negative up option is checked
    if handles.negative_up
        data_to_plot = data_to_plot * -1;
    end
end

% filter the data
% ~~~~~~~~~~~~~~~
% check for filter toggle and that ICA is not being plotted
if strcmp(get(handles.menu.filter_toggle, 'checked'), 'on') ...
        && handles.plotICA == 0
    
    % calculate and filter separately for each channel type
    for n = 1 : 4
        
        % which channels to apply this to
        channel_ind = handles.channel_types(handles.disp_chans) == n;
        
        % check if relevant
        if sum(channel_ind) == 0
            continue
        end
        
        % determine filtering parameters
        % check for empty boxes for one-sided filters
        if isnan(handles.filter_options(n, 2))
            
            [filt_param_b, filt_param_a] = butter(2, ...
                handles.filter_options(n, 1) / (EEG.srate / 2), 'high');
            
        elseif isnan(handles.filter_options(1))
            
            [filt_param_b, filt_param_a] = butter(2, ...
                handles.filter_options(n, 2) / (EEG.srate / 2), 'low');
        else
            [filt_param_b, filt_param_a] = ...
                butter(2,[handles.filter_options(n, 1)/(EEG.srate/2),...
                handles.filter_options(n, 2) / (EEG.srate / 2)]);
        end
        
        % apply the filter to the data window
        data_to_plot(channel_ind, :) = single(filtfilt(filt_param_b, filt_param_a, ...
            double(data_to_plot(channel_ind, :)'))');
    end
end


% define accurate spacing
scale = get(handles.txt_scale, 'value')*-1;
toAdd = [1:handles.n_disp_chans]'*scale;
toAdd = toAdd * ones(1, length(range));

% space out the data for the single plot
data_to_plot = data_to_plot + toAdd;

set([handles.main_ax, handles.name_ax],...
    'yLim', [scale 0] * (handles.n_disp_chans + 1 ))

% calculate the time in seconds
time = range/EEG.srate;
set(handles.main_ax, 'xlim', [time(1), time(end)]);
set(handles.ax_lower_event, 'xlim', [time(1), time(end)]);

% set main axis tick labels
if ~verLessThan('matlab', '8.4')
    main_ax_tick_times = seconds(get(handles.main_ax, 'XTick'));
    main_ax_tick_labels = cellstr(char(main_ax_tick_times, 'hh:mm:ss'));
    set(handles.main_ax, 'XTickLabels', main_ax_tick_labels);
end

% grid plotting
% ^^^^^^^^^^^^^
% plot vertical gridlines
if handles.plot_vgrid && ~isfield(handles, 'v_gridlines')
    % plot the line if wished and there wasn't one there already
    inttimes = time(~mod(time, handles.v_grid_spacing)); % find all integer times
    gridtimes = repmat(inttimes, 2, 1);
    ylims = get(handles.main_ax, 'ylim');
    gridlims = repmat(ylims, length(inttimes), 1)';
    handles.v_gridlines = line(gridtimes, gridlims,...
        'lineStyle',  ':',...
        'color',      handles.colorscheme.fg_col_3,...
        'parent',     handles.main_ax);
    
elseif handles.plot_vgrid && isfield(handles, 'v_gridlines')
    % just update the time if line is there
    inttimes = time(~mod(time, handles.v_grid_spacing)); % find all integer times
    gridtimes = repmat(inttimes, 2, 1);
    set(handles.v_gridlines, {'xdata'}, num2cell(gridtimes, 1)');
    
elseif ~handles.plot_vgrid && isfield(handles, 'v_gridlines')
    % get rid of the line if turned off
    delete(handles.v_gridlines);
    handles = rmfield(handles, 'v_gridlines');
end

% plot horizontal gridlines
if handles.plot_hgrid && ~isfield(handles, 'h_gridlines')
    % adjust the spacing based on scaling factors
    grid_spacing = [handles.h_grid_spacing/2 .* ...
        EEG.csc_montage.scaling(handles.disp_chans, 1)] * ones(1, length(range));
    grid_lines =  [toAdd - grid_spacing; toAdd + grid_spacing];
    % plot the lines
    handles.h_gridlines = line(time, grid_lines, ...
        'lineStyle',  '-.',...
        'color', handles.colorscheme.fg_col_3,...
        'parent', handles.main_ax);
    
elseif handles.plot_hgrid && isfield(handles, 'h_gridlines')
    % just update the time if line is there
    set(handles.h_gridlines, 'xdata', time);
    
elseif ~handles.plot_hgrid && isfield(handles, 'h_gridlines')
    % get rid of the line if turned off
    delete(handles.h_gridlines);
    handles = rmfield(handles, 'h_gridlines');
end


% plot the channel data
% ^^^^^^^^^^^^^^^^^^^^^
if flag_replot
    
    % delete existing handles and lines
    if isfield(handles, 'plot_eeg') 
        delete(handles.plot_eeg); 
        handles = rmfield(handles, 'plot_eeg');
    end
    
    % plot lines
    handles.plot_eeg = line(time, data_to_plot,...
        'color', handles.colorscheme.fg_col_1,...
        'parent', handles.main_ax);
    
    % Get indices of channels to hide
    hidden_idx = ismember(handles.disp_chans, handles.hidden_chans);
    % Now hide them
    set(handles.plot_eeg(hidden_idx), 'visible', 'off');
    
else
    % just change the data
    set(handles.plot_eeg, {'xdata'}, num2cell(time, 2));
    set(handles.plot_eeg, {'ydata'}, num2cell(data_to_plot, 2));
end


% plot the labels in their own boxes
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
if flag_replot
    % delete existing handles
    if isfield(handles, 'labels')
        delete(handles.labels);
        handles = rmfield(handles, 'labels');
    end
    handles.labels = zeros(handles.n_disp_chans, 1);
    % loop for each label
    for n = 1 : handles.n_disp_chans
        chn = handles.disp_chans(n);
        handles.labels(n) = ...
            text(0.25, toAdd(n, 1) + scale / 5, EEG.csc_montage.label_channels{chn},...
            'parent', handles.name_ax,...
            'fontsize',   12,...
            'fontweight', 'bold',...
            'color', handles.colorscheme.fg_col_2,...
            'backgroundcolor', handles.colorscheme.bg_col_2,...
            'horizontalAlignment', 'center',...
            'userdata', 1, ...
            'buttondownfcn', {@fcn_toggle_channel});
    end
end
                    
% change the x limits of the indicator plot
set(handles.spike_ax, 'xlim', [0, EEG.pnts * EEG.trials]);

% set indicator plot tick labels
if ~verLessThan('matlab', '8.4')
    spike_ax_tick_samples = get(handles.spike_ax, 'XTick');
    spike_ax_tick_times = seconds(spike_ax_tick_samples / EEG.srate);
    spike_ax_tick_labels = cellstr(char(spike_ax_tick_times, 'hh:mm:ss'));
    set(handles.spike_ax, 'XTickLabels', spike_ax_tick_labels);
end

% add indicator line to lower plot
if ~isfield(handles, 'indicator')
    handles.indicator = line([range(1), range(1)], [0, handles.number_of_event_types], ...
        'color', handles.colorscheme.fg_col_2,...
        'linewidth', 4,...
        'parent', handles.spike_ax,...
        'hittest', 'off');
else
    set(handles.indicator, 'xdata', [range(1), range(1)]);
end
                    
% set the new parameters
guidata(handles.fig, handles);
setappdata(handles.fig, 'EEG', EEG);

function fcn_change_time(object, ~)
% get the handles from the guidata
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% calculate number of samples
number_samples = EEG.pnts * EEG.trials;

current_point = get(handles.cPoint, 'value');
if current_point < 1
    fprintf(1, 'This is the first sample \n');
    set(handles.cPoint, 'value', 1);
elseif current_point > number_samples - handles.epoch_length * EEG.srate
    fprintf(1, 'No more data \n');
    set(handles.cPoint,...
        'value', number_samples - handles.epoch_length * EEG.srate );
end
current_point = get(handles.cPoint, 'value');

% update the hypnogram indicator line
set(handles.indicator, 'Xdata', [current_point, current_point]);

% update the GUI handles
guidata(handles.fig, handles)
setappdata(handles.fig, 'EEG', EEG);

% update all the axes
update_main_plot(handles.fig, false);

function fcn_toggle_channel(object, ~)
% get the handles from the guidata
handles = guidata(object);

% find which of the n_disp_chans possible plot lines the selected channel is
label_number = find(handles.labels == object);
% find which channel this corresponds to
channel_id = handles.disp_chans(label_number);

% get its current state ('on' or 'off')
state = get(handles.plot_eeg(label_number), 'visible');

switch state
    case 'on'
        % check the color
        if any(get(handles.plot_eeg(label_number), 'color') == handles.colorscheme.fg_col_1)
            % if same color then change the color
            set(handles.plot_eeg(label_number), 'Color', [0.16, 0.36, 0.60]);
        else
            % if a different color then change back but turn off
            set(handles.plot_eeg(label_number), 'visible', 'off');
            set(handles.plot_eeg(label_number), 'color', handles.colorscheme.fg_col_1);
            handles.hidden_chans = [handles.hidden_chans channel_id]; % save state
        end
        
    case 'off'
      set(handles.plot_eeg(label_number), 'visible', 'on');
      handles.hidden_chans = handles.hidden_chans(handles.hidden_chans ~= channel_id);
end
guidata(object, handles);

function fcn_time_select(object, ~)
handles = guidata(object);

% get position of click
clicked_position = get(handles.spike_ax, 'currentPoint');

% if scoring mode is enabled align to scoring trace
if handles.scoring_mode
    % Get the EEG from the figure's appdata
    EEG = getappdata(handles.fig, 'EEG');
    
    % get events
    event_data = fcn_compute_events(handles);
    
    % convert to ms
    position_in_seconds = floor(clicked_position(1)/EEG.srate);
    
    % compare click position to event data
    [distance, closest_event] = min(abs(cell2mat(event_data(:, 2)) - position_in_seconds));
    
    % if clicked too far away just ignore the adjustment
    if abs(distance) < 200
        clicked_position(1, 1) = event_data{closest_event, 2} * EEG.srate; 
    end
end

% set the current point accordingly
set(handles.cPoint, 'Value', floor(clicked_position(1,1)));

% update the plots using the change time function
fcn_change_time(object, []);

function EEG = initialize_loaded_eeg(object, EEG, eegData)

handles = guidata(object);

% check for the channel locations
if isempty(EEG.chanlocs)
    if isempty(EEG.urchanlocs)
        fprintf(1, 'Warning: No channel locations found in the eegMeta structure \n');
    else
        fprintf(1, 'Information: Taking the EEG.urchanlocs as the channel locations \n');
        EEG.chanlocs = EEG.urchanlocs;
    end
end

% check for obvious change in the data
if isfield(EEG, 'csc_montage')
    if max(EEG.csc_montage.channels(:)) > EEG.nbchan ...
            || (strcmp(EEG.csc_montage.name, 'original')...
            && size(EEG.csc_montage.channels, 1) ~= EEG.nbchan)
        fprintf(1, 'Warning: Montage does not match data; resetting montage | Note that events may no longer be accurate \n');
        % delete the fields
        EEG = rmfield(EEG, 'csc_montage');
    end
end

if isfield(EEG, 'csc_event_data') && ~isempty(EEG.csc_event_data)
    % check for later event than the length of the data
    if max([EEG.csc_event_data{:, 2}]) > EEG.xmax
        % delete the field
        EEG = rmfield(EEG, 'csc_event_data');
        fprintf(1, 'Warning: Events not in range, resetting events \n'); 
    end
end

% check for previous
if ~isfield(EEG, 'csc_montage')
    % assign defaults
    EEG.csc_montage.name = 'original';
    EEG.csc_montage.label_channels = cell(EEG.nbchan, 1);
    for n = 1 : EEG.nbchan
        EEG.csc_montage.label_channels(n) = {num2str(n)};
        EEG.csc_montage.channel_type(n) = {'EEG'};
    end
    EEG.csc_montage.channels(:, 1) = 1:EEG.nbchan;
    EEG.csc_montage.channels(:, 2) = EEG.nbchan;
    EEG.csc_montage.scaling(:, 1) = ones(EEG.nbchan, 1);
    EEG.csc_montage.reference = 'inherent';
else
    % restore hidden channels
    if isfield(EEG, 'hidden_channels')
        handles.hidden_chans = EEG.hidden_channels;
    end
end

% check for scaling for backwards compatibility with old montages
if ~isfield(EEG.csc_montage, 'scaling')
    EEG.csc_montage.reference = 'inherent';
    EEG.csc_montage.scaling(:, 1) = ones(EEG.nbchan, 1);
end

% check for channel type for backwards compatibility with old montages
if ~isfield(EEG.csc_montage, 'channel_type')
    for n = 1 : length(EEG.csc_montage.label_channels)
        EEG.csc_montage.channel_type{n, 1} = 'EEG';
    end
end

% recalculate channel types
handles.channel_types = ones(length(EEG.csc_montage.channel_type), 1);
channel_types = {'EEG', 'EMG', 'EOG', 'Other'};
for n = 1 : 4
    type_ind = cellfun(@(x) strcmp(x, channel_types{n}), EEG.csc_montage.channel_type);
    handles.channel_types(type_ind) = n;
end
             
% check that the montage has enough channels to display
if length(EEG.csc_montage.label_channels) < handles.n_disp_chans
    handles.n_disp_chans = length(EEG.csc_montage.label_channels);
    handles.disp_chans = [1 : handles.n_disp_chans];
    fprintf(1, 'Warning: reduced number of display channels to match montage\n');
end

% load ICA time courses if the information need to construct them is available.
if isfield(EEG, 'icaweights') && isfield(EEG, 'icasphere')
    if ~isempty(EEG.icaweights) && ~isempty(EEG.icasphere)
        % re-calculate the ICA activations
        ica_data = (EEG.icaweights * EEG.icasphere) ...
            * EEG.data(EEG.icachansind, :);
        
        % pad the remaining data in case not equal size
        if ~[size(EEG.icaweights, 1) == size(eegData, 1)]
            dimdiff = size(eegData, 1) - size(EEG.icaweights, 1);
            pad = zeros(dimdiff, size(eegData, 2));
            
            % add to ica activations
            ica_data = [ica_data; pad];
            
        end
        
        % save the ica data to the handles structure
        setappdata(handles.fig, 'icaData', ica_data);
        
        % check for a "good_components" field
        if ~isfield(EEG, 'good_components')
            EEG.good_components = true(size(EEG.icaweights, 1), 1);
        end
        
    end
end

% adjust initially scaling to match the data
channel_variance = nanstd(eegData(1, :));
set(handles.txt_scale, 'value', channel_variance * 3);

% check the data length
if EEG.pnts / EEG.srate < handles.epoch_length
    handles.epoch_length = floor(EEG.pnts / EEG.srate);
end

% look for already hidden channels
if isfield(EEG, 'hidden_channels')
    handles.hidden_channels = EEG.hidden_channels;
end

% look for bad trials
if isfield(EEG, 'marked_trials')
    handles.trials = EEG.marked_trials;
else
    % allocate marked trials
    handles.trials = false(EEG.trials, 1);
end

% turn on the montage option
set(handles.menu.montage, 'enable', 'on');

% update the handles
guidata(object, handles);

function fcn_close_window(object, ~)
% just resume the ui if the figure is closed
handles = guidata(object);

% get current figure status
current_status = get(handles.fig, 'waitstatus');

if isempty(current_status)
    % close the figure
    delete(handles.fig);
    return;
end

switch current_status
    case 'waiting'
        uiresume;
    otherwise
        % close the figure
        delete(handles.fig);
end


% Event Functions
% ^^^^^^^^^^^^^^^
function fcn_event_browser(object, ~)
% get the handles
handles.csc_plotter = guidata(object);

% check if any events exist
if ~isfield(handles.csc_plotter, 'events')
    fprintf(1, 'Warning: No events were found in the data \n');
    return
end

handles.fig = figure(...
    'name',         'csc event browser',...
    'numberTitle',  'off',...
    'color',        handles.csc_plotter.colorscheme.bg_col_1,...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.5 0.2 0.5]);

% montage table
handles.table = uitable(...
    'parent',       handles.fig             ,...
    'units',        'normalized'            ,...
    'position',     [0.05, 0.30, 0.9, 0.65]   ,...
    'backgroundcolor', handles.csc_plotter.colorscheme.bg_col_2 ,...
    'foregroundcolor', handles.csc_plotter.colorscheme.fg_col_1 ,...
    'columnName',   {'label','time', 'type'});

% clear events
handles.clear_button = uicontrol(...
    'Parent',   handles.fig ,...
    'Style',    'pushbutton' ,...
    'String',   'clear event(s)' ,...
    'Units',    'normalized' ,...
    'Position', [0.05 0.20 0.9 0.04],...
    'FontName', 'Century Gothic' ,...
    'FontSize', 11,...
    'tooltipString', 'delete above selected events');
set(handles.clear_button, 'callback', {@pb_event_option, 'clear'});

% import events
handles.import_button = uicontrol(...
    'Parent',   handles.fig ,...
    'Style',    'pushbutton' ,...
    'String',   'import events' ,...
    'Units',    'normalized' ,...
    'Position', [0.05 0.15 0.9 0.04] ,...
    'FontName', 'Century Gothic',...
    'FontSize', 11 ,...
    'tooltipString', 'import events' ,...
    'enable', 'on');
set(handles.import_button, 'callback', {@pb_event_option, 'import'});

% export to workspace
handles.export_button = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'pushbutton',...
    'String',   'export to workspace',...
    'Units',    'normalized',...
    'Position', [0.05 0.10 0.9 0.04],...
    'FontName', 'Century Gothic',...
    'FontSize', 11,...
    'tooltipString', 'export to workspace');
set(handles.export_button, 'callback', {@pb_event_option, 'export'});

% export to file
handles.save_button = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'pushbutton',...
    'String',   'save to file',...
    'Units',    'normalized',...
    'Position', [0.05 0.05 0.9 0.04],...
    'FontName', 'Century Gothic',...
    'FontSize', 11,...
    'tooltipString', 'export to file');
set(handles.save_button, 'callback', {@pb_event_option, 'save'});

% get the underlying java properties
jscroll = findjobj(handles.table);
jscroll.setVerticalScrollBarPolicy(jscroll.java.VERTICAL_SCROLLBAR_ALWAYS);

% make the table sortable
% get the java table from the jscroll
jtable = jscroll.getViewport.getView;
jtable.setSortable(true);
jtable.setMultiColumnSortable(true);

% auto-adjust the column width
jtable.setAutoResizeMode(jtable.AUTO_RESIZE_ALL_COLUMNS);

% set the callback for table cell selection
set(handles.table, 'cellSelectionCallback', {@cb_select_table});

% calculate the event_data from the handles
event_data = fcn_compute_events(handles.csc_plotter);

% put the data into the table
set(handles.table, 'data', event_data);

% update the GUI handles
guidata(handles.fig, handles)

function event_data = fcn_compute_events(handles, ~)
% function used to create the event_table from the handle structure

% pull out the events from the handles structure
events = handles.events;

% calculate the number of events
no_events = size(events, 1);

% check for no events
if no_events == 0
    event_data = [];
    return
end

% pre-allocate the event data
event_data = cell(sum(no_events), 3);

% insert latencies and event type
if size(events, 1) == 1
    % single handles return a double not a cell
    event_data(:, 2) = {get(events(:,1), 'xdata')};
    event_data(:, 3) = {get(events(:,1), 'userData')};
else
    event_data(:, 2) = get(events(:,1), 'xdata');
    event_data(:, 3) = get(events(:,1), 'userData');
end

% insert event labels
% NOTE: no one ever changes the event labels from default so this might be deletable
all_labels = get(handles.selection.item, 'label');
event_data(:, 1) = {all_labels{[event_data{:, 3}]}};

% sort the events by latency
[~, sort_ind] = sort([event_data{:, 2}]);
event_data = event_data(sort_ind, :);

function cb_select_table(object, event_data)
% when a cell in the table is selected, jump to that time point

% if cell selection was called without selecting
if isempty(event_data.Indices)
    return
end

% if the event column was selected return
if event_data.Indices(2) == 1 || isempty(event_data.Indices)
    return
end


% get the handles
handles = guidata(object);

% get the data
EEG = getappdata(handles.csc_plotter.fig, 'EEG');

% return the data from the table
table_data = get(object, 'data');

% retrieve the time from the table
selected_time = table_data{event_data.Indices(1), 2};
go_to_time = selected_time - handles.csc_plotter.epoch_length / 2;
selected_sample = floor(go_to_time * EEG.srate);

% change the hidden time keeper
set(handles.csc_plotter.cPoint, 'Value', selected_sample);

% update the time in the plotter window
fcn_change_time(handles.csc_plotter.fig, []);

function cb_event_selection(object, ~, event_type, current_point)
% TODO: small box at the top to indicate the last marker event

% get the handles
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% get the default color order for the axes
event_colors = get(handles.main_ax, 'ColorOrder');

% check if its the first item
if ~isfield(handles, 'events')
   handles.events = [];
end

% check if event latency is pre-specified
if nargin < 4
    current_point = get(handles.main_ax, 'currentPoint');
end

% mark the main axes
% ~~~~~~~~~~~~~~~~~~
x = current_point(1);
y = get(handles.main_ax, 'ylim');

% draw bottom triangle
handles.events(end+1, 1) = plot(x, 0,...
    'lineStyle', 'none',...
    'marker', '^',...
    'markerSize', 20,...
    'markerEdgeColor', [0.9, 0.9, 0.9],...
    'markerFaceColor', event_colors(event_type, :),...
    'userData', event_type,...
    'parent', handles.ax_lower_event,...
    'buttonDownFcn', {@bdf_delete_event});

% draw top triangle
handles.events(end, 2) = plot(x, y(2),...
    'lineStyle', 'none',...
    'marker', 'v',...
    'markerSize', 20,...
    'markerEdgeColor', [0.9, 0.9, 0.9],...
    'markerFaceColor', event_colors(event_type, :),...
    'userData', event_type,...
    'parent', handles.main_ax,...
    'buttonDownFcn', {@bdf_delete_event});

% mark the spike axes
% ~~~~~~~~~~~~~~~~~~~
% translate the current x point into the event axes
sample_point = floor(x * EEG.srate);

handles.events(end, 3) = line([sample_point, sample_point], ...
    [event_type - 1, event_type], ...
    'color', event_colors(event_type, :),...
    'parent', handles.spike_ax,...
    'userData', event_type,...
    'hitTest', 'off');

% update the GUI handles
guidata(handles.fig, handles)

function bdf_delete_event(object, ~)
% get the handles
handles = guidata(object);

% calculate the event number (which row is the object handle in)
event_number = any(object == handles.events, 2);

% erase the object from the main and spike axes
delete(handles.events(event_number, :));

% erase the event from the list
handles.events(event_number, :) = [];

% update the GUI handles
guidata(handles.fig, handles)

function fcn_redraw_events(object, ~)
% function to erase all events and redraw their markers based on the
% csc_event_data array in the EEG structure

% get the handles
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% check for current events and delete their handles
if isfield(handles, 'events')
    % delete all the event handles
    delete(handles.events);
    % reset handle structure structure
    handles.events = [];
end

% update the GUI handles
guidata(handles.fig, handles)

% loop through each event
for n = 1 : size(EEG.csc_event_data, 1)
    cb_event_selection(object, [], EEG.csc_event_data{n, 3}, EEG.csc_event_data{n, 2})
end

function fcn_plot_trial_borders(object, ~)
% function to plot the borders of trials for epoched data

% get the handles
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% check for epoched data
if EEG.trials == 1
    return;
end

% get the trial starts in concatenated samples
x = (1 : EEG.pnts : EEG.pnts * EEG.trials) / EEG.srate;

% draw bottom arrow
handles.trial_borders = plot(x, 0,...
    'lineStyle', 'none',...
    'marker', '>',...
    'markerSize', 20,...
    'markerEdgeColor', [0.9, 0.9, 0.9],...
    'markerFaceColor', [0.6, 0.6, 0.6],...
    'parent', handles.ax_lower_event,...
    'buttonDownFcn', {@bdf_mark_trial});

% set previously marked trials color
set(handles.trial_borders(handles.trials), 'markerFaceColor', [0.9, 0.2, 0.2]);

% update the GUI handles
guidata(handles.fig, handles)

function bdf_mark_trial(object, ~)
% get the handles
handles = guidata(object);

% calculate the trial number
trial_number = find(object == handles.trial_borders);

if ~handles.trials(trial_number)
    handles.trials(trial_number) = true;
    set(object, 'markerFaceColor', [0.9, 0.2, 0.2]);
else
    handles.trials(trial_number) = false;
    set(object, 'markerFaceColor', [0.6, 0.6, 0.6]);
end

% update the GUI handles
guidata(handles.fig, handles)

function pb_event_option(object, ~, option)
% get the handles
handles = guidata(object);

switch option
    case 'clear'
        % find the row indices to delete
        jscroll = findjobj(handles.table);
        del_ind = jscroll.getComponent(0).getComponent(0).getSelectedRows+1;
        
        % get the table, delete the rows and reset the table
        event_data = get(handles.table, 'data');
        event_data(del_ind, :) = [];
        set(handles.table, 'data', event_data);
        
        % put the new table into the structure
        % Get the EEG from the figure's appdata
        EEG = getappdata(handles.csc_plotter.fig, 'EEG');
        EEG.csc_event_data = event_data;
        setappdata(handles.csc_plotter.fig, 'EEG', EEG);
        
        % re-draw the event window in main
        fcn_redraw_events(handles.csc_plotter.fig, []);
        
    case 'import'
        % load an event file
        [file_name, file_path] = uigetfile('*.mat');
        loaded_event_file = load(fullfile(file_path, file_name));
        
        if isfield(loaded_event_file, 'event_data')
            set(handles.table, 'data', loaded_event_file.event_data);
            
            % put the new table into the structure
            % Get the EEG from the figure's appdata
            EEG = getappdata(handles.csc_plotter.fig, 'EEG');
            EEG.csc_event_data = loaded_event_file.event_data;
            setappdata(handles.csc_plotter.fig, 'EEG', EEG);
            
            % re-draw the event window in main
            fcn_redraw_events(handles.csc_plotter.fig, []);
            
        else
            % TODO: event error message
        end
        
    case 'export'
        % assign events to base workspace
        event_data = fcn_compute_events(handles.csc_plotter);
        assignin('base', 'event_data', event_data);
        
    case 'save'
        % save the events as a file
        event_data = fcn_compute_events(handles.csc_plotter);

        % Ask where to put file...
        [saveFile, savePath] = uiputfile('*.mat');
        save(fullfile(savePath, saveFile), 'event_data', '-mat');
        
end


% Options Menu and their Keyboard Shortcuts
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function fcn_options(object, ~, type)
% get the handles
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

switch type
    case 'disp_chans'
     
        % No answer, no change
        answer = inputdlg('channels to display (number or range)','', 1);

        % if no input, do nothing
        if isempty(answer) || strcmp(answer{1}, '')
          return
        end

        answer = strsplit(answer{1}, ':'); 

        if length(answer) > 2 %for example '1:2:5' was provided as input
          fprintf(1, 'Warning: You did not select a valid channel range. Doing nothing.\n');
          return
        end

        if length(answer) == 1 %if a number was provided
          % if more channels were requested than exist in the montage, take the number in the montage
          handles.n_disp_chans = min(str2double(answer{1}),...
                                     length(EEG.csc_montage.label_channels)); 
          handles.disp_chans = [1 : handles.n_disp_chans];
          
        else %length(answer) == 2, so a range was provided
          disp_chans = [str2double(answer{1}) : str2double(answer{2})];
          
          if isempty(disp_chans) %if bogus input like '99:12' was provided
            fprintf(1, 'Warning: You did not select a valid channel range. Doing nothing\n');
            return
          else %input was good
            handles.disp_chans = disp_chans;
            handles.n_disp_chans = length(handles.disp_chans);
          end
        end
        
        % replot the grid
        if handles.plot_vgrid
            delete(handles.v_gridlines);
            handles = rmfield(handles, 'v_gridlines');
        end
        if handles.plot_hgrid
            delete(handles.h_gridlines);
            handles = rmfield(handles, 'h_gridlines');
        end
        
        % update the handles
        guidata(object, handles);
        update_main_plot(object)
               
    case 'epoch_length'
        
        answer = inputdlg('length of epoch',...
            '', 1, {num2str( handles.epoch_length )});
        
        % if different from previous
        if ~isempty(answer)
            newNumber = str2double(answer{1});
            if newNumber ~= handles.epoch_length
                handles.epoch_length = newNumber;
                
                % replot the grid
                if handles.plot_vgrid
                    delete(handles.v_gridlines);
                    handles = rmfield(handles, 'v_gridlines');
                end
                if handles.plot_hgrid
                    delete(handles.h_gridlines);
                    handles = rmfield(handles, 'h_gridlines');
                end
                
                guidata(object, handles);
                update_main_plot(object)
            end
        end
           
    case 'color_scheme'
        % get the current scheme
        if  handles.colorscheme.bg_col_1 == [0.1, 0.1, 0.1]
            % its the dark scheme so change to light
            handles.colorscheme = struct(...
                'fg_col_1',     [0.1, 0.1, 0.1] , ...
                'fg_col_2',     [0.2, 0.2, 0.2] , ...
                'fg_col_3',     [0.5, 0.5, 0.5] , ...
                'bg_col_1',     [0.95, 0.95, 0.95] , ...
                'bg_col_2',     [1, 1, 1] , ...
                'bg_col_3',     [0.85, 0.85, 0.85] );
                           
        else
            % its the light scheme so change to dark
            handles.colorscheme = struct(...
                'fg_col_1',     [0.9, 0.9, 0.9] , ...
                'fg_col_2',     [0.8, 0.8, 0.8] , ...
                'fg_col_3',     [0.5, 0.5, 0.5] , ...
                'bg_col_1',     [0.1, 0.1, 0.1] , ...
                'bg_col_2',     [0.2, 0.2, 0.2] , ...
                'bg_col_3',     [0.15, 0.15, 0.15] );
        end
        
        % change figure and axes
        set(handles.fig, 'color', handles.colorscheme.bg_col_1);
        set([handles.main_ax, handles.spike_ax], ...
            'color', handles.colorscheme.bg_col_2 ,...
            'xcolor', handles.colorscheme.fg_col_1 ,...
            'ycolor', handles.colorscheme.fg_col_1 );
        
        % update the axes
        guidata(object, handles);
        update_main_plot(object)

    case 'vgrid_spacing'
        
        % display dialogue box
        answer = inputdlg({'grid spacing (s)'} , ...
            '', 1, {num2str( handles.v_grid_spacing )});
        
        % check for cancelled window
        if isempty(answer); return; end
        
        % replot the grid
        if handles.plot_vgrid
            delete(handles.v_gridlines);
            handles = rmfield(handles, 'v_gridlines');
        end
        
        % set answer
        handles.v_grid_spacing = round(str2double(answer));
        guidata(object, handles);
        update_main_plot(object);
        
    case 'hgrid_spacing'
        
        % display dialogue box
        answer = inputdlg({'grid spacing (uV)'} , ...
            '', 1, {num2str( handles.h_grid_spacing )});
        
        % check for cancelled window
        if isempty(answer); return; end
        
        % replot the grid
        if handles.plot_hgrid
            delete(handles.h_gridlines);
            handles = rmfield(handles, 'h_gridlines');
        end
        
        % set answer
        handles.h_grid_spacing = round(str2double(answer));
        guidata(object, handles);
        update_main_plot(object);
        
    case 'negative_toggle'
        % apply online filter to the data or not
        switch get(handles.menu.negative_toggle, 'checked')
            case 'on'
                set(handles.menu.negative_toggle, 'checked', 'off');
                handles.negative_up = false;
            case 'off'
                set(handles.menu.negative_toggle, 'checked', 'on');
                handles.negative_up = true;
        end
        
        % replot
        guidata(object, handles);
        update_main_plot(object);
        
    case 'filter_toggle'
        % apply online filter to the data or not
        switch get(handles.menu.filter_toggle, 'checked')
            case 'on'
                set(handles.menu.filter_toggle, 'checked', 'off');
            case 'off'
                set(handles.menu.filter_toggle, 'checked', 'on');
        end
        
        % replot
        guidata(object, handles);
        update_main_plot(object);
        
    case 'filter_settings'
        
        answer = inputdlg({'low cut-off', 'high cut-off'},...
            '', 1, {num2str( handles.filter_options(1)),...
                    num2str( handles.filter_options(2))});
        
        % check for cancelled window        
        if isempty(answer); return; end

                
        % get and set the new values
        new_values = str2double(answer);
        if ~isequal(new_values, handles.filter_options')
            handles.filter_options = new_values;
            guidata(object, handles);
            update_main_plot(object);
        end
    
    case 'icatoggle'
        % apply online filter to the data or not
        switch get(handles.menu.icatoggle, 'checked')
            case 'on'
                set(handles.menu.icatoggle, 'checked', 'off');
                handles.plotICA = false;
            case 'off'
                set(handles.menu.icatoggle, 'checked', 'on');
                handles.plotICA = true;
        end
        
        % replot
        guidata(object, handles);
        update_main_plot(object);
               
    case 'export_hidden_chans'
        % export the hidden channels
        var_name = inputdlg('Workspace variable to export to?',...
            '', 1, {'hidden_channels'});
        var_name = var_name{1} % *sigh*
        eval_str = sprintf('exist(''%s'')', var_name); % will check if var exists
        if(evalin('base', eval_str)) % If variable already exists
            warning_msg = ['A variable with thise name already exists in your '...
                'workspace. Are you sure you want to overwrite it?'];
            answer = questdlg(warning_msg);
            if ~strcmp(answer, 'Yes')
                return
            end
        end
        labels = EEG.csc_montage.label_channels(handles.hidden_chans);
        refs = EEG.csc_montage.channels(handles.hidden_chans, :);
        refs = mat2cell(refs, ones(length(handles.hidden_chans), 1), ones(2, 1));
        selected_channels = [labels refs];
        assignin('base', var_name, selected_channels);
        
    case 'export_marked_trials'
        % export the marked trials
        var_name = inputdlg('Workspace variable to export to?',...
            '', 1, {'marked_trials'});
        var_name = var_name{1} % *sigh*
        eval_str = sprintf('exist(''%s'')', var_name); % will check if var exists
        if(evalin('base', eval_str)) % If variable already exists
            warning_msg = ['A variable with thise name already exists in your '...
                'workspace. Are you sure you want to overwrite it?'];
            answer = questdlg(warning_msg);
            if ~strcmp(answer, 'Yes')
                return
            end
        end
        assignin('base', var_name, handles.trials);

    case 'export_axes'
        
        % open a new figure
        new_handle = figure('color', handles.colorscheme.bg_col_1);
        
        % copy the main ax
        copyobj(handles.main_ax, new_handle);
        delete(findobj(gca, 'type', 'line', '-and', 'markersize', 20));
        
        if exist('plot2svg')
            plot2svg('eeg_plotter_svg.svg', new_handle);
        else
            saveas(new_handle, 'eeg_plotter_svg.svg', 'svg');
        end
        
    case 'scoring_mode'
        % scoring mode toggle (numbered events indicate sleep stage)
        switch get(handles.menu.scoring_toggle, 'checked')
            case 'on'
                set(handles.menu.scoring_toggle, 'checked', 'off');
                handles.scoring_mode = false;
            case 'off'
                set(handles.menu.scoring_toggle, 'checked', 'on');
                handles.scoring_mode = true;
        end      
        guidata(object, handles);
end

function cb_key_pressed(object, event)
% get the relevant data
handles = guidata(object);
EEG = getappdata(handles.fig, 'EEG');

% movement keys
if isempty(event.Modifier)
    switch event.Key
        case 'leftarrow'
            % move to the previous epoch
            set(handles.cPoint, 'Value',...
                get(handles.cPoint, 'Value') - handles.epoch_length*EEG.srate);
            fcn_change_time(object, [])
            
        case 'rightarrow'
            % move to the next epoch
            set(handles.cPoint, 'Value',...
                get(handles.cPoint, 'Value') + handles.epoch_length*EEG.srate);
            fcn_change_time(object, [])
            
        case 'uparrow'
            scale = get(handles.txt_scale, 'value');
            % adjust by 30%
            value = scale / 1.3;
            set(handles.txt_scale, 'value', value);
            
            % replot the grid (easier like this because new scale only calculated during plot later)
            if handles.plot_hgrid
                delete(handles.h_gridlines);
                handles = rmfield(handles, 'h_gridlines');
                guidata(object, handles);
            end
           
            % adjust vertical grid position
            if handles.plot_vgrid
                % get new bottom Y
                y_lim = [value 0] * -(handles.n_disp_chans + 1 );
               set(handles.v_gridlines, 'ydata', y_lim); 
            end
            
            set(handles.txt_scale, 'string', get(handles.txt_scale, 'value'));
            set(handles.main_ax, 'yLim', [get(handles.txt_scale, 'value')*-1, 0]*(handles.n_disp_chans+1))
            update_main_plot(object)
                       
        case 'downarrow'
            scale = get(handles.txt_scale, 'value');
            % adjust by 30%
            value = scale * 1.3;
            set(handles.txt_scale, 'value', value);
            
            % replot the grid
            if handles.plot_hgrid
                delete(handles.h_gridlines);
                handles = rmfield(handles, 'h_gridlines');
                guidata(object, handles);
            end
            
             % adjust vertical grid position
            if handles.plot_vgrid
                % get new bottom Y
                y_lim = [value 0] * -(handles.n_disp_chans + 1 );
               set(handles.v_gridlines, 'ydata', y_lim); 
            end
            
            set(handles.txt_scale, 'string', get(handles.txt_scale, 'value'));
            set(handles.main_ax, 'yLim', [get(handles.txt_scale, 'value')*-1, 0]*(handles.n_disp_chans+1))
            update_main_plot(object)
            
        case 'pageup'
            
            top_channel = handles.disp_chans(1);
            
            if top_channel -  handles.n_disp_chans < 1
                handles.disp_chans = 1 : handles.n_disp_chans;
            else
                handles.disp_chans = top_channel - handles.n_disp_chans : top_channel - 1;
            end
            
            % redraw the plot by calling the scroll callback
            guidata(object, handles);
            update_main_plot(object);

        case 'pagedown'
            
            bottom_channel = handles.disp_chans(end);
            
            if bottom_channel +  handles.n_disp_chans - 1 > size(EEG.csc_montage.channels, 1)
                handles.disp_chans = size(EEG.csc_montage.channels, 1) -  handles.n_disp_chans + 1 : size(EEG.csc_montage.channels, 1);
            else
                handles.disp_chans = bottom_channel + 1 : bottom_channel + handles.n_disp_chans;
            end
                        
            % redraw the plot by calling the scroll callback
            guidata(object, handles);
            update_main_plot(object);
            
        case 'g'
          handles.plot_vgrid = ~handles.plot_vgrid;
          guidata(object, handles);
          update_main_plot(object);
          
        case 'h'
            handles.plot_hgrid = ~handles.plot_hgrid;
            guidata(object, handles);
            update_main_plot(object);
            
        otherwise
            % is the key a valid event key?
            if any(strcmp(handles.valid_event_keys, event.Character))
                % check if in scoring mode
                if ~handles.scoring_mode
                    % force update the currentPoint property by using any callback
                    set(handles.fig, 'WindowButtonMotionFcn', 'x=1;');
                    current_point = get(handles.main_ax, 'currentPoint');
                    
                    % check if current mouse point is within visible window
                    axes_x_lim = get(handles.main_ax, 'xlim');
                    if current_point(1) < axes_x_lim(1)
                        current_point = axes_x_lim(1);
                    elseif current_point(1) > axes_x_lim(2)
                        current_point = axes_x_lim(2);
                    end
                        
                    % create an event where the mouse cursor is
                    cb_event_selection(object, [], str2double(event.Character), current_point);
                else
                    % get the window position
                    if verLessThan('matlab', '8.4')
                        tmp_limits = get(handles.main_ax, 'xlim');
                        current_point = floor(tmp_limits(1));
                    else
                        current_point = floor(handles.main_ax.XLim(1));
                    end
                    
                    % check for existing event
                    event_type = str2double(event.Character);
                    
                    % check if its the first item
                    if ~isfield(handles, 'events')
                        event_latencies = [];
                    elseif size(handles.events, 1) == 1
                        % if there is only 1 event doesn't return a cell
                        event_latencies = floor(get(handles.events(:, 1), 'xdata'));
                    else
                        event_latencies = floor(cell2mat(get(handles.events(:, 1), 'xdata')));
                    end
                    
                    if any(event_latencies == [current_point + handles.scoring_offset])
                        % replace that event with new label
                        event_number = ...
                            find(event_latencies == [current_point + handles.scoring_offset]);
                        
                        % get color scheme
                        event_colors = get(handles.main_ax, 'ColorOrder');
                        
                        % change color and user data
                        set(handles.events(event_number, :), 'markerFaceColor', ...
                            event_colors(event_type, :));
                        
                        set(handles.events(event_number, :), 'userData', ...
                            event_type);
                        
                        % change location of marker on lower plot
                        set(handles.events(event_number, 3), 'ydata', ...
                            [event_type - 1, event_type]);
                        set(handles.events(event_number, 3), 'color', ...
                            event_colors(event_type, :));
                        
                    else
                        % new event
                        % set the appropriate marker at the start of the window
                        cb_event_selection(object, [],...
                            str2double(event.Character), ...
                            current_point + handles.scoring_offset);
                    end

                    % go to next window
                    set(handles.cPoint, 'value', ...
                        floor([current_point + handles.scoring_window] * EEG.srate));
                    
                    fcn_change_time(object, [])
                end
            end
    end

% check whether the ctrl is pressed also
elseif any(strcmp(event.Modifier, {'control', 'alt'}))
    
    switch event.Key
        case 'c'
            %TODO: pop_up for channel number
            
        case 'uparrow'
            %             fprintf(1, 'more channels \n');
            
        case 'leftarrow'
            % move a little to the left
            set(handles.cPoint, 'Value',...
                get(handles.cPoint, 'Value') ...
                - handles.epoch_length/3 * EEG.srate);
            fcn_change_time(object, [])
            
        case 'rightarrow'
            % move a little to the right
            set(handles.cPoint, 'Value',...
                get(handles.cPoint, 'Value') ...
                + handles.epoch_length/3 * EEG.srate);
            fcn_change_time(object, [])
            
        case 'pageup'
            
            top_channel = handles.disp_chans(1);
            
            if top_channel ~= 1
                handles.disp_chans = handles.disp_chans - 1;
            end
            
            % redraw the plot by calling the scroll callback
            guidata(object, handles);
            update_main_plot(object);
            
        case 'pagedown'
            
            bottom_channel = handles.disp_chans(end);
            
            if bottom_channel ~=  size(EEG.csc_montage.channels, 1)
                handles.disp_chans = handles.disp_chans + 1;
            end
            
            % redraw the plot by calling the scroll callback
            guidata(object, handles);
            update_main_plot(object);
    end    
end

function fcn_filter_settings(object, event)
% get the original figure handles
handles.csc_plotter = guidata(object);
EEG = getappdata(handles.csc_plotter.fig, 'EEG');

% make a window
handles.fig = figure(...
    'name',         'csc filter settings',...
    'numberTitle',  'off',...
    'color',        handles.csc_plotter.colorscheme.bg_col_1,...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition', [0.4 0.4 0.2 0.2]);

% montage table
handles.table = uitable(...
    'parent',       handles.fig             ,...
    'units',        'normalized'            ,...
    'position',     [0.05, 0.30, 0.9, 0.65]   ,...
    'backgroundcolor', handles.csc_plotter.colorscheme.bg_col_2 ,...
    'foregroundcolor', handles.csc_plotter.colorscheme.fg_col_1 ,...
    'columnEditable', [false, true, true, false], ...
    'columnFormat', {'char', 'numeric', 'numeric', 'char'}, ...
    'columnName',   {'type', 'high', 'low', 'color'});

% set the data
data = cell(4, 4);
data(:, 1) = {'EEG', 'EMG', 'EOG', 'Other'};
data(:, [2, 3]) = num2cell(handles.csc_plotter.filter_options);
% TODO: make color options for individual channel types
data(:, 4) = {'d'};
set(handles.table, 'Data', data);

% automatically adjust the column width using java handle
jscroll = findjobj(handles.table);
jtable  = jscroll.getViewport.getView;
jtable.setAutoResizeMode(jtable.AUTO_RESIZE_ALL_COLUMNS);

% create the save button
handles.apply_filters = uicontrol(...
    'parent',       handles.fig,...
    'style',        'push',...    
    'string',       'apply',...
    'foregroundColor', 'k',...
    'units',        'normalized',...
    'position',     [0.275 0.1 0.5 0.1],...
    'fontName',     'Century Gothic',...
    'fontWeight',   'bold',...   
    'fontSize',     10);
set(handles.apply_filters, 'callback', {@fcn_apply_filters});

% save those handles
guidata(handles.fig, handles);

function fcn_apply_filters(object, event)
% get filter figure handles
handles = guidata(object);
handles.csc_plotter = guidata(handles.csc_plotter.fig);

% get relevant filter data
data = get(handles.table, 'Data');
filter_data = cell2mat(data(:, [2, 3]));

% put in plotter figure handles
handles.csc_plotter.filter_options = filter_data;

% save those handles
guidata(handles.fig, handles);
guidata(handles.csc_plotter.fig, handles.csc_plotter);

% update the plot
update_main_plot(handles.csc_plotter.fig, 1);


% Montage Functions
% ^^^^^^^^^^^^^^^^^
function fcn_montage_setup(object, ~)
% get the original figure handles
handles.csc_plotter = guidata(object);
EEG = getappdata(handles.csc_plotter.fig, 'EEG');

% make a window
% ~~~~~~~~~~~~~
handles.fig = figure(...
    'name',         'csc montage setup',...
    'numberTitle',  'off',...
    'color',        [0.1, 0.1, 0.1],...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.04 .8 0.96]);

% make the axes
% ~~~~~~~~~~~~~
% main axes
handles.main_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.05 0.1, 0.6, 0.8]   ,...
    'nextPlot',     'add'                   ,...
    'color',        [0.2, 0.2, 0.2]         ,...
    'xcolor',       [0.9, 0.9, 0.9]         ,...
    'ycolor',       [0.9, 0.9, 0.9]         ,...
    'xtick',        []                      ,...    
    'ytick',        []                      ,...
    'fontName',     'Century Gothic'        ,...
    'fontSize',     8                       );

% drop-down list of montages
% ~~~~~~~~~~~~~~~~~~~~~~~~~~
montage_dir  = which('csc_eeg_plotter.m');
montage_dir  = fullfile(fileparts(montage_dir), 'Montages');
montage_list = dir(fullfile(montage_dir, '*.emo'));

% default list
default_list = {''; 'original'};

% check the list
if ~isempty(montage_list)
    montage_list = [default_list; {montage_list.name}'];
else
    montage_list = default_list;
end

% create the drop down
handles.montage_list = uicontrol(       ...
    'parent',       handles.fig         ,...
    'style',        'popupmenu'         ,...
    'backgroundColor', [0.2, 0.2, 0.2]  ,...
    'units',        'normalized'        ,...
    'position',     [0.05 0.9 0.2, 0.05],...
    'string',       montage_list        ,...
    'selectionHighlight', 'off'         ,...
    'foregroundColor', [0.9, 0.9, 0.9]  ,...
    'fontName',     'Century Gothic'    ,...
    'fontSize',     8);
set(handles.montage_list, 'callback', {@fcn_select_montage});

% create the save button
handles.save_montage = uicontrol(...
    'parent',       handles.fig,...
    'style',        'push',...    
    'string',       '+',...
    'foregroundColor', 'k',...
    'units',        'normalized',...
    'position',     [0.275 0.93 0.02 0.02],...
    'fontName',     'Century Gothic',...
    'fontWeight',   'bold',...   
    'fontSize',     10);
set(handles.save_montage, 'callback', {@fcn_save_montage});


% montage table
handles.table = uitable(...
    'parent',       handles.fig             ,...
    'units',        'normalized'            ,...
    'position',     [0.675, 0.1, 0.3, 0.8]  ,...
    'backgroundcolor', [0.1, 0.1, 0.1; 0.2, 0.2, 0.2],...
    'foregroundcolor', [0.9, 0.9, 0.9]      ,...
    'columnName',   {'name','chan','ref', 'scale', 'type'},...
    'columnFormat', {'char', 'numeric', 'numeric', 'numeric', {'EEG', 'EMG', 'EOG', 'Other'}}, ...
    'columnEditable', [true, true, true, true, true]);

% automatically adjust the column width using java handle
jscroll = findjobj(handles.table);
jtable  = jscroll.getViewport.getView;
jtable.setAutoResizeMode(jtable.AUTO_RESIZE_ALL_COLUMNS);

% create the reference list text
handles.reference_text = uicontrol(...
    'parent',       handles.fig, ...
    'units',        'normalized', ...
    'style',        'text', ...
    'string',       'reference choice', ...
    'horizontalAlignment', 'center', ...
    'enable', 'on', ...
    'position',     [0.675 0.93 0.10, 0.02], ...
    'backgroundColor', handles.csc_plotter.colorscheme.bg_col_2, ...
    'foregroundColor', handles.csc_plotter.colorscheme.fg_col_2, ...
    'fontName',     'Century Gothic', ...
    'fontSize',     8);
handles.java.reference_text = findjobj(handles.reference_text); 
handles.java.reference_text.setVerticalAlignment(javax.swing.SwingConstants.CENTER);
    
% create reference drop down menu
reference_list = {'inherent', 'custom', 'average'};
handles.reference_list = uicontrol(     ...
    'parent',       handles.fig         ,...
    'style',        'popupmenu'         ,...
    'backgroundColor', handles.csc_plotter.colorscheme.bg_col_2,...
    'foregroundColor', handles.csc_plotter.colorscheme.fg_col_2  ,...
    'units',        'normalized'        ,...
    'position',     [0.8 0.9 0.175, 0.05],...
    'string',       reference_list      ,...
    'selectionHighlight', 'off'         ,...
    'fontName',     'Century Gothic'    ,...
    'fontSize',     8);
% if montage exists set to reference already chosen
switch EEG.csc_montage.reference
    case 'custom'
        set(handles.reference_list, 'value', 2);
    case 'average'
        set(handles.reference_list, 'value', 3);
end
% set callback
set(handles.reference_list, 'callback', {@fcn_montage_buttons, 'reference'});

% create the buttons
handles.button_add = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'push',...    
    'String',   'add',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.675 0.075 0.05 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);
set(handles.button_add, 'callback', {@fcn_montage_buttons, 'add'});

handles.button_delete = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'push',...    
    'String',   'delete',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.75 0.075 0.05 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);
set(handles.button_delete, 'callback', {@fcn_button_delete});
guidata(handles.fig, handles);
guidata(handles.csc_plotter.fig, handles.csc_plotter);
handles.button_reset = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'push',...    
    'String',   'reset',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.85 0.075 0.05 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);
set(handles.button_reset, 'callback', {@fcn_montage_buttons, 'reset'});

handles.button_apply = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'push',...    
    'String',   'apply',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.925 0.075 0.05 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);
set(handles.button_apply, 'callback', {@fcn_button_apply});

% set the initial table values
data = cell(length(EEG.csc_montage.label_channels), 3);
% current montage
data(:, 1) = deal(EEG.csc_montage.label_channels);
data(:, [2,3]) = num2cell(EEG.csc_montage.channels);
data(:, 4) = num2cell(EEG.csc_montage.scaling);
data(:, 5) = deal(EEG.csc_montage.channel_type);

% put the data into the table
set(handles.table, 'data', data);

% update handle structure
guidata(handles.fig, handles);

% plot the net
plot_net(handles.fig)

function plot_net(montage_handle)
% get the handles and EEG structure
handles  = guidata(montage_handle);
EEG = getappdata(handles.csc_plotter.fig, 'EEG');

% check if chanlocs are available
if isempty(EEG.chanlocs)
   return 
end

if ~isfield(EEG.chanlocs(1), 'x')
   EEG.chanlocs = csc_add2dlocations(EEG.chanlocs); 
end

x = [EEG.chanlocs.x];
y = [EEG.chanlocs.y];
labels = {EEG.chanlocs.labels};

% make sure the circles are in the lines
set(handles.main_ax, 'xlim', [0, 41], 'ylim', [0, 41]);

for n = 1:length(EEG.chanlocs)
    handles.plt_markers(n) = plot(handles.main_ax, y(n), x(n),...
        'lineStyle', 'none',...
        'lineWidth', 3,...
        'marker', 'o',...
        'markersize', 25,...
        'markerfacecolor', [0.15, 0.15, 0.15],...
        'markeredgecolor', [0.08, 0.08, 0.08],...
        'selectionHighlight', 'off',...
        'userData', n);
    
    handles.txt_labels(n) = text(...
        y(n), x(n), labels{n},...
        'parent', handles.main_ax,...
        'fontname', 'liberation sans narrow',...
        'fontsize',  8,...
        'fontweight', 'bold',...
        'color',  [0.9, 0.9, 0.9],...
        'horizontalAlignment', 'center',...
        'selectionHighlight', 'off',...
        'userData', n);
end

set(handles.plt_markers, 'ButtonDownFcn', {@bdf_select_channel});
set(handles.txt_labels, 'ButtonDownFcn', {@bdf_select_channel});

guidata(handles.fig, handles);
setappdata(handles.csc_plotter.fig, 'EEG', EEG);

update_net_arrows(handles.fig)

function update_net_arrows(montage_handle)
% get the handles and EEG structure
handles     = guidata(montage_handle);
EEG         = getappdata(handles.csc_plotter.fig, 'EEG');

% check if chanlocs are available
if isempty(EEG.chanlocs)
    return
end

x = [EEG.chanlocs.x];
y = [EEG.chanlocs.y];

if isfield(handles, 'line_arrows')
    try
        delete(handles.line_arrows);
        handles.line_arrows = [];
    end
end

% get the table data
data = get(handles.table, 'data');

% make an arrow from each channel to each reference
for n = 1:size(data, 1)
    handles.line_arrows(n) = line([y(data{n,2}), y(data{n,3})],...
                                  [x(data{n,2}), x(data{n,3})],...
                                  'parent', handles.main_ax,...
                                  'color', [0.3, 0.8, 0.3]);
end

uistack(handles.plt_markers, 'top');
uistack(handles.txt_labels, 'top');

guidata(handles.fig, handles);

function bdf_select_channel(object, ~)
% get the handles
handles = guidata(object);

% get the mouse button
event = get(handles.fig, 'selectionType');
ch    = get(object, 'userData');  

switch event
    case 'normal'
        data = get(handles.table, 'data');
        data{end+1, 1} = [num2str(ch), ' - '];
        data{end, 2} = ch;
        data{end, 4} = 1;
        set(handles.table, 'data', data);
        
    case 'alt'
        data = get(handles.table, 'data');
        ind  = cellfun(@(x) isempty(x), data(:, 3));
        % if same channel is selected than apply no reference
        if ch == data{end, 2}
            data(ind, 3) = deal({0});
        else
            data(ind, 3) = deal({ch});
        end
        set(handles.table, 'data', data);
        
        % replot the arrows
        update_net_arrows(handles.fig)
end

set(handles.montage_list, 'value', 1);

function fcn_button_delete(object, ~)
% get the handles
handles = guidata(object);

% find the row indices to delete
jscroll = findjobj(handles.table);
del_ind = jscroll.getComponent(0).getComponent(0).getSelectedRows+1;

% get the table, delete the rows and reset the table
data = get(handles.table, 'data');
data(del_ind, :) = [];
set(handles.table, 'data', data);

% update the arrows on the montage plot
update_net_arrows(handles.fig)

function fcn_button_apply(object, ~)
% get the montage handles
handles = guidata(object);
EEG     = getappdata(handles.csc_plotter.fig, 'EEG');

% get (potentially updated handles of main figure)
handles.csc_plotter = guidata(handles.csc_plotter.fig);

% get the table data
data = get(handles.table, 'data');

% check the all inputs are valid
if any(any(cellfun(@(x) ~isa(x, 'double'), data(:,[2,3]))))
    fprintf(1, 'Warning: check that all channel inputs are numbers\n');
end

EEG.csc_montage.label_channels = data(:,1);
EEG.csc_montage.channels = cell2mat(data(:,[2,3]));
EEG.csc_montage.scaling = cell2mat(data(:, 4));
EEG.csc_montage.channel_type = data(:, 5);

% compatibility with older matlab versions (handles dot notation).
if verLessThan('matlab', '8.4')
    tmp_list = get(handles.reference_list, 'String');
    EEG.csc_montage.reference = tmp_list{get(handles.reference_list, 'Value')};
else
    EEG.csc_montage.reference = ...
        handles.reference_list.String{handles.reference_list.Value};
end
    
% adjust the number of channels to display if necessary
if length(EEG.csc_montage.label_channels) < handles.csc_plotter.n_disp_chans
    handles.csc_plotter.n_disp_chans = length(EEG.csc_montage.label_channels);
    handles.csc_plotter.disp_chans = [1:handles.csc_plotter.n_disp_chans];
    fprintf(1, 'Warning: reduced number of display channels to match montage\n');
end

% Reset hidden channels
handles.csc_plotter.hidden_chans = [];

% change montage name
% compatibility with older matlab versions (handles dot notation).
tmp_list = get(handles.montage_list, 'string');
if isempty(tmp_list)
    EEG.csc_montage.name = 'custom';
else
    EEG.csc_montage.name = tmp_list{get(handles.montage_list, 'Value')};
end
    
% recalculate channel type (faster plotting if calculated once here)
handles.csc_plotter.channel_types = ones(length(EEG.csc_montage.channel_type), 1);
channel_types = {'EEG', 'EMG', 'EOG', 'Other'};
for n = 1 : 4
    type_ind = cellfun(@(x) strcmp(x, channel_types{n}), EEG.csc_montage.channel_type);
    handles.csc_plotter.channel_types(type_ind) = n;
end

% update the handle structures
guidata(handles.fig, handles);
guidata(handles.csc_plotter.fig, handles.csc_plotter);
setappdata(handles.csc_plotter.fig, 'EEG', EEG);

% update the plot
update_main_plot(handles.csc_plotter.fig);

function fcn_montage_buttons(object, ~, event_type)
% get the montage handles
handles = guidata(object);

switch event_type
    case 'add'
        % add a row of ones to the table 
        old_data = handles.table.Data;
        new_row = {'', 1, 0, 1, 'EEG'};
        set(handles.table, 'Data', [old_data; new_row]);
        
    case 'reset'
        % populate the montage with original channels and labels
        
        % get the EEG meta data
        EEG = getappdata(handles.csc_plotter.fig, 'EEG');

        montage = cell(length(EEG.chanlocs), 4);
        
        % assign motange values
        [montage(:, 1)] = deal({EEG.chanlocs.labels}); % names
        [montage(:, 2)] = deal(num2cell(1 : EEG.nbchan)); % actual number
        montage(:, 3) = {EEG.nbchan}; % reference
        montage(:, 4) = {1}; % scaling
        [montage(:, 5)] = deal({'EEG'});
        
        % assign to table
        set(handles.table, 'Data', montage);

end

function fcn_select_montage(object, ~)
% get the montage handles
handles = guidata(object);
EEG     = getappdata(handles.csc_plotter.fig, 'EEG');

% find the montage directory
montage_dir  = which('csc_eeg_plotter.m');
montage_dir  = fullfile(fileparts(montage_dir), 'Montages');

% get the file name
montage_name = get(handles.montage_list, 'string');
montage_name = montage_name{get(handles.montage_list, 'value')};

% TODO: check whether montage is compatible with currently loaded dataset

% set the montage back into the EEG.csc_montage
EEG.csc_montage.name = montage_name;

% check if the empty string was selected
if ~isempty(montage_name) && ~strcmp(montage_name, 'original')
    montage = load(fullfile(montage_dir, montage_name), '-mat');
    if isfield(montage, 'data')
               
        % check for missing channel types
        if size(montage.data, 2) < 5
            montage.data(:, 5) = deal({'EEG'});
        end

        % set into the table
        set(handles.table, 'data', montage.data);

    else
        fprintf(1, 'Warning: could not find montage data in the file.\n');
    end
elseif ~isempty(montage_name) && strcmp(montage_name, 'original')
    % taken care of in the u
end

% update the handles in the structure
guidata(handles.fig, handles);
setappdata(handles.csc_plotter.fig, 'EEG', EEG);

% update the arrows on the montage plot
update_net_arrows(handles.fig)

function fcn_save_montage(object, ~)
% get the montage handles
handles = guidata(object);

% get the montage data
data = get(handles.table, 'data');

% find the montage directory
montage_dir  = which('csc_eeg_plotter.m');
montage_dir  = fullfile(fileparts(montage_dir), 'Montages');

% ask user for the filename
fileName = inputdlg('new montage name',...
    '', 1, {'new_montage'});

% check to see if user cancels
if isempty(fileName)
    return;
else
    % if not then get the string
    fileName = fileName{1};
end

% check to make sure it ends with '.emo' extension
if ~strcmp(fileName(end-3 : end), '.emo')
    fileName = [fileName, '.emo'];
end

% save the file
save(fullfile(montage_dir, fileName), 'data', '-mat')

% update the montage list
montage_list = dir(fullfile(montage_dir, '*.emo'));
montage_list = [{''}; {montage_list.name}'];

new_index = find(strcmp(fileName, montage_list));

% set the drop-down menu
set(handles.montage_list,...
    'string', montage_list,...
    'value', new_index);


