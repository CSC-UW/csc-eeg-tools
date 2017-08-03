function [spectral_data, spectral_range] = csc_quick_spectral_analysis(EEG, flag_plot)
% performs 1 second window spectral analysis using pwelch on EEG structure

% check inputs
if nargin < 2
    flag_plot = true;
end

% flag parameters
% TODO: put as input arguments
flag_mastoid = false;
flag_remove_channels = true; 

% pre-allocate
% spectral_data = nan();
spectral_window = floor(EEG.srate * 1);         % 1 second windows
spectral_overlap = floor(spectral_window / 2);  % 50% overlap

% only run on certain stages
if isfield(EEG, 'swa_scoring') && length(EEG.swa_scoring) == EEG.pnts
    range_of_interest = EEG.swa_scoring.stages == 2 | EEG.swa_scoring.stages == 3;
else
    range_of_interest = true(EEG.pnts, 1);
end

% do not use bad data
if isfield (EEG, 'bad_data')
    fprintf(1, 'Not using segments indicated in EEG.bad_data...\n');
    range_of_interest(EEG.bad_data) = false;
end

% remove bad channels
if flag_remove_channels
    if isfield (EEG, 'bad_channels')
        % bad channels should be a cell array of lists
        fprintf(1, 'Removing bad channels...\n');
        EEG.data(EEG.bad_channels{1}, :) = [];
        EEG.chanlocs(EEG.bad_channels{1}) = [];
        EEG.nbchan = size(EEG.data, 1);
    elseif isfield (EEG, 'good_channels')
        % good channels should be a logical vector
        fprintf(1, 'Removing bad channels...\n');
        EEG.data(~EEG.good_channels, :) = [];
        EEG.chanlocs(~EEG.good_channels) = [];
        EEG.nbchan = size(EEG.data, 1);
    end
end

% rereference for mastoid
if flag_mastoid
    EEG = pop_reref(EEG, [94, 190]);
else
    fprintf(1, 'Performing temporary average reference...\n');
    EEG.data = EEG.data - repmat(mean(EEG.data, 1), EEG.nbchan, 1);
end
    
% calculate the spectral power using pwelch
% [1Hz bin size = 1s windows])
fprintf(1, 'Running spectral analysis using pwelch...\n');
if ~verLessThan('matlab', '8.4')
    [spectral_data, spectral_range] = pwelch(...
        EEG.data(:, range_of_interest)' ,... % data (transposed to channels are columns)
        hanning(spectral_window) ,...    % window length
        spectral_overlap ,...   % overlap
        spectral_window ,...    % points in calculation (window length)
        EEG.srate );            % sampling rate
else
    % pre-allocate
    spectral_data = nan(EEG.nbchan, EEG.srate/2 + 1);
    swa_progress_indicator('initialise', 'channels complete');
    for n = 1 : EEG.nbchan
        swa_progress_indicator('update', n, EEG.nbchan);
        [spectral_data(n, :), spectral_range] = pwelch(...
            EEG.data(n, range_of_interest)' ,... % data (transposed to channels are columns)
            hanning(spectral_window) ,...    % window length
            spectral_overlap ,...   % overlap
            spectral_window ,...    % points in calculation (window length)
            EEG.srate );            % sampling rate
    end
end

% topography
% ''''''''''
if flag_plot
    % define ranges of interest
    delta_range = spectral_range >= 0.9 & spectral_range <= 4.1;
    spindle_range = spectral_range >= 10.9 & spectral_range <= 16.1;
    
    % calculate average power
    delta_power = double(sqrt(mean(spectral_data(delta_range, :) .^ 2)));
    spindle_power = double(sqrt(mean(spectral_data(spindle_range, :) .^ 2)));
    delta_median = median(delta_power);
    spindle_median = median(spindle_power);
    
    % plot topographies
    csc_Topoplot(log(delta_power), EEG.chanlocs);
    csc_Topoplot(log(spindle_power), EEG.chanlocs);
end