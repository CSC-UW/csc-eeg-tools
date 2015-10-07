function EEG = csc_eeg_plotter(varargin)

%TODO: Main page 
        %Scale - green lines across one of the channels
        %Video scroll with space bar - reasonable speed - pause/play?
        %Auto adjust time scale on bottom for whole night
        %left side epoch length/scale boxes
        %top center box stating what is in the epoch (much like sleep scoring)
        %highlight spikes, makes tick below
        %Scoring axis
            %ticks or mapping (like sleep scoring) only marked seizure, spike, artifact
        %Display button? way to visualize event related EEG data while scoring?
        %Options button? channel/window length and print button

%TODO: Montage
        %Green line in front of headset
        %headset electrodes smaller due to poor resolution on my computer

% TODO: Fix this ugly default setting style (e.g. handles.options...)        
% declare defaults
N_DISP_CHANS = 12;
PLOT_ICA = 0;
EPOCH_LENGTH = 30;
PLOT_GRID = 1;
FILTER_OPTIONS = [0.3 40];

% Set display channels
handles.n_disp_chans = N_DISP_CHANS;
handles.disp_chans = [1 : handles.n_disp_chans];
% Undisplayed channels are off the plot entirely. Hidden channels reserve space
% on the plot, but are invisible. 
handles.hidden_chans = [];
% Plot normal time courses instead of component time courses by default
handles.plotICA = PLOT_ICA;

% make a window
% ~~~~~~~~~~~~~
handles.fig = figure(...
    'name',         'csc EEG Plotter',...
    'numberTitle',  'off',...
    'color',        [0.1, 0.1, 0.1],...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.04 .5 0.96]);

% make the axes
% ~~~~~~~~~~~~~
% main axes
handles.main_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.05 0.2, 0.9, 0.75]   ,...
    'nextPlot',     'add'                   ,...
    'color',        [0.2, 0.2, 0.2]         ,...
    'xcolor',       [0.9, 0.9, 0.9]         ,...
    'ycolor',       [0.9, 0.9, 0.9]         ,...  
    'ytick',        []                      ,...
    'fontName',     'Century Gothic'        ,...
    'fontSize',     8                       );

% navigation/spike axes
handles.spike_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0.05 0.075, 0.9, 0.05] ,...
    'nextPlot',     'add'                   ,...
    'color',        [0.2, 0.2, 0.2]         ,...
    'xcolor',       [0.9, 0.9, 0.9]         ,...
    'ycolor',       [0.9, 0.9, 0.9]         ,...   
    'ytick',        []                      ,...   
    'fontName',     'Century Gothic'        ,...
    'fontSize',     8                       );

% invisible name axis
handles.name_ax = axes(...
    'parent',       handles.fig             ,...
    'position',     [0 0.2, 0.1, 0.75]   ,...
    'visible',      'off');

handles.filter_options = FILTER_OPTIONS;
handles.epoch_length = EPOCH_LENGTH;
handles.plot_grid = PLOT_GRID;

% create the uicontextmenu for the main axes
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
handles.selection.menu = uicontextmenu;
set(handles.main_ax, 'uicontextmenu', handles.selection.menu);
% TODO: move to loading stage and read from file or create these defaults
number_of_event_types = 2;
for n = 1:number_of_event_types
    handles.selection.item(n) = uimenu(handles.selection.menu,...
        'label', ['event ', num2str(n)], 'userData', n);
    set(handles.selection.item(n),...
        'callback',     {@cb_event_selection, n});
end

% create the menu bar
% ~~~~~~~~~~~~~~~~~~~
handles.menu.file       = uimenu(handles.fig, 'label', 'file');
handles.menu.load       = uimenu(handles.menu.file,...
    'Label', 'load eeg',...
    'Accelerator', 'l');
handles.menu.save       = uimenu(handles.menu.file,...
    'Label', 'save eeg',...
    'Accelerator', 's');

handles.menu.montage    = uimenu(handles.fig, 'label', 'montage', 'enable', 'off');

handles.menu.events     = uimenu(handles.fig, 'label', 'events', 'accelerator', 'v');

% options menu
handles.menu.options    = uimenu(handles.fig, 'label', 'options');
handles.menu.disp_chans = uimenu(handles.menu.options,...
    'label', 'display channels',...
    'accelerator', 'd');
handles.menu.epoch_length = uimenu(handles.menu.options,...
    'label', 'epoch length',...
    'accelerator', 'e');
handles.menu.filter_settings = uimenu(handles.menu.options,...
    'label', 'filter settings',...
    'accelerator', 'f');
handles.menu.icatoggle = uimenu(handles.menu.options,...
    'label', 'toggle components/channels',...
    'accelerator', 't');
handles.menu.export_hidden_chans = uimenu(handles.menu.options,...
    'label', 'export hidden channels',...
    'accelerator', 'x');
handles.menu.export_marked_trials = uimenu(handles.menu.options,...
    'label', 'export marked trials',...
    'accelerator', 't');

% scroll bar
% ~~~~~~~~~~  
handles.vertical_scroll = uicontrol(...
    'Parent',   handles.fig,...
    'Units',    'normalized',...
    'Style',    'slider',...
    'Position', [0.01, 0.4, 0.015, 0.4],...
    'Max',      -1,...
    'Min',      -(length(handles.disp_chans)),...
    'value',    -1,...
    'callback', @cb_scrollbar);

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

set(handles.menu.disp_chans,   'callback', {@fcn_options, 'disp_chans'});
set(handles.menu.epoch_length, 'callback', {@fcn_options, 'epoch_length'});
set(handles.menu.filter_settings, 'callback', {@fcn_options, 'filter_settings'});
set(handles.menu.icatoggle,    'callback', {@fcn_options, 'icatoggle'});
set(handles.menu.export_hidden_chans, 'callback',...
    {@fcn_options, 'export_hidden_chans'});
set(handles.menu.export_marked_trials, 'callback',...
    {@fcn_options, 'export_marked_trials'});

set(handles.fig,...
    'KeyPressFcn', {@cb_key_pressed,});

set(handles.spike_ax, 'buttondownfcn', {@fcn_time_select});

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
            setappdata(handles.fig, 'EEG', EEG);
            setappdata(handles.fig, 'eegData', EEG.data);
        end
        
        EEG = initialize_loaded_eeg(handles.fig, EEG, EEG.data);
        setappdata(handles.fig, 'EEG', EEG);
        
        % allocate marked trials
        handles.trials = false(EEG.trials, 1);
        guidata(handles.fig, handles)
        
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

% update the handles structure
guidata(handles.fig, handles)

% use setappdata for data storage to avoid passing it around in handles when not necessary
setappdata(handles.fig, 'EEG', EEG);

% check for previously epoched data
if ndims(EEG.data) == 3
    % flatten the third dimension into the second
    eegData = reshape(EEG.data, size(EEG.data, 1), []);
    setappdata(handles.fig, 'eegData', eegData);
else
    setappdata(handles.fig, 'eegData', EEG.data);
end
    
% plot the initial data
update_main_plot(handles.fig);

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

function update_main_plot(object)
% get the handles structure
handles = guidata(object);

% get the data
EEG = getappdata(handles.fig, 'EEG');

% select the plotting data
current_point = get(handles.cPoint, 'value');
range = current_point : ...
    current_point + handles.epoch_length * EEG.srate -1;

% check for ica flag plot and get if there
if handles.plotICA == 1
  title(handles.main_ax, 'Component Activations', 'Color', 'w');
  icaData = getappdata(handles.fig, 'icaData');
  data = icaData(EEG.csc_montage.channels(handles.disp_chans, 1),range);
  
else
  title(handles.main_ax, 'Channel Activations', 'Color', 'w');
  eegData = getappdata(handles.fig, 'eegData');
  
  if strcmp(EEG.csc_montage.name, 'original')
      data = eegData(handles.disp_chans, range);
  else  
      data = eegData(EEG.csc_montage.channels(handles.disp_chans, 1), range)...
          - eegData(EEG.csc_montage.channels(handles.disp_chans, 2), range);
  end
  
  % filter the data
  % ~~~~~~~~~~~~~~~
  [EEG.filter.b, EEG.filter.a] = ...
          butter(2,[handles.filter_options(1)/(EEG.srate/2),...
                    handles.filter_options(2)/(EEG.srate/2)]);
  data = single(filtfilt(EEG.filter.b, EEG.filter.a, double(data'))');
end


% plot the data
% ~~~~~~~~~~~~~
% define accurate spacing
scale = get(handles.txt_scale, 'value')*-1;
toAdd = [1:handles.n_disp_chans]'*scale;
toAdd = repmat(toAdd, [1, length(range)]);

% space out the data for the single plot
data = data + toAdd;

set([handles.main_ax, handles.name_ax], 'yLim', [scale 0]*(handles.n_disp_chans+1))

% in the case of replotting delete the old handles
% TODO: seems to always replot entire line... best to reset yData!
if isfield(handles, 'plot_eeg')
    delete(handles.plot_eeg);
    delete(handles.labels);
    delete(handles.indicator);
end
if isfield(handles, 'gridlines')
    delete(handles.gridlines);
end

% calculate the time in seconds
time = range/EEG.srate;
set(handles.main_ax,  'xlim', [time(1), time(end)]);
handles.plot_eeg = line(time, data,...
                        'color', [0.9, 0.9, 0.9],...
                        'parent', handles.main_ax);
% plot gridlines
if handles.plot_grid
  inttimes = time(~mod(time, 1)); % find all integer times
  gridtimes = repmat(inttimes, 2, 1);
  ylims = get(handles.main_ax, 'ylim');
  gridlims = repmat(ylims, length(gridtimes), 1)';
  handles.gridlines = line(gridtimes, gridlims,...
      'LineStyle',  ':',...
      'Color',      [0.6 0.6 0.6],...
      'Parent',     handles.main_ax);
end

% Get indices of channels to hide
hidden_idx = ismember(handles.disp_chans, handles.hidden_chans);
% Now hide them
set(handles.plot_eeg(hidden_idx), 'visible', 'off');

% plot the labels in their own boxes
handles.labels = zeros(handles.n_disp_chans, 1);
for i = 1:handles.n_disp_chans
  chn = handles.disp_chans(i);
  handles.labels(i) = ...
        text(0.5, toAdd(i,1)+scale/5, EEG.csc_montage.label_channels{chn},...
        'parent', handles.name_ax,...
        'fontsize',   12,...
        'fontweight', 'bold',...
        'color',      [0.8, 0.8, 0.8],...
        'backgroundcolor', [0.1 0.1 0.1],...
        'horizontalAlignment', 'center',...
        'buttondownfcn', {@fcn_toggle_channel});
end
                    
% change the x limits of the indicator plot
set(handles.spike_ax,   'xlim', [0, EEG.pnts * EEG.trials],...
                        'ylim', [0, 1]);
                    
% add indicator line to lower plot
handles.indicator = line([range(1), range(1)], [0, 1],...
                        'color', [0.9, 0.9, 0.9],...
                        'linewidth', 4,...
                        'parent', handles.spike_ax,...
                        'hittest', 'off');
                    
% set the new parameters
guidata(handles.fig, handles);
setappdata(handles.fig, 'EEG', EEG);

function cb_scrollbar(object, ~)
% callback to the change the displayed channels
handles = guidata(object);
EEG = getappdata(handles.fig, 'EEG');

% calculate the new display channel range
new_start = -ceil(handles.vertical_scroll.Value);

% check whether new_start and potential end make sense
total_channels = length(EEG.csc_montage.channels(:, 1));
if new_start + handles.n_disp_chans - 1 < total_channels
    % change the indices of displayed channels
    handles.disp_chans = new_start : new_start + handles.n_disp_chans - 1;
else
    handles.disp_chans = total_channels - handles.n_disp_chans + 1 : total_channels;
end

% update the handles and replot the data
guidata(handles.fig, handles);
update_main_plot(object);

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
update_main_plot(handles.fig);

function fcn_toggle_channel(object, ~)
% get the handles from the guidata
handles = guidata(object);

% find which of the n_disp_chans possible plot lines the selected channel is
i = find(handles.labels == object);
% find which channel this corresponds to
ch = handles.disp_chans(i);

% get its current state ('on' or 'off')
state = get(handles.plot_eeg(i), 'visible');

switch state
    case 'on'
      set(handles.plot_eeg(i), 'visible', 'off');
      handles.hidden_chans = [handles.hidden_chans ch]; % save state
    case 'off'
      set(handles.plot_eeg(i), 'visible', 'on');
      handles.hidden_chans = handles.hidden_chans(handles.hidden_chans ~= ch);
end
guidata(object, handles);

function fcn_time_select(object, ~)
handles = guidata(object);

% get position of click
clicked_position = get(handles.spike_ax, 'currentPoint');

set(handles.cPoint, 'Value', floor(clicked_position(1,1)));
fcn_change_time(object, []);

function eegMeta = initialize_loaded_eeg(object, eegMeta, eegData)

handles = guidata(object);

% check for the channel locations
if isempty(eegMeta.chanlocs)
    if isempty(eegMeta.urchanlocs)
        fprintf(1, 'Warning: No channel locations found in the eegMeta structure \n');
    else
        fprintf(1, 'Information: Taking the EEG.urchanlocs as the channel locations \n');
        eegMeta.chanlocs = eegMeta.urchanlocs;
    end
end

% check for previous
if ~isfield(eegMeta, 'csc_montage')
    % assign defaults
    eegMeta.csc_montage.name = 'original';
    eegMeta.csc_montage.label_channels      = cell(eegMeta.nbchan, 1);
    for n = 1 : eegMeta.nbchan
        eegMeta.csc_montage.label_channels(n) = {num2str(n)};
    end
    eegMeta.csc_montage.channels(:, 1)       = 1:eegMeta.nbchan;
    eegMeta.csc_montage.channels(:, 2)       = eegMeta.nbchan;
end

% load ICA time courses if the information need to construct them is available.
if isfield(eegMeta, 'icaweights') && isfield(eegMeta, 'icasphere')
    if ~isempty(eegMeta.icaweights) && ~isempty(eegMeta.icasphere)
        % If we have the same number of components as channels...
        if size(eegMeta.icaweights, 1) == size(eegData, 1)
            icaData = eegMeta.icaweights*eegMeta.icasphere*eegData;
            setappdata(handles.fig, 'icaData', icaData);
            % If we have fewer components than channels (maybe you've already removed
            % some of them), then pad the ICA weights with zeros and produce component
            % activations as if you had the same number of components as channels.
        elseif size(eegMeta.icaweights, 1) < size(eegData,1)
            dimdiff = size(eegData, 1) - size(eegMeta.icaweights, 1);
            pad = zeros(dimdiff, size(eegMeta.icaweights, 2));
            paddedweights = [eegMeta.icaweights ; pad];
            try
                icaData = paddedweights*eegMeta.icasphere*eegData;
            catch
                fprintf('%s. %s.',...
                        'Data were reinterpolated after IC removal',...
                        'Can no longer display IC activations');
                icaData = zeros(size(eegData));
            end
            setappdata(handles.fig, 'icaData', icaData);
        else
            error('ICA unmixing matrix is too large for data');
        end
    end
end

% turn on the montage option
set(handles.menu.montage, 'enable', 'on');

% reset the scrollbar values
handles.vertical_scroll.Max = -1;
handles.vertical_scroll.Min = -(eegMeta.nbchan - length(handles.disp_chans) + 1);

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
    'color',        [0.1, 0.1, 0.1],...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.5 0.1 0.5]);

% montage table
handles.table = uitable(...
    'parent',       handles.fig             ,...
    'units',        'normalized'            ,...
    'position',     [0.05, 0.1, 0.9, 0.8]   ,...
    'backgroundcolor', [0.1, 0.1, 0.1; 0.2, 0.2, 0.2],...
    'foregroundcolor', [0.9, 0.9, 0.9]      ,...
    'columnName',   {'label','time', 'type'});

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
no_events = cellfun(@(x) size(x,1), events);

% pre-allocate the event data
event_data = cell(sum(no_events), 3);

% loop for each event type
for type = 1:length(no_events)
    % skip event type if there are no events
    if isempty(events{type})
        continue;
    end
    
    % calculate the rows to be inserted
    % TODO: range calculation breaks for multiple event types
    range = sum(no_events(1:type - 1)) + 1 : sum(no_events(1:type));
    
    % deal the event type into the event_data
    event_data(range, 1) = {get(handles.selection.item(type), 'label')};
    
    % return the xdata from the handles
    % check for single event
    if numel(range) < 2
        event_data(range, 2) = {get(events{type}(:,1), 'xdata')};
    else
        event_data(range, 2) = get(events{type}(:,1), 'xdata');
    end
    
    % add the event type number in case labels are changed
    event_data(range, 3) = {type};
    
end

function cb_select_table(object, event_data)
% when a cell in the table is selected, jump to that time point

% get the handles
handles = guidata(object);

% get the data
EEG = getappdata(handles.csc_plotter.fig, 'EEG');

% if the event column was selected return
if event_data.Indices(2) == 1
    return
end

% return the data from the table
table_data = get(object, 'data');

% retrieve the time from the table
selected_time = table_data{event_data.Indices(1), 2};
go_to_time = selected_time - handles.epoch_length/2;
selected_sample = floor(go_to_time * EEG.srate);

% change the hidden time keeper
set(handles.csc_plotter.cPoint, 'Value', selected_sample);

% update the time in the plotter window
fcn_change_time(handles.csc_plotter.fig, []);

function cb_event_selection(object, ~, event_type, current_point)
% get the handles
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% get the default color order for the axes
event_colors = get(handles.main_ax, 'ColorOrder');

% check if its the first item
if ~isfield(handles, 'events')
   handles.events = cell(length(handles.selection.item), 1);
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
handles.events{event_type}(end+1, 1) = plot(x, y(1),...
    'lineStyle', 'none',...
    'marker', '^',...
    'markerSize', 20,...
    'markerEdgeColor', [0.9, 0.9, 0.9],...
    'markerFaceColor', event_colors(event_type, :),...
    'userData', event_type,...
    'parent', handles.main_ax,...
    'buttonDownFcn', {@bdf_delete_event});

% draw top triangle
handles.events{event_type}(end, 2) = plot(x, y(2),...
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
% get the y limits of the event axes
y = get(handles.spike_ax, 'ylim');

% translate the current x point into the event axes
sample_point = floor(x * EEG.srate);

handles.events{event_type}(end, 3) = line([sample_point, sample_point], y,...
    'color', [0.6, 0.9, 0.9],...
    'parent', handles.spike_ax,...
    'userData', event_type,...
    'hitTest', 'off');

% update the GUI handles
guidata(handles.fig, handles)

function bdf_delete_event(object, ~)
% get the handles
handles = guidata(object);

% calculate the event number
event_type = get(object, 'userData');
event_number = mod(find(object == handles.events{event_type}), size(handles.events{event_type}, 1));

% check for event 0, which is really the last event
if event_number == 0
    event_number = size(handles.events{event_type}, 1);
end

% erase the object from the main and spike axes
delete(handles.events{event_type}(event_number, :));

% erase the event from the list
handles.events{event_type}(event_number, :) = [];

% update the GUI handles
guidata(handles.fig, handles)

function fcn_redraw_events(object, ~)
% function to erase all events and redraw their markers based on the
% csc_event_data array in the EEG structure

% get the handles
handles = guidata(object);
% Get the EEG from the figure's appdata
EEG = getappdata(handles.fig, 'EEG');

% TODO check for current events and delete their handles

% loop through each event
for n = 1:size(EEG.csc_event_data, 1)
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

% get the y limits of the main axes
y = get(handles.main_ax, 'ylim');

% draw bottom arrow
handles.trial_borders = plot(x, y(1),...
    'lineStyle', 'none',...
    'marker', '>',...
    'markerSize', 20,...
    'markerEdgeColor', [0.9, 0.9, 0.9],...
    'markerFaceColor', [0.6, 0.6, 0.6],...
    'parent', handles.main_ax,...
    'buttonDownFcn', {@bdf_mark_trial});

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
        
        % when changing the number of channels go back to 1
        handles.vertical_scroll.Value = -1;
        
        % update the handles and re-plot
        guidata(object, handles);
        update_main_plot(object);
        
    case 'epoch_length'
        
        answer = inputdlg('length of epoch',...
            '', 1, {num2str( handles.epoch_length )});
        
        % if different from previous
        if ~isempty(answer)
            newNumber = str2double(answer{1});
            if newNumber ~= handles.epoch_length 
                handles.epoch_length = newNumber;

                guidata(object, handles);
                update_main_plot(object)
            end
        end
        
    case 'filter_settings'
        
        answer = inputdlg({'low cut-off', 'high cut-off'},...
            '', 1, {num2str( handles.filter_options(1)),...
                    num2str( handles.filter_options(2))});
        
        % get and set the new values
        new_values = str2double(answer);
        if ~isequal(new_values, handles.filter_options')
            handles.filter_options = new_values;
            guidata(object, handles);
            update_main_plot(object);
        end
    
    case 'icatoggle'

        answer = questdlg('What would you like to display?',...
                          'Show/hide ICA time courses',...
                          'Channel activations',...
                          'ICA component activations',...
                          'Channel activations');
        if isempty(answer)
          return
        end

        if strcmp(answer, 'Channel activations')
          handles.plotICA = 0;
        end

        if strcmp(answer, 'ICA component activations')
          if isempty(getappdata(handles.fig, 'icaData'))
            warning('No ICA data found. Doing nothing');
          else
            handles.plotICA = 1;
          end
        end
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
            if scale <= 20
                value = scale / 2;
                set(handles.txt_scale, 'value', value);
            else
                value = scale - 20;
                set(handles.txt_scale, 'value', value);
            end
            
            set(handles.txt_scale, 'string', get(handles.txt_scale, 'value'));
            set(handles.main_ax, 'yLim', [get(handles.txt_scale, 'value')*-1, 0]*(handles.n_disp_chans+1))
            update_main_plot(object)
            
            if isfield(handles, 'events')
                % update the event lower triangles
                y_limits = get(handles.main_ax, 'ylim');
                relevant_handles = cell2mat(handles.events);
                relevant_handles = relevant_handles(:,1); 
                set(relevant_handles, 'ydata', y_limits(1))
            end
            
        case 'downarrow'
            scale = get(handles.txt_scale, 'value');
            if scale <= 20
                value = scale * 2;
                set(handles.txt_scale, 'value', value);
            else
                value = scale + 20;
                set(handles.txt_scale, 'value', value);
            end
            
            set(handles.txt_scale, 'string', get(handles.txt_scale, 'value'));
            set(handles.main_ax, 'yLim', [get(handles.txt_scale, 'value')*-1, 0]*(handles.n_disp_chans+1))
            update_main_plot(object)
            
            if isfield(handles, 'events')
                % update the event lower triangles
                y_limits = get(handles.main_ax, 'ylim');
                relevant_handles = cell2mat(handles.events);
                relevant_handles = relevant_handles(:,1); 
                set(relevant_handles, 'ydata', y_limits(1))
            end

        case 'pageup'
            
            % get the current top visible channel
            top_channel = -handles.vertical_scroll.Value;
            
            if top_channel - handles.n_disp_chans < 1
                handles.vertical_scroll.Value = -1;
            else
                handles.vertical_scroll.Value = -(top_channel - handles.n_disp_chans); 
            end
            
            % redraw the plot by calling the scroll callback
            cb_scrollbar(handles.vertical_scroll, []);            

        case 'pagedown'
            
            % get the current top visible channel
            bottom_channel = -handles.vertical_scroll.Value + handles.n_disp_chans -1;
            
            if bottom_channel + handles.n_disp_chans > -handles.vertical_scroll.Min
                handles.vertical_scroll.Value = handles.vertical_scroll.Min;
            else
                handles.vertical_scroll.Value = -(bottom_channel + 1);
            end
            
            % redraw the plot by calling the scroll callback
            cb_scrollbar(handles.vertical_scroll, []);            
            
        case 'g'
          handles.plot_grid = ~handles.plot_grid;
          guidata(object, handles);
          update_main_plot(object);

    end

% check whether the ctrl is pressed also
elseif strcmp(event.Modifier, 'control')
    
    switch event.Key
        case 'c'
            %TODO: pop_up for channel number
            
        case 'uparrow'
            %             fprintf(1, 'more channels \n');
            
        case 'leftarrow'
            % move a little to the left
            set(handles.cPoint, 'Value',...
                get(handles.cPoint, 'Value') - handles.epoch_length/5 * EEG.srate);
            fcn_change_time(object, [])
            
        case 'rightarrow'
            % move a little to the right
            set(handles.cPoint, 'Value',...
                get(handles.cPoint, 'Value') + handles.epoch_length/5 * EEG.srate);
            fcn_change_time(object, [])
    end
    
end


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

% TODO: add original and average reference

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
    'position',     [0.7, 0.05, 0.25, 0.9]  ,...
    'backgroundcolor', [0.1, 0.1, 0.1; 0.2, 0.2, 0.2],...
    'foregroundcolor', [0.9, 0.9, 0.9]      ,...
    'columnName',   {'name','chn','ref'},...
    'columnEditable', [true, true, true]);

% automatically adjust the column width using java handle
jscroll = findjobj(handles.table);
jtable  = jscroll.getViewport.getView;
jtable.setAutoResizeMode(jtable.AUTO_RESIZE_ALL_COLUMNS);


% create the buttons
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

handles.button_apply = uicontrol(...
    'Parent',   handles.fig,...
    'Style',    'push',...    
    'String',   'apply',...
    'ForegroundColor', 'k',...
    'Units',    'normalized',...
    'Position', [0.85 0.075 0.05 0.02],...
    'FontName', 'Century Gothic',...
    'FontWeight', 'bold',...   
    'FontSize', 10);

set(handles.button_apply, 'callback', {@fcn_button_apply});

% set the initial table values
data = cell(length(EEG.csc_montage.label_channels), 3);
% current montage
data(:,1) = deal(EEG.csc_montage.label_channels);
data(:,[2,3]) = num2cell(EEG.csc_montage.channels);

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

if ~isfield(EEG.chanlocs(1), 'x')
   EEG.chanlocs = swa_add2dlocations(EEG.chanlocs); 
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
        'hitTest', 'off');
end

set(handles.plt_markers, 'ButtonDownFcn', {@bdf_select_channel});

guidata(handles.fig, handles);
setappdata(handles.csc_plotter.fig, 'EEG', EEG);

update_net_arrows(handles.fig)

function update_net_arrows(montage_handle)
% get the handles and EEG structure
handles     = guidata(montage_handle);
EEG         = getappdata(handles.csc_plotter.fig, 'EEG');

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
        set(handles.table, 'data', data);
        
    case 'alt'
        data = get(handles.table, 'data');
        ind  = cellfun(@(x) isempty(x), data(:,3));
        data(ind,3) = deal({ch});
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

% get the table data
data = get(handles.table, 'data');

% check the all inputs are valid
if any(any(cellfun(@(x) ~isa(x, 'double'), data(:,[2,3]))))
    fprintf(1, 'Warning: check that all channel inputs are numbers\n');
end

EEG.csc_montage.label_channels  = data(:,1);
EEG.csc_montage.channels        = cell2mat(data(:,[2,3]));

if length(EEG.csc_montage.label_channels) < handles.csc_plotter.n_disp_chans
    handles.csc_plotter.n_disp_chans = length(EEG.csc_montage.label_channels);
    handles.csc_plotter.disp_chans = [1:handles.csc_plotter.n_disp_chans];
    fprintf(1, 'Warning: reduced number of display channels to match montage\n');
end

% Reset hidden channels
handles.csc_plotter.hidden_chans = [];

% update the slider to reflect new montage
handles.csc_plotter.vertical_scroll.Value = -1;
handles.csc_plotter.vertical_scroll.Min = -(EEG.nbchan - length(handles.csc_plotter.disp_chans));

% update the handle structures
guidata(handles.fig, handles);
guidata(handles.csc_plotter.fig, handles.csc_plotter);
setappdata(handles.csc_plotter.fig, 'EEG', EEG);

% update the plot using the scrollbar callback
% update_main_plot(handles.csc_plotter.fig);
cb_scrollbar(handles.csc_plotter.vertical_scroll, []);

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

% set the montage back into the EEG.csc_montage
EEG.csc_montage.name = montage_name;

% check if the empty string was selected
if ~isempty(montage_name) && ~strcmp(montage_name, 'original')
    montage = load(fullfile(montage_dir, montage_name), '-mat');
    if isfield(montage, 'data')
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
if ~strcmp(fileName(end-3: end), '.emo')
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


