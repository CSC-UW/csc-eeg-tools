function [data_to_filter] = csc_filter(data_to_filter, sampling_rate)
% TODO: everything relevant to filtering!

% NOTE: found that low pass filter applied first is better than the other way

% design lower low-pass filter
filter_design = designfilt('lowpassiir', 'DesignMethod', 'cheby2', ...
    'StopbandFrequency', 20, 'PassbandFrequency', 18, ...
    'SampleRate', sampling_rate);

% apply filter
data_to_filter = filtfilt(filter_design, data_to_filter')';

% design high-pass
filter_design = designfilt('highpassiir', 'DesignMethod', 'cheby2', ...
    'StopbandFrequency', 4, 'PassbandFrequency', 6, ...
    'SampleRate', sampling_rate);

% apply filter
data_to_filter = filtfilt(filter_design, data_to_filter')';


% channel by channel to reduce memory issues
% for ch = 1 : size(data_to_filter, 1)
%     data_to_filter(ch, :) = filtfilt(filter_design, data_to_filter(ch, :)')';
% end