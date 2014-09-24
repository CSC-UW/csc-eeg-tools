function [fft_all, freq_range] = csc_average_reference_and_FFT(EEG, options)

% remove bad channels
% ~~~~~~~~~~~~~~~~~~~
if ~isempty(options.bad_channels)
    
    % set the bad channel values to NaN
    EEG.data(options.bad_channels, :) = NaN;
    
end


% calculate the average reference if desired
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if options.ave_ref == 1
    
    % use EEGLABs function
    EEG = pop_reref( EEG, [],...
        'refloc', EEG.chaninfo.nodatchans(:));

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
no_epoch_samples = EEG.srate * options.epoch_length;

% calculate the number of channels
no_channels = size(EEG.data, 1);

% calculate the number of epochs, rounded down
no_epochs = floor(size(EEG.data, 2) / no_epoch_samples);

% pre-allocate the size of the fft variable
    %TODO: change arbitrary 240 frequency bins to something useful
freq_limit = options.freq_limit;
fft_all=NaN(no_channels, freq_limit, no_epochs + 1);

% TODO: Use appropriate inputs to pwelch function for epoch split
% loop for each channel
fprintf(1, '\nInformation: Calculating FFT: Channel ');
for channel = 1:no_channels
    fprintf(1, '%s, ', num2str(channel));
    
    % start a count for the epochs
    epoch_count = 1;
    
    % loop for each epoch
    for epochNum = 1:no_epochs
        start   = ((epochNum - 1) * no_epoch_samples) + 1;
        ending  = start + no_epoch_samples;
        
        % run the fft using the pwelch method of overlapping windows
        [ffte, F] = pwelch(EEG.data(channel, start:ending) ,...
            [], []              ,...
            no_epoch_samples    ,...
            EEG.srate           );
        
        % only save ffts up to a particular frequency
        ffte = ffte(1:freq_limit);
        fft_all(channel, :, epoch_count) = ffte;
        
        % increase the count
        epoch_count = epoch_count+1;
    end
end

freq_range = F(1 : freq_limit);

% save to external file
if options.save_file
    
    % save the file in the current directory
    save(options.save_name, 'fft_all', 'freq_range', '-v7.3');
    
end

fprintf(1, '\nInformation: FFT calculation complete \n');
