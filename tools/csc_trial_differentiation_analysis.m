function differentiation = csc_trial_differentiation_analysis(EEG, measure, selected_samples)
% calculate differentiation of EEG trials

% measure: 'base' | 'temporal' | 'spatial' | 'all'

if nargin < 2
    measure = 'base';
end

if nargin < 3
    selected_samples = EEG.times > 0;
end

switch measure
    case 'base'
        % base differentiation (channel, samples combined)

        % reshape data
        long_data = permute(EEG.data(:, selected_samples, EEG.good_trials), [3, 1, 2]);
        long_data = reshape(long_data, sum(EEG.good_trials), []);
        
        % calculate distance matrix
        rdm = pdist(long_data, 'euclidean');
        
        % extract parameters
        differentiation.base_median = median(rdm);
        differentiation.base_mean = mean(rdm);
        differentiation.base_std = std(rdm);
        
    case 'temporal'
        % temporal differentiation
        
        long_data = permute(EEG.data(:, :, EEG.good_trials), [3, 1, 2]);
        
        % pre-allocate
        differentiation.temporal_median = nan(EEG.pnts, 1);
        differentiation.temporal_mean = nan(EEG.pnts, 1);
        differentiation.temporal_std = nan(EEG.pnts, 1);
        
        for n = 1 : EEG.pnts
           
            % calculate distance matrix
            rdm = pdist(long_data(:, :, n), 'euclidean');
            
            % extract parameters
            differentiation.temporal_median(n) = median(rdm);
            differentiation.temporal_mean(n) = mean(rdm);
            differentiation.temporal_std(n) = std(rdm);
        end
        
    case 'spatial'
        % spatial differentiation
        
        % reshape data
        long_data = permute(EEG.data(:, :, EEG.good_trials), [3, 2, 1]);

        % pre-allocate
        differentiation.spatial_median = nan(EEG.nbchan, 1);
        differentiation.spatial_mean = nan(EEG.nbchan, 1);
        differentiation.spatial_std = nan(EEG.nbchan, 1);
        
        for n = 1 : EEG.nbchan
           
            % calculate distance matrix
            rdm = pdist(long_data(:, :, n), 'euclidean');
            
            % extract parameters
            differentiation.spatial_median(n) = median(rdm);
            differentiation.spatial_mean(n) = mean(rdm);
            differentiation.spatial_std(n) = std(rdm);
        end
end