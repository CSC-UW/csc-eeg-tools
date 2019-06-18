function EEG = csc_ecg_removal(EEG, eeg_channels, ecg_channel, flag_plot)
% exploration of using ecg channel to directly remove the artefact from eeg
% EEG = csc_ecg_removal(EEG, [3:10], 13, 1);
% warning: you may have to manual switch polarity:
% 

if nargin < 4
    flag_plot = true;
end

% find ecg peaks
[ecg_ind, ~] = ...
    csc_heart_beat_detection(EEG.data(ecg_channel, :), EEG.srate, ...
    600, 1, flag_plot);

% interpolate data at each QRS
time_window = 0.035;
interp_start = ecg_ind.R - floor(EEG.srate * time_window);
interp_end = ecg_ind.R + floor(EEG.srate * time_window);

% create all indices
interp_range = floor(EEG.srate * time_window); 
interp_inds = bsxfun(@plus, ecg_ind.R(:), -interp_range : interp_range); 

% just loop it (I'm sure there's a vector way)
data_interp = nan(length(eeg_channels), interp_range * 2 + 1);
data_copy = EEG.data(eeg_channels, :);

swa_progress_indicator('initiate', 'number of peaks');
for n = 1 : length(ecg_ind.R)
    swa_progress_indicator('update', n, length(ecg_ind.R));
    
    data_start = EEG.data(eeg_channels, ecg_ind.R(n) - interp_range);
    data_end = EEG.data(eeg_channels, ecg_ind.R(n) + interp_range);
    
    for m = 1 : length(eeg_channels)
        data_interp(m, :) = linspace(data_start(m), data_end(m), interp_range * 2 + 1);
    end
    
    data_copy(:, interp_start(n) : interp_end(n)) = data_interp;
end


% plot selected channels
if flag_plot
    
    % random sample
    window_length = 10;
    chan_sel = 2;
    rand_samples = randi(EEG.pnts - window_length * EEG.srate, 1);
    samples_range = rand_samples + (1 : window_length * EEG.srate);
    time_range = samples_range / EEG.srate;
    
    % prepare figure
    handles.fig = figure('color', 'w');
    handles.main_ax = axes('nextplot', 'add', ...
        'xlim', [time_range(1), time_range(end)]);
    
    % plot first eeg channel
    handles.lines(1) = plot(time_range, EEG.data(eeg_channels(chan_sel), samples_range), ...
        'linewidth', 3, ...
        'color', [0.7, 0.7, 0.7]);
    
    % plot ecg removed data
    handles.lines(2) = plot(time_range, data_copy(chan_sel, samples_range), ...
        'linewidth', 2, ...
        'color', [0.3, 0.3, 0.3]);   
    
end


% map back onto the data
EEG.data(eeg_channels, :) = data_copy;
