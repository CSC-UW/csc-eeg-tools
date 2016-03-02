function fft_bands = csc_calculate_freq_bands(fft_all, freq_range, options)
% concatenates all the ffts from the input into one large variable

% define the frequency bands of interest
% TODO: specify bands in the options input
freq_bands =   [0.5, 4 ;
                5,   8 ;
                8,  12 ;
                12, 16 ;
                16, 25 ];

% calculate the power of the specified frequencies
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% pre-allocate the range
number_bands = size(freq_bands, 1);
fft_bands = zeros(size(fft_all, 1), size(fft_all, 3), number_bands);

% loop over each band and average the frequencies
for b = 1:number_bands
   range = freq_range >= freq_bands(b, 1)  &  freq_range <= freq_bands(b, 2);
   fft_bands(:, :, b) = squeeze(nanmean(fft_all(:, range, :), 2));
end

% save to an external file if requested
if options.save_file
    
    % append to the already saved file
    save(options.save_name, 'fft_bands', '-v7.3', '-append');

end
