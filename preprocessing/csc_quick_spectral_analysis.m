function [spectral_data, spectral_range] = csc_quick_spectral_analysis(EEG)

flag_mastoid = false;

% pre-allocate
% spectral_data = nan();
spectral_window = floor(EEG.srate * 1);         % 1 second windows
spectral_overlap = floor(spectral_window / 2);  % 50% overlap

% only run on certain stages
range_of_interest = EEG.swa_scoring.stages == 2 | EEG.swa_scoring.stages == 3;
   
% rereference for mastoid
if flag_mastoid
    EEG = pop_reref(EEG, [94, 190]);
end
    
% calculate the spectral power using pwelch
% [1Hz bin size = 1s windows])
[spectral_data, spectral_range] = pwelch(...
    EEG.data(:, range_of_interest)' ,... % data (transposed to channels are columns)
    spectral_window ,...    % window length
    spectral_overlap ,...   % overlap
    spectral_window ,...    % points in calculation (window length)
    EEG.srate );            % sampling rate

% define ranges of interest
delta_range = spectral_range >= 0.9 & spectral_range <= 4.1;
spindle_range = spectral_range >= 10.9 & spectral_range <= 16.1;

% topography
% ''''''''''
% calculate average power
delta_power = double(sqrt(sum(spectral_data(delta_range, :) .^ 2)));
spindle_power = double(sqrt(sum(spectral_data(spindle_range, :) .^ 2)));
delta_median = median(delta_power);
spindle_median = median(spindle_power);

% plot on topography
csc_Topoplot(delta_power, EEG.chanlocs);

csc_Topoplot(spindle_power, EEG.chanlocs);
