function EEG = csc_export_for_scoring(EEG, desired_channels)
% function to downsample and export only relevant channels to new smaller file

if nargin < 2
    % extended psg channels for EGI-256 with backup channels around mastoid electrodes
    desired_channels = ...
        [241, 10, 41, 15, 214, 59, 183, 86, 101, 162, 124, 149, 111, 190, 94, 102, 201, 178, 93, 95];
end

% select only relevant channels
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% get channels from data
EEG.data = EEG.data(desired_channels, :);
% from channel locations
EEG.chanlocs = EEG.chanlocs(desired_channels);
% from channel info
EEG.nbchan = length(desired_channels);
EEG = eeg_checkset(EEG);

% filter the data before downsampling
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% first-order highpass (mimics analog filter)
fprintf(1, 'applying high pass filter...\n');
EEG = csc_first_order_highpass(EEG, 0.1);

% use EEGLAB's resample which uses Nyquist low-pass filter
% N: perhaps not the best filter generally but sufficient for viewing and scoring
EEG = pop_resample(EEG, 100);

