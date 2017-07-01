function [data_to_filter] = csc_filter(data_to_filter, sampling_rate, high_pass, low_pass)
% TODO: everything relevant to filtering!

% NOTE: SW defaults lp: 8-12 | hp: 0.3-0.8
if nargin < 3
    low_pass = [8, 12];
    high_pass = [0.3, 0.8];
end

% design lower band-pass filter
filter_design = designfilt('bandpassiir', 'DesignMethod', 'cheby2', ...
    'StopbandFrequency1', high_pass(1), 'PassbandFrequency1', high_pass(2), ...
    'StopbandFrequency2', low_pass(2), 'PassbandFrequency2', low_pass(1), ...   
    'SampleRate', sampling_rate);

% apply filter
fprintf('Applying band pass filter from %0.1f (%0.1f) to %0.1f (%0.1f) ...\n',...
    high_pass(2), high_pass(1), low_pass(1), low_pass(2));
data_to_filter = filtfilt(filter_design, data_to_filter')';


% channel by channel to reduce memory issues
% for ch = 1 : size(data_to_filter, 1)
%     data_to_filter(ch, :) = filtfilt(filter_design, data_to_filter(ch, :)')';
% end