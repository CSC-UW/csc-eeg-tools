% run a 1000 random signals and test there power
for n = 1 : 1000
    
    N=1000; %length of the signal
    x=randn(1,N); %a random signal to test
    X=fft(x); %Frequency domain representation of the signal
    
    signal_power(n) = sqrt(mean(x.^2)); %RMS value from time domain samples
    RMS2(n) = sqrt(sum(abs(X/N).^2)); %RMS value from frequency domain representation
    
    SM(n) = sum(abs(X/N)); % just taking the mean of the spectrum
    
end

% show the correlation between signal and measured power
figure;
scatter(signal_power, RMS2);
title('signal power v RMS: perfect relationship from signal to psd')
figure;
scatter(signal_power, SM);
title('RMS v mean: random noise introduced')

% NOTE: while the SM correlates, its clearly noisier than taking the RMS!
% NOTE: with the RMS the power values are actually interpretable given the original signal strength
