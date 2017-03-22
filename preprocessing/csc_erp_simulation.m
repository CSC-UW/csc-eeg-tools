% simulate a typical EEG signal
total_length = 600;
s_rate = 250;

[alpha_eeg,ai,varargout] = get_sim_alpha(total_length, s_rate, [9, 11], 1, 0.4);

% generate sine wave
dt = 1/s_rate; % seconds per sample
StopTime = 0.20;             % seconds
t = (0:dt:StopTime-dt)';     % seconds

% Sine wave:
Fc = 5;                     % hertz
erp_signal = sin(2*pi*Fc*t);

% insert several waves
n_trials = 100;
signal_to_noise = 4;
random_latencies = randsample(length(alpha_eeg)-s_rate*2, n_trials) + s_rate;

for n = 1 : n_trials
    
    alpha_eeg(random_latencies(n) : random_latencies(n) + length(erp_signal) - 1) ...
        = alpha_eeg(random_latencies(n) : random_latencies(n) + length(erp_signal) - 1) ...
        + [erp_signal * signal_to_noise]';
    
end


% extract ERP
epoched_data = nan(n_trials, length(-s_rate/5 : s_rate));
for n = 1 : n_trials
    
   epoched_data(n, :) = alpha_eeg(random_latencies(n) - s_rate/5 : random_latencies(n) + s_rate);
    
end

mean_ERP = mean(epoched_data, 1);
figure; 
plot(mean_ERP, 'linewidth', 2);

% extract unsynced ERP

delete(handle_plot);

max_jitter = floor(0.1 * s_rate);

for n = 1 : n_trials
    
   jitterer_latencies = random_latencies(n) + randi([max_jitter*2], 1) - max_jitter; 
    
   jittered_data(n, :) = alpha_eeg(jitterer_latencies - s_rate/5 : jitterer_latencies + s_rate);
    
end

mean_jERP = mean(jittered_data, 1);

hold on
handle_plot = plot(mean_jERP, 'r', 'linewidth', 2);
