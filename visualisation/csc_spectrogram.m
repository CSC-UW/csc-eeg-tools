function csc_spectrogram
% plot the spectogram
% ^^^^^^^^^^^^^^^^^^^
% find the desired channel
channel_name = 'E81';
channel_id = find(strcmp({EEG.chanlocs.labels}, channel_name));

% get channel data
channel_data = EEG.data(channel_id, :);

% remove bad data
channel_data(:, EEG.bad_data) = 0;

% calculate the spectrogram
window_length = 2; 
[fft, freq_range, time_range, psd] = spectrogram(...
    channel_data, ... % the data
    EEG.srate * window_length, ... % the window size
    EEG.srate * window_length/2, ... % the overlap
    EEG.srate * window_length, ... % number of points (no buffer)
    EEG.srate, ... % sampling rate
    'yaxis');
    
% define frequency limits to plot
freq_ind = freq_range < 50;

% smooth the psd
smoothed_psd = imgaussfilt(log(psd(freq_ind, :)), 1.5);

% plot the spectrogram
handles.fig = figure('color', 'w');
handles.ax = axes('nextPlot', 'add');
handles.contour = contourf(time_range, freq_range(freq_ind), ...
    smoothed_psd, 7, ...
    'lineStyle', 'none');

% put little tick marks at the events
% events_to_plot = [1, 2, 4, 5, 7, 8, 10, 11];
events_to_plot = [1:length(EEG.event)];
for n = 1 : length(events_to_plot)
    
    plot(EEG.event(events_to_plot(n)).latency / EEG.srate, 45,...
        'lineStyle', 'none',...
        'marker', 'v',...
        'markerSize', 15,...
        'markerEdgeColor', [0.9, 0.9, 0.9],...
        'markerFaceColor', [0.2, 0.2, 0.2]);
end

% turn time in hours/minutes
tick_samples = get(handles.ax, 'XTick');
tick_times = seconds(tick_samples);
tick_labels = cellstr(char(tick_times, 'hh:mm:ss'));
set(handles.ax, 'XTickLabels', tick_labels);

% export to image
export_fig(gcf, ['nde_spec'], '-jpg', '-m3');