function bad_epochs = csc_artifact_detection_fft(fft_all, freq_range, options)
% plot the fft power of each channel for each epoch and find samples above
% the manually set threshold

% plot the channels and bands of interest
if strcmp(options.method, 'semi_automatic')
    
    [channel_thresholds, fft_bands] = csc_artifact_rejection_fft_gui(fft_all, freq_range, options);
    
else
    
    % concatenate the ffts
    fft_bands = csc_calculate_freq_bands(fft_all, freq_range, options);
    
    % only select the bands of interest from the fft
    fft_bands = fft_bands(:,:, options.bands_of_interest);

    % calculate the default percentiles over epochs (dim=2) of each band
    channel_thresholds = squeeze(prctile(fft_bands, options.default_percentile, 2));
    
end

% create threshold matrix
threshold_matrix = repmat(channel_thresholds, [size(fft_bands, 2), 1]);
threshold_matrix = reshape(threshold_matrix, size(fft_bands));

% find the above threshold samples
bad_epochs = fft_bands > threshold_matrix;

% % find samples with minimum number above threshold epochs
% % TODO: provide minimum number of channels
% bad_epochs = any(sum(bad_epochs, 3), 1);
    