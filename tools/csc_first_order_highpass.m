function [EEG] = csc_first_order_highpass(EEG, cutoff)
% First-order (single pole), highpass IIR filter mimicking EGI Net Station

% check arguments
if nargin < 2
    cutoff = 0.1;
end

% check cutoff value 
if cutoff > 2
    fprintf(1, 'Warning: generally a first-order filter should have a cutoff below 1Hz\n');
end

% set parameters
d = pi * cutoff / EEG.srate;
c0 = 1 - d;
c1 = -(1 - d);
c3 = -(1 - 2 * d);

% filter the data (double transposed)
EEG.data = filter([c0 c1], [1 c3], EEG.data')';


% % Original CSC-Internal Function
% % This is a simple single pole highpass IIR filter meaning that it's the same in the lowpass sense as a single resistor capacitor.
% % be cautious because it will attenuate signal beyond its cutoff
% % it will also lose cutoff accuracy at progressively higher cutoff values.
% % realistically it should only be used 0 - 1 Hz (maybe 2 Hz)
% 
% % can only be done successfully with long segments - need to check what size makes it behave badly poorly BAR
% % 
% % 2/23/16 modified to be channels by time and do multiple channels
% function dataf = firstorderhpfilterNS(samples,samplingRate,cutoff)
% %samples should be channels x time;
% dataf = zeros(size(samples));
% for ch = 1:size(samples,1)
%     d = pi * cutoff / samplingRate;
%     
%     c0 = 1 - d;
%     c1 = -(1 - d);
%     c3 = -(1 - 2 * d);
%     dataf(ch,:) = single(filter([c0 c1], [1 c3], samples(ch,:)));
% end

