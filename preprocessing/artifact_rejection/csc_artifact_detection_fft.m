function bad_epochs = csc_artifact_detection_fft(fft_bands, bands_of_interest, method)
% plot the fft power of each channel for each epoch and find samples above
% the manually set threshold

% specify parameters
    %TODO: make these parameters options
default_percentile = 99;

% only select the bands of interest from the fft
fft_bands = fft_bands(:,:, bands_of_interest);

% calculate the default percentiles over epochs (dim=2) of each band
channel_thresholds = squeeze(prctile(fft_bands, default_percentile, 2));

% plot the channels and bands of interest
if strcmp(method, 'semi_automatic')
    
    channel_thresholds = csc_artifact_rejection_fft_gui(fft_bands, channel_thresholds);
       
end

% create threshold matrix
threshold_matrix = repmat(channel_thresholds, [size(fft_bands, 2), 1]);
threshold_matrix = reshape(threshold_matrix, size(fft_bands));

% find the above threshold samples
bad_channel_epoch_bands = fft_bands > threshold_matrix;

% find samples with minimum number above threshold epochs
    %TODO: provide minimum number of channels
bad_epochs = any(sum(bad_channel_epoch_bands, 3), 1);
    