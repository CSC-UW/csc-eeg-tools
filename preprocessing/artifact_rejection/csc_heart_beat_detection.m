function [ecg_ind, filt_data] = pnn_heart_beat_detection(data, srate, threshold, flag_filter, flag_plot)
% heart beat detection

% polyfit detrending doesn't work well at all with long signal
if 0
    
    % get number of samples
    n_samples = length(data);
    
    % fit a low-order polynomial to the data
    [p,s,mu] = polyfit((1:n_samples), data, 2);
    trend = polyval(p,(1:n_samples), [], mu);
    
    % detrend the data by substracting the line
    filt_data = data - trend;
    
    % plot the difference
    sample_range = 121400:122000;
    plot(sample_range, data(sample_range));
    hold on;
    plot(sample_range, filt_data(sample_range));
end

if flag_filter
    % detrend using low-pass filter
    fhc = 0.3/(srate/2);
    flc = 40/(srate/2);
    
    [b1, a1] = butter(2, fhc, 'high');
    [b2, a2] = butter(2, flc, 'low');
    
    filt_data = filtfilt(b1, a1, double(data));
    filt_data = (filtfilt(b2, a2, filt_data))';
    
else
    
    filt_data = data;
    
end


% interwave distance
iwd = 0.5 * srate;

[~, ecg_ind.R] = findpeaks(filt_data,...
    'MinPeakHeight', threshold,...
    'MinPeakDistance', iwd);

if isempty(ecg_ind)
    return;
end

% [~, ecg_ind.S] = findpeaks(-filt_data,...
%     'MinPeakHeight', 250,...
%     'MinPeakDistance', iwd);

if flag_plot
    
    % find random point
    random_wave = ecg_ind.R(randi(length(ecg_ind.R), 1));
    
    % define random sample range
    sample_range = random_wave - 5 * srate : random_wave + 10 * srate;

    figure('color', 'w');
    axes('nextplot', 'add');
    plot(sample_range, filt_data(sample_range));
    
    R2plot = ecg_ind.R(ismember([ecg_ind.R], sample_range));
    
    plot(R2plot, threshold, ':rv',...
        'markersize', 10, ...
        'markerFaceColor', 'r');
    
end