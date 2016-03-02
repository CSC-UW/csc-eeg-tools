function [spectral_data, freq_range] = csc_average_reference_and_FFT(EEG, options)

% remove bad channels
% ~~~~~~~~~~~~~~~~~~~
% NOTE: at this point bad channels should have been removed anyways
if ~isempty(options.bad_channels)
    
    % set the bad channel values to NaN
    EEG.data(options.bad_channels, :) = NaN;
    
end


% calculate the average reference if desired
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if options.ave_ref == 1
    
    % use EEGLABs function
    EEG = pop_reref( EEG, [] );

elseif options.ave_ref == 185
    
    % load the channel list for the 185 channel reference
    if exist('inside185.mat', 'file')
        load('inside185.mat', 'file');
    elseif exist('inside185new.mat', 'file')
        load('inside185.mat', 'file');
    else
        [fileName, filePath] = uigetfile('*.mat', 'Cannot find 185 file, please locate it manually');
        load(fullfile(filePath, fileName));
    end
    
    % use EEGLABs function
        %TODO: check for consistency in inside185 variable
    EEG = pop_reref( EEG, inside185,...
        'keepref',  'on'    );
end


% calculate the fft on epoched data
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% calculate the number of samples in each epoch
window_size = floor(EEG.srate * options.epoch_length);
% mod the window size to 2
window_size = floor(window_size / 2) * 2;
% calculate the number of epochs, rounded down
no_epochs = floor(EEG.pnts/ window_size);
% calculate the frequency range
freq_range = EEG.srate * (0 : (window_size / 2)) / window_size;
selected_range = freq_range >= 0 & freq_range < options.freq_limit;
no_bins = sum(selected_range);

% pre_allocate spectral_data
spectral_data = nan(EEG.nbchan, no_bins, no_epochs);

% loop for each individual epoch
csc_progress_indicator('initialise', 'epochs completed');
for epoch_num = 1 : no_epochs
    
    epoch_start = (epoch_num - 1) * window_size + 1;
    epoch_end = epoch_num * window_size;
    
    % run the fft
    fft_estimate = fft(EEG.data(:, epoch_start : epoch_end), [], 2);
    
    fft_estimate = abs(fft_estimate / window_size);
    fft_estimate = fft_estimate(:, 1 : window_size / 2 + 1);
    fft_estimate(:, 2 : end - 1) = 2. * fft_estimate(:, 2 : end - 1);
    spectral_data(:, :, epoch_num) = fft_estimate(:, selected_range);
    
    % update progress
    csc_progress_indicator('update', epoch_num, no_epochs);    
    
end

% edit freq_range to final output
freq_range = freq_range(selected_range);

% save to external file
if options.save_file
    
    % save the file in the current directory
    save(options.save_name, 'spectral_data', 'freq_range', '-v7.3');
    
end

fprintf(1, '\nInformation: FFT calculation complete \n');
