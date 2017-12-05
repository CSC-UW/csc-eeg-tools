function [wavelet_series, freq_range, trial_wavelet] = csc_ersp_analysis(EEG, flag_plot)
% function similar to newtimef with matlab's own continuous wavelet transform

% returns the event-related spectral perturbation in decible (10 * log10), after
% mean normalisation, and baseline correction, squared/square root averaging of
% individual trials

if nargin < 2
    flag_plot = false;
end

% define options
flag_baseline = 'difference'; % 'difference' | 'ratio'


% remove bad trials
if isfield (EEG, 'good_trials')
    EEG.data = EEG.data(:, :, EEG.good_trials);
    EEG.trials = sum(EEG.good_trials);
end

% define baseline period
baseline_period = EEG.times >= -400 & EEG.times <= -100;
normalisation_period = EEG.times >= -600 & EEG.times <= 600;

% run single trial to get output sizes
[~, freq_range, ~] = cwt(...
    double(EEG.data(1, :, 1)), ...
    'amor', EEG.srate);
no_freqs = length(freq_range);     
        
% pre-allocate wavelet_series
trial_wavelet = nan(no_freqs, EEG.pnts, EEG.trials);
wavelet_series = nan(no_freqs, EEG.nbchan, EEG.pnts);

% loop over all trials and channels and keep the mean
swa_progress_indicator('initialise', 'number of trials complete');
for nCh = 1 : EEG.nbchan
    swa_progress_indicator('update', nCh, EEG.nbchan);

    for nT = 1 : EEG.trials
        trial_wavelet(:, :, nT) = cwt(...
            double(EEG.data(nCh, :, nT)), ...
            'amor', EEG.srate);
    end
    
    % calculate wavelet power
    wavelet_power = trial_wavelet .* conj(trial_wavelet);
    
    % normalise by full time series mean (like newtimef
    % NOTE: each trial has its own mean
    % TODO: explore whether trial or whole series normalisation is better
    mean_wavelet_power = mean(wavelet_power(:, normalisation_period, :), 2);
    norm_wavelet_power = wavelet_power ...
        ./repmat(mean_wavelet_power, [1, size(wavelet_power, 2), 1] );
    
    % calculate the trial by trial baseline
    trial_baseline = mean(norm_wavelet_power(:, baseline_period, :), 2);
    
    % calculate overall baseline mean
    % NOTE: baseline taken from averaged time series
    temp_mean = mean(norm_wavelet_power, 3);
    overall_baseline = mean(temp_mean(:, baseline_period), 2);
    
    switch flag_baseline
        case 'difference'
            % trial minus the trial baseline
            corrected_wavelet = norm_wavelet_power ...
                - trial_baseline(:, ones(EEG.pnts, 1), :);
            
        case 'ratio'
            % or divide by overall baseline (like newtimef)
            corrected_wavelet = bsxfun(@rdivide, norm_wavelet_power, overall_baseline);
    end
      
    % get the absolute mean (newtimef just takes the mean directly)
    wavelet_mean = sqrt(mean(corrected_wavelet .^ 2, 3)); 
    
    % log transform in db
    wavelet_series(:, nCh, :) = 10 * log10(wavelet_mean);
end
    
% contour plot of example channel's results.
if flag_plot
   
    selected_channel = 1;
    selected_freqs = freq_range < 50;
    
    figure('color', 'w');
    contourf(EEG.times(normalisation_period), freq_range(selected_freqs), ...
        squeeze(wavelet_series(selected_freqs, selected_channel, normalisation_period)), ...
        'linestyle', 'none');
    
end