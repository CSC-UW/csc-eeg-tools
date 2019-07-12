function [norm_data, time_points] = csc_epoched_fft(EEG, selected_channel, epoch_length)
% calculate the delta/beta power ratio for a selected channel and specified epoch length
% output data will have single-sided z-score with 1 unit = 1 median absolute deviation

% default options
if nargin < 2
    selected_channel = 3;
end
if nargin < 3
    epoch_length = 30;
end

% manually define the borders of frequency ranges
delta_range = [1, 4];
beta_range = [18, 25];

% calculate spectral
window_size = 1; % size of p_welch window in seconds
spectral_window = floor(EEG.srate * window_size); % 1 second windows
spectral_overlap = floor(spectral_window / 2);  % 50% overlap
n_epochs = floor(EEG.pnts / (epoch_length * EEG.srate));

% calculate the starting sample of each epoch
time_points = linspace(1, n_epochs * epoch_length * EEG.srate, n_epochs);

% reshape single channel into epoched matrix (i.e. pretend that the epochs are different channels :)
% NOTE: need to cut off the ending data that doesn't add up to a whole epoch
temp_data = EEG.data(selected_channel, (1 : n_epochs * epoch_length * EEG.srate));
temp_data = reshape(temp_data, [], n_epochs);

% calculate the spectral power using the pwelch method
[spectral_data, freq_range] = pwelch(...
    temp_data, ... % epoched data
    hanning(spectral_window) ,... % window length
    spectral_overlap ,... % overlap
    spectral_window ,... % points in calculation (window length)
    EEG.srate ); % sampling rate

% calculate delta beta bins
delta_bins = freq_range >= delta_range(1) & freq_range <= delta_range(2);
beta_bins = freq_range >= beta_range(1) & freq_range <= beta_range(2);

% average power for each epoch calculated using the root-mean-square
delta_beta = rms(spectral_data(delta_bins, :)) ./ rms(spectral_data(beta_bins, :));

% normalize logged-10 values with 1 unit as 1 'mad'
norm_data = log10(delta_beta) - min(log10(delta_beta));
data_mad = mad(norm_data);
norm_data = norm_data ./ data_mad;
