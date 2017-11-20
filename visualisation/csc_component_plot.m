function component_list = csc_component_plot(EEG)
% function to plot properties of a component and accept or reject them

% make the figure
handles = define_interface();

% options
handles.opt.freq_max = 45;

% check for good channels field in EEG
if ~isfield(EEG, 'good_channels')
    EEG.good_channels = true(EEG.nbchan, 1);
end

% check for marked bad_data
if ~isfield(EEG, 'bad_data')
   EEG.bad_data = false(1, EEG.pnts);   
end

% check for good trials
if ~isfield(EEG, 'good_trials')
   EEG.good_trials = true(1, EEG.trials);   
end

% check for EEG.icaact
if isempty(EEG.icaact)
    fprintf(1, 'recalculating EEG.icaact...\n')
    EEG.icaact = (EEG.icaweights * EEG.icasphere) ...
        * EEG.data(EEG.icachansind, :);
    % convert to trials if necessary
    if EEG.trials > 1
        EEG.icaact = reshape(EEG.icaact, [size(EEG.icaweights, 1), EEG.pnts, EEG.trials]);
    end
end

% save the EEG to the figure
setappdata(handles.fig, 'EEG', EEG);  

% allocate the component list from scratch

% TODO: look for previously run good_components and put on component list
if isfield(EEG, 'good_components')
    handles.component_list = EEG.good_components;
else
    number_components = size(EEG.icaact, 1);
    handles.component_list = true(number_components, 1);
end

% set some specific properties from the data
set([handles.ax_erp_time, handles.ax_erp_image],...
    'xlim', [EEG.times(1), EEG.times(end)] / 1000);

% check if trialed data
if EEG.trials > 1
    ica_data = reshape(EEG.icaact(:, :, EEG.good_trials), ...
        size(EEG.icaact, 1), []);
else
    ica_data = EEG.icaact;
end

% run the frequency analysis on all components at once
% use pwelch
fprintf(1, 'Computing frequency spectrum for all components\n');
window_length = 5 * EEG.srate;
[spectral_data, spectral_range] = pwelch(...
    ica_data' ,... % data (transposed to channels are columns)
    hanning(window_length) ,...    % window length with hanning windowing
    floor(window_length / 2) , ...   % overlap
    window_length ,...    % points in calculation (window length)
    EEG.srate);            % sampling rate
    
% eliminate filtered frequencies
handles.spectral_range = spectral_range(spectral_range < handles.opt.freq_max);
handles.spectral_data = spectral_data(spectral_range < handles.opt.freq_max, :, :)';

% update the figure handles
guidata(handles.fig, handles)
    
% initial plot
initial_plots(handles.fig);

% if an output is expected, wait for the figure to close
if nargout > 0
    uiwait(handles.fig);
    
    % get the handles structure
    handles = guidata(handles.fig);
    
    % get the output of the struct
    component_list = handles.component_list;

    % close the figure
    delete(handles.fig);    
end


function handles = define_interface()

% make a window
% ~~~~~~~~~~~~~
handles.fig = figure(...
    'name',         'csc component plotter',...
    'numberTitle',  'off',...
    'color',        [0.1, 0.1, 0.1],...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.5 0.25 0.5]);

set(handles.fig, 'closeRequestFcn', {@fcn_close_window});

% make the axes
% ~~~~~~~~~~~~~
% topoplot_axes
handles.ax_topoplot = axes(...
    'parent',       handles.fig ,...
    'position',     [0.05 0.55, 0.4, 0.4] ,...
    'nextPlot',     'add' ,...
    'color',        [0.1, 0.1, 0.1] ,...
    'xcolor',       [0.1, 0.1, 0.1] ,...
    'ycolor',       [0.1, 0.1, 0.1] ,...
    'xtick',        [] ,...
    'ytick',        [] ,...
    'fontName',     'Century Gothic' ,...
    'fontSize',     8 );

% erp axes
handles.ax_erp_image = axes(...
    'parent',       handles.fig ,...
    'position',     [0.55 0.7, 0.4, 0.25] ,...
    'nextPlot',     'add' ,...
    'color',        [0.2, 0.2, 0.2] ,...
    'xcolor',       [0.9, 0.9, 0.9] ,...
    'ycolor',       [0.9, 0.9, 0.9] ,...
    'xtick',        [] ,...
    'ytick',        [] ,...
    'fontName',     'Century Gothic' ,...
    'fontSize',     8 );

handles.ax_erp_time = axes(...
    'parent',       handles.fig ,...
    'position',     [0.55 0.55, 0.4, 0.1] ,...
    'nextPlot',     'add' ,...
    'color',        [0.2, 0.2, 0.2] ,...
    'xcolor',       [0.9, 0.9, 0.9] ,...
    'ycolor',       [0.9, 0.9, 0.9] ,...
    'ytick',        [] ,...
    'fontName',     'Century Gothic' ,...
    'fontSize',     8 );

% spectra axes
handles.ax_spectra = axes(...
    'parent',       handles.fig ,...
    'position',     [0.05 0.05, 0.9, 0.3] ,...
    'nextPlot',     'add' ,...
    'color',        [0.2, 0.2, 0.2] ,...
    'xcolor',       [0.9, 0.9, 0.9] ,...
    'ycolor',       [0.9, 0.9, 0.9] ,...
    'ytick',        [] ,...
    'fontName',     'Century Gothic' ,...
    'fontSize',     8 );


% plot the spinner
% ~~~~~~~~~~~~~~~~
[handles.java.spinner, handles.spinner] = ...
    javacomponent(javax.swing.JSpinner);

set(handles.spinner,...
    'parent',   handles.fig,...      
    'units',    'normalized',...
    'position', [0.45 0.425 0.1 0.05]);
% Set the font and size (Found through >>handles.java.Slider.Font)
handles.java.spinner.setFont(javax.swing.plaf.FontUIResource('Century Gothic', 0, 25))
handles.java.spinner.getEditor().getTextField().setHorizontalAlignment(javax.swing.SwingConstants.CENTER)
handles.java.spinner.setValue(1);
set(handles.java.spinner, 'StateChangedCallback', {@cb_change_component, handles.fig});


% plot button
% ~~~~~~~~~~~
handles.ax_button = axes(...
    'parent',       handles.fig ,...
    'position',     [0.65 0.425, 0.05, 0.05] ,...
    'nextPlot',     'add' ,...
    'PlotBoxAspectRatio', [1, 1, 1] ,...
    'xlim',         [0, 1] ,...
    'ylim',         [0, 1] ,...
    'visible',      'off' ,...
    'fontName',     'Century Gothic' ,...
    'fontSize',     8 );

handles.button = rectangle(...
    'position', [0, 0, 1, 1],...
    'curvature', [1, 1] ,...
    'parent', handles.ax_button,...
    'faceColor', [0, 1, 0] ,...
    'edgeColor', [0.9, 0.9, 0.9] ,...
    'userData', 1 ,...
    'buttonDownFcn', {@cb_accept_reject});

% plot titles
% ~~~~~~~~~~~
handles.title_topo = uicontrol(...
    'style',    'text',...
    'string',   'topography',...
    'parent',   handles.fig,...
    'units',    'normalized',...
    'position', [0.05 0.95, 0.4, 0.025] ,...
    'backgroundColor', [0.1, 0.1, 0.1] ,...  
    'foregroundColor', [0.9, 0.9, 0.9] ,...
    'fontName', 'Century Gothic',...
    'fontSize', 11);

handles.title_image = uicontrol(...
    'style',    'text',...
    'string',   'trial activity',...
    'parent',   handles.fig,...
    'units',    'normalized',...
    'position', [0.55 0.95, 0.4, 0.025] ,...
    'backgroundColor', [0.1, 0.1, 0.1] ,...  
    'foregroundColor', [0.9, 0.9, 0.9] ,...
    'fontName', 'Century Gothic',...
    'fontSize', 11);

handles.title_erp = uicontrol(...
    'style',    'text',...
    'string',   'evoked potential',...
    'parent',   handles.fig,...
    'units',    'normalized',...
    'position', [0.55 0.65, 0.4, 0.025] ,...
    'backgroundColor', [0.1, 0.1, 0.1] ,...  
    'foregroundColor', [0.9, 0.9, 0.9] ,...
    'fontName', 'Century Gothic',...
    'fontSize', 11);

handles.title_erp = uicontrol(...
    'style',    'text',...
    'string',   'power spectra',...
    'parent',   handles.fig,...
    'units',    'normalized',...
    'position', [0.05 0.35, 0.9, 0.025] ,...
    'backgroundColor', [0.1, 0.1, 0.1] ,...  
    'foregroundColor', [0.9, 0.9, 0.9] ,...
    'fontName', 'Century Gothic',...
    'fontSize', 11);

handles.title_spectra = uicontrol(...
    'style',    'text',...
    'string',   'power spectra',...
    'parent',   handles.fig,...
    'units',    'normalized',...
    'position', [0.05 0.35, 0.9, 0.025] ,...
    'backgroundColor', [0.1, 0.1, 0.1] ,...  
    'foregroundColor', [0.9, 0.9, 0.9] ,...
    'fontName', 'Century Gothic',...
    'fontSize', 11);


function initial_plots(object)
% get the handles structure
handles = guidata(object);

% get the data
EEG = getappdata(handles.fig, 'EEG');

% component number
no_comp = 1;

% update the button
if handles.component_list(no_comp)
    % turn button green
    set(handles.button, 'faceColor', [0, 1, 0]);
else
    % turn button red
    set(handles.button, 'faceColor', [1, 0, 0]);
end

% ---------------------------- %
% plot the image of all trials %
% ---------------------------- %
trials_image = squeeze(EEG.icaact(no_comp, :, :))';
% turn lost trials into nans
trials_image(~EEG.good_trials, :) = nan;
handles.plots.image = ...
    imagesc(EEG.times / 1000, 1 : EEG.trials, ...
    trials_image, ...
    'parent', handles.ax_erp_image);

% ------------------------- %
% plot the evoked potential %
% ------------------------- %
data_to_plot = mean(EEG.icaact(no_comp, : , EEG.good_trials), 3)';

if isfield(EEG, 'bad_data')
    data_to_plot(EEG.bad_data) = nan;
elseif isfield(EEG, 'good_data')
    data_to_plot(~EEG.good_data) = nan;
end

handles.plots.erp_time = ...
    plot(handles.ax_erp_time,...
    EEG.times / 1000, data_to_plot,...
    'color', [0.9, 0.9, 0.9] ,...
    'lineWidth', 2);

% --------------------- %
% get the power spectra %
% --------------------- %
fft_data = handles.spectral_data(no_comp, :);

% normalise the fft by 1/f
fft_data = fft_data.* handles.spectral_range';

% plot the spectra
handles.plots.spectra = ...
    plot(handles.ax_spectra ,...
    handles.spectral_range, fft_data ,...
    'color', [0.9, 0.9, 0.9] ,...
    'lineWidth', 2);

% ------------------- %
% plot the topography %
% ------------------- %
handles.plots.topo = ...
    csc_Topoplot(EEG.icawinv(EEG.good_channels, no_comp), EEG.chanlocs(EEG.good_channels) ,...
    'axes', handles.ax_topoplot ,...
    'plotChannels', false);

% update the handles
guidata(handles.fig, handles)


function cb_change_component(~, ~, object)
% get the handles structure
handles = guidata(object);

% get the data
EEG = getappdata(handles.fig, 'EEG');

% check the current value
current_component = handles.java.spinner.getValue();
max_component = size(EEG.icaact, 1);

if current_component > max_component
    handles.java.spinner.setValue(max_component);
    return;
elseif current_component < 1
    handles.java.spinner.setValue(1);
    return;
end

% update the plots
update_plots(handles.fig)


function update_plots(object)
% get the handles structure
handles = guidata(object);

% get the data
EEG = getappdata(handles.fig, 'EEG');

% get the current value
current_component = handles.java.spinner.getValue();

% update the button
if handles.component_list(current_component)
    % turn button green
    set(handles.button, 'faceColor', [0, 1, 0]);
else
    % turn button red
    set(handles.button, 'faceColor', [1, 0, 0]);
end

% re-set the image of all trials %
trials_image = squeeze(EEG.icaact(current_component, :, :))';
trials_image(~EEG.good_trials, :) = nan;
set(handles.plots.image, ...
    'cData', trials_image);
% re-adjust the axes limits to match image percentiles
set(handles.ax_erp_image, 'CLim', [prctile(trials_image(:), 2), prctile(trials_image(:), 98)]);

% re-set the evoked potential %
data_to_plot = mean(EEG.icaact(current_component, : , EEG.good_trials), 3)';
data_to_plot(EEG.bad_data) = nan;
set(handles.plots.erp_time, ...
    'ydata', data_to_plot);

% re-set the power spectra %
fft_data = handles.spectral_data(current_component, :);
% normalise the fft by 1/f
fft_data = fft_data.* handles.spectral_range';
% plot the spectra
set(handles.plots.spectra, ...
    'ydata', fft_data);

% ------------------- %
% plot the topography %
% ------------------- %
current_topo_data = EEG.icawinv(EEG.good_channels, current_component);
handles.plots.topo = ...
    csc_Topoplot(current_topo_data, EEG.chanlocs(EEG.good_channels),...
    'axes', handles.ax_topoplot ,...
    'plotChannels', false);

% adjust the color limits
set(handles.plots.topo.CurrentAxes, 'CLim', [min(current_topo_data), max(current_topo_data)]);

guidata(handles.fig, handles)


function cb_accept_reject(object, ~)
% get the handles structure
handles = guidata(object);

% component number
current_component = handles.java.spinner.getValue();

% change the current value;
if handles.component_list(current_component)
    handles.component_list(current_component) = false;
    % turn button red
    set(object, 'faceColor', [1, 0, 0]);
else
    handles.component_list(current_component) = true;
    % turn button green
    set(object, 'faceColor', [0, 1, 0]);
end

% plotting component projections
plotter_fig_handle = findobj('Type', 'Figure', '-and', 'Name', 'csc EEG Plotter');

if ~isempty(plotter_fig_handle)
       
    % get the guidata from the handles
    plotter_handles = guidata(plotter_fig_handle);
    
    % change some property
    plotter_handles.component_projection = 1;
    
    % get EEG from plotter
    EEG_in_plotter = getappdata(plotter_handles.fig, 'EEG');
    
    % change good components
    EEG_in_plotter.good_components = handles.component_list;
    
    % put the EEG back
    setappdata(plotter_handles.fig, 'EEG', EEG_in_plotter);
    
    % update the guidata
    guidata(plotter_handles.fig, plotter_handles)
    
    % update the figure
    plotter_handles.update_axes(plotter_handles.fig, 0)
end

% update the handles
guidata(handles.fig, handles)


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