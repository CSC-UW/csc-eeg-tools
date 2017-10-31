function [PLF, threshold] = csc_phase_locking_factor(time_series, srate, flag_filter)

% filter data if necessary
if flag_filter
    fprintf(1, 'Filtering data at > 8Hz... \n');
    fc = 8; % cut off frequency
    fn = floor(srate / 2); % nyquivst frequency = sample frequency/2;
    order = 3; % 3rd order filter, high pass
    [b a] = butter(order, (fc/fn), 'high');
    
    % reshape time series to long
    num_trials = size(time_series, 2);
    time_series = time_series(:);
    time_series = filtfilt(b, a, double(time_series));
    
    % reshape back to trials
    time_series = reshape(time_series, [], num_trials);
end

for k= 1 : size(time_series,2)
    hilberT(:,k) = hilbert((time_series(:,k))); %for every trial calculate hilbert transform
    hilberT(:,k) = hilberT(:,k)./abs(hilberT(:,k)); %divide for the absolute value to obtain the instantaneous phase
end
PLF=(abs(mean(hilberT,2))); 

% statistical significance
tendbaseline=726; % end of baseline, in sample
alpha=0.01; %alpha value
xaxe=0:0.001:1;
meanbase=mean(PLF(1:tendbaseline));
xrayle=raylpdf(xaxe,meanbase./sqrt(pi/2)); %build the rayle dirtribution
acch=0;
is=1;
while acch==0
    if sum(xrayle(1:is))/sum(xrayle)>(1-alpha)
        acch=1;
    else
        is=is+1;
    end
end
threshold = xaxe(1, is);