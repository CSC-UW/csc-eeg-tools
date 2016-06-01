% Preprocess the Data
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% load the specific dataset
% [fileName, filePath] = uigetfile('*.set');
EEG = pop_loadset();

% clean line noise if necessary
% consider high-pass filtering prior to this stage for optimal performance
EEG = pop_cleanline(EEG);

% filter the data
% consider filtering on double precision data then back to single
low_cutoff  = 0.3;
high_cutoff = 40;
EEG = pop_eegfiltnew(EEG, low_cutoff, high_cutoff, [], 0, [], 0);

% down-sample if necessary
EEG = pop_resample(EEG, 200);

% remove artefacts
% ````````````````
% use csc_eeg_plotter to visualise the time series
% [click on channel label to hide channels]
% [mark bad segments using event 1 and event 2 markers]
EEG = csc_eeg_plotter(EEG);

% remove bad channels and trials
EEG.bad_channels{1} = EEG.hidden_channels;
EEG = pop_select(EEG, 'nochannel', EEG.bad_channels{1});

% remove epochs
event_starts = cellfun(@(x) strcmp(x, 'event 1'), EEG.csc_event_data(:, 1));

% sanity check for artifact event markers
if sum(event_starts) ~= sum(~event_starts)
   fprintf('\nWarning: uneven number of events, check event_data\n'); 
end

% use EEGLAB to remove the points
EEG.bad_segments{1} = [cell2mat(EEG.csc_event_data(event_starts, 2)), ...
    cell2mat(EEG.csc_event_data(~event_starts, 2))];

% convert the timing from seconds to samples
EEG.bad_segments{1} = floor(EEG.bad_segments{1} * EEG.srate);

% use EEGLAB to remove the regions
EEG = pop_select(EEG, 'nopoint', EEG.bad_segments{1});


% semi-automatic bad segment detection
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    % use either eeglab [pop_rejchan] or wispic options
method = 'wispic';
EEG = csc_artifact_rejection(EEG, method, 'epoch_length', 6);

% plot the first bad region
    window = 2 * EEG.srate;
    plot(EEG.data(:, EEG.bad_regions(1,1) - window : EEG.bad_regions(1,2) + window)',...
        'color', [0.8, 0.8, 0.8]);
    
% remove the bad_regions
switch method
    % eeglab regions are given as samples
    case 'eeglab'
        EEG = pop_select(EEG, 'nopoint', EEG.bad_regions);
    % wispic regions are given as time in seconds    
    case 'wispic'
        EEG = pop_select(EEG, 'notime', EEG.bad_regions);
end


% independent components analysis 
% ```````````````````````````````
% run ICA (optional)
EEG = pop_runica(EEG,...
    'icatype', 'binica', ...
    'extended', 1,...
    'interupt', 'off');

% or use the csc_eeg_tools and use the ica option
% remove the components (best to do using plot component properties in the GUI)
csc_eeg_plotter(EEG);
EEG.good_components = csc_component_plot(EEG);

% save the data so componont removal can be quickly reproduced
EEG = pop_saveset(EEG);

% pop_prop changes the local EEG variable automatically when marked as reject
EEG = pop_subcomp( EEG , find(~EEG.good_components));
EEG = eeg_checkset(EEG);


% interpolate the removed channels
% ````````````````````````````````
[previousFile, previousPath] = uigetfile('*.set');
previousEEG = load(fullfile(previousPath, previousFile), '-mat');
EEG = eeg_interp(EEG, previousEEG.EEG.chanlocs);

% change reference
% ````````````````
% average reference
EEG = pop_reref( EEG, [],...
    'refloc', EEG.chaninfo.nodatchans(:));

% linked mastoid
% mastoids = [94, 190];
% EEG = pop_reref(EEG, mastoids);

% save the data
% `````````````
EEG = pop_saveset(EEG);