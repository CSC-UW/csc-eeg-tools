function [channel_thresholds, fft_bands] = csc_artifact_rejection_fft_gui(fft_all, freq_range, options)

% set some default options
options.ylimitmax = 1;


% calculate the intial bands
% concatenate the ffts
fft_bands = csc_calculate_freq_bands(fft_all, freq_range, options);

% only select the bands of interest from the fft
fft_bands = fft_bands(:,:, options.bands_of_interest);

% calculate the default percentiles over epochs (dim=2) of each band
thresholds = squeeze(prctile(fft_bands, options.default_percentile, 2));


% create the figure
handles.fig = figure(...
    'name',         'csc fft plotter',...
    'numberTitle',  'off',...
    'color',        [0.1, 0.1, 0.1],...
    'menuBar',      'none',...
    'units',        'normalized',...
    'outerPosition',[0 0.04 .5 0.96]);

set(handles.fig,...
    'KeyPressFcn', {@cb_KeyPressed});
set(handles.fig, ...
    'CloseRequestFcn', {@pb_accept});


% slider for channel navigation
[handles.jslider,handles.slider] = javacomponent(javax.swing.JSlider);
set(handles.slider,...
    'Parent',   handles.fig,...
    'Units',    'normalized',...
    'Position', [0.25 0.875 0.5 0.05]);
handles.jslider.setBackground(javax.swing.plaf.ColorUIResource(0.1,0.1,0.1))

% set slider properties based on the data
handles.jslider.setMinimum(1);
handles.jslider.setMaximum(size(fft_bands, 1));
handles.jslider.setValue(1);


% channel indicator
handles.channel_indicator = uicontrol(...
    'Parent',   handles.fig,...
    'backgroundColor', [0.1, 0.1, 0.1],...
    'foregroundColor', [0.9, 0.9, 0.9],...
    'String',   '1',...
    'Style',    'text',...    
    'Units',    'normalized',...
    'Position', [0.4 .925 0.2 0.05],...
    'FontName', 'Century Gothic',...
    'FontSize', 40);

% calculate axes positions
no_bands = size(fft_bands, 3);
axes_pos_x = linspace(0.05, 0.95, no_bands+1)+0.025;
axes_width = (0.9 / no_bands) - 0.05;

% find the initial y-axis minima & maxima
band_minimum = squeeze(min(min(fft_bands, [], 1), [], 2));
band_maximum = squeeze(max(max(fft_bands, [], 1), [], 2));

% draw axes
for a = 1 : no_bands
    handles.axes(a) = axes(...
        'parent',       handles.fig             ,...
        'position',     [axes_pos_x(a) 0.35, axes_width, 0.5]   ,...
        'nextPlot',     'add'                   ,...
        'color',        [0.2, 0.2, 0.2]         ,...
        'xcolor',       [0.9, 0.9, 0.9]         ,...
        'ycolor',       [0.9, 0.9, 0.9]         ,...
        'fontName',     'Century Gothic'        ,...
        'fontSize',     8                       );
    
    % set the y limits of the axes to be minimal and maximal possible
    if options.ylimitmax
        set(handles.axes(a),...
            'ylim',         [0, band_maximum(a)]);
    end
    
    % set the callback
    set(handles.axes(a), 'buttonDownFcn', {@cb_mark_threshold, a});
end

% set the xlimits of the axes
set(handles.axes, 'xlim', [0, size(fft_bands, 2)]);

% draw spectral axes
handles.spectral_ax = axes(...
        'parent',       handles.fig             ,...
        'position',     [0.075, 0.05, 0.85, 0.2]   ,...
        'nextPlot',     'add'                   ,...
        'color',        [0.2, 0.2, 0.2]         ,...
        'xcolor',       [0.9, 0.9, 0.9]         ,...
        'ycolor',       [0.9, 0.9, 0.9]         ,...
        'fontName',     'Century Gothic'        ,...
        'fontSize',     8                       );


% push button to reset channel threshold
handles.pb_accept = uicontrol(...
    'Parent',   handles.fig,...   
    'Style',    'pushbutton',...    
    'String',   'reset',...
    'Units',    'normalized',...
    'Position', [0.1 .875 0.1 0.05],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.pb_accept, 'Callback', {@pb_accept})

% push button to finish editing thresholds
handles.pb_accept = uicontrol(...fft_bands
    'Parent',   handles.fig,...   
    'Style',    'pushbutton',...    
    'String',   'done',...
    'Units',    'normalized',...
    'Position', [0.8 .875 0.1 0.05],...
    'FontName', 'Century Gothic',...
    'FontSize', 11);
set(handles.pb_accept, 'Callback', {@pb_accept})


% set the data into the figure structure
guidata(handles.fig, handles);
setappdata(handles.fig, 'fft_all', fft_all);
setappdata(handles.fig, 'freq_range', freq_range);
setappdata(handles.fig, 'fft_bands', fft_bands);
setappdata(handles.fig, 'thresholds', thresholds);

% plot the initial data
fcn_initial_plot(handles.fig);

% use waitfor the window to close to postpone variable output
uiwait(handles.fig);

% once uiwait resumes get the most current thresholds
channel_thresholds = getappdata(handles.fig, 'thresholds');
fft_bands = getappdata(handles.fig, 'fft_bands');

% and delete the figure
delete (handles.fig);


function fcn_initial_plot(object)
% initial plot of the channels

% get the handles structure
handles = guidata(object);

% get the data
fft_bands = getappdata(handles.fig, 'fft_bands');
thresholds = getappdata(handles.fig, 'thresholds');
fft_all = getappdata(handles.fig, 'fft_all');
freq_range = getappdata(handles.fig, 'freq_range');

% always plot the first channel in the initial plot
nCh = 1;

% loop plot the channel for each band on the appropriate axes
for b = 1:size(fft_bands, 3);
    % plot the data
    handles.plot(b) = plot(fft_bands(nCh,:,b),...channel_thresholds
        'parent',   handles.axes(b), ...
        'color',    [0.8, 0.8, 0.8]);
   
    % plot the default threshold line
    handles.threshold_line(b) = line(...
        'parent', handles.axes(b), ...
        'xdata', [0, size(fft_bands, 2)], ...
        'ydata', [thresholds(nCh, b), thresholds(nCh, b)], ...
        'lineStyle', '--',  ...
        'lineWidth', 2,     ...
        'color', [0.8, 0.5, 0.5] );
    
   % create the x/y labels
   handles.labels(1,b) = xlabel(handles.axes(b), 'Epochs');
   handles.labels(2,b) = ylabel(handles.axes(b), 'FFT Power');
 
end

% set the label properties
set(handles.labels,...
    'fontSize', 14, ...
    'interpreter', 'latex');


% calculate the original spectrum
original_spectra = sqrt(mean(fft_all(nCh, :, :) .^2 , 3));

% calculate the "thresholded" spectrum
currently_good_epochs = ...
    fft_bands(nCh, :, 1) < thresholds(nCh, 1) | ...
    fft_bands(nCh, :, 2) < thresholds(nCh, 2);
thresholded_spectra = sqrt(mean(fft_all(nCh, :, currently_good_epochs) .^2 , 3));

% plot the overall spectrum
flag_log = true;
if flag_log
    handles.original_spectra = plot(freq_range, log(original_spectra), ...
        'parent', handles.spectral_ax, ...
        'color', [0.4, 0.4, 0.4], ...
        'lineWidth', 6);
    
    handles.thresholded_spectra = plot(freq_range, log(thresholded_spectra), ...
        'parent', handles.spectral_ax, ...
        'color', [0.8, 0.8, 0.8], ...
        'lineWidth', 1);
end

% set the handles structure
guidata(handles.fig, handles);


function fcn_update_plots(object)
% fast update of the ydata in the plots

% get the handles structure
handles = guidata(object);

% get the data
fft_bands = getappdata(handles.fig, 'fft_bands');
thresholds = getappdata(handles.fig, 'thresholds');

% get the current channel
nCh = handles.jslider.getValue();

% loop for replotting
for b = 1:size(fft_bands, 3)

   set(handles.plot(b),...
       'ydata', fft_bands(nCh,:,b));
    
   set(handles.threshold_line(b),...
       'ydata', [thresholds(nCh, b), thresholds(nCh, b)]);
end

% update the channel indicator
set(handles.channel_indicator, 'string', num2str(nCh));

function fcn_update_spectra(object)
% fast update of the thresholded ydata in the spectrum

% get the GUI figure handles
handles = guidata(object);

% get the data
fft_bands = getappdata(handles.fig, 'fft_bands');
thresholds = getappdata(handles.fig, 'thresholds');
fft_all = getappdata(handles.fig, 'fft_all');

% get the current channel
nCh = handles.jslider.getValue();

% calculate the original spectrum
original_spectra = sqrt(mean(fft_all(nCh, :, :) .^2 , 3));

% calculate the "thresholded" spectrum
currently_good_epochs = not(...
    fft_bands(nCh, :, 1) > thresholds(nCh, 1) | ...
    fft_bands(nCh, :, 2) > thresholds(nCh, 2));
thresholded_spectra = sqrt(mean(fft_all(nCh, :, currently_good_epochs) .^2 , 3));

% replace the spectrum
flag_log = true;
if flag_log   
    set(handles.original_spectra, 'ydata', log(original_spectra));
    set(handles.thresholded_spectra, 'ydata', log(thresholded_spectra));
end


function cb_KeyPressed(object, eventdata)
% callback function when the keyboard is pressed

% get the GUI figure handles
handles = guidata(object);

% get the current channel
nCh = handles.jslider.getValue();

% movement keys
switch eventdata.Key
    case 'leftarrow'
        % move to the last channel if not at the beginning
        if nCh > 1
            handles.jslider.setValue(nCh-1);
        end
        
        % update the plots
        fcn_update_plots(object);
        fcn_update_spectra(object)

        
    case 'rightarrow'
        % move to the next wave if not at the end
        if nCh < handles.jslider.getMaximum
            handles.jslider.setValue(nCh+1);
        end

        % update the plots
        fcn_update_plots(object);
        fcn_update_spectra(object)

    case 'uparrow'
        current_limits = get(handles.axes, 'ylim');

        % set each axes individually
        for n = 1:length(current_limits) 
            set(handles.axes(n), 'ylim', [0, current_limits{n}(2) / 1.3]);
        end
        
    case 'downarrow'
        current_limits = get(handles.axes, 'ylim');

        % set each axes individually
        for n = 1:length(current_limits) 
            set(handles.axes(n), 'ylim', [0, current_limits{n}(2) * 1.3]);
        end
end



function cb_mark_threshold(object, ~, band)
% callback to adjust the threshold on the axes

% get the GUI figure handles
handles = guidata(object);

% get the data
thresholds = getappdata(handles.fig, 'thresholds');

% get the current channel
nCh = handles.jslider.getValue;

% get the mouse click position
current_point = get(handles.axes(band), 'currentPoint');

% get the new threshold
new_threshold = current_point(1, 2);

% set the new threshold 
thresholds(nCh, band) = new_threshold;

% put the thresholds back in the gui
setappdata(handles.fig, 'thresholds', thresholds);

% update the axes
fcn_update_plots(object);
fcn_update_spectra(object);


function pb_accept(~, ~)
uiresume;