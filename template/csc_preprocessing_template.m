% Preprocess the Data
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% * steps can be done within EEGLAB GUI

% clear the memory
clear all; clc;

% load the specific dataset
% [fileName, filePath] = uigetfile('*.set');
EEG = pop_loadset();

% filter the data
low_cutoff  = 0.3;
high_cutoff = 40;
EEG = pop_eegfiltnew(EEG, low_cutoff, high_cutoff, [], 0, [], 0);

% removing bad data
% `````````````````
% take a look at the data manually
    eegplot( EEG.data               ,...
        'srate',        EEG.srate   ,...
        'winlength',    30          ,...
        'dispchans',    15          );

% bad channels
    % find channels based on stds for spectral windows (better)
    [~, EEG.bad_channels, EEG.specdata] = pop_rejchanspec(EEG,...
        'freqlims', [20 40]     ,...
        'stdthresh',[-3.5 3.5]  ,...
        'plothist', 'off'       );

    % manually remove channels
    EEG.bad_channels = [EEG.bad_channels, ];
    
    % remove the bad channels found
    EEG = pop_select(EEG, 'nochannel', EEG.bad_channels);

% bad segments
    % use either eeglab or wispic options
    method = 'wispic';
EEG = csc_artifact_rejection(EEG, method);
EEG = csc_artifact_rejection(EEG, method, 'epoch_length', 6);

% plot the first bad region
    window = 2 * EEG.srate;
    plot(EEG.data(:, EEG.bad_regions(1,1)-window : EEG.bad_regions(1,2)+window)',...
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
EEG = pop_runica(EEG, 'extended', 1, 'interupt', 'off');

% remove the components (best to do using plot component properties in the GUI)
% plot the ica components as time series
eegplot( EEG.icaact             ,...
    'srate',        EEG.srate   ,...
    'winlength',    30          ,...
    'dispchans',    15          );

% plot the properties of the components manually (second input = 0)
pop_prop( EEG, 0, [1  : 16], NaN, {'freqrange' [2 40] });
pop_prop( EEG, 0, [17 : 32], NaN, {'freqrange' [2 40] });
pop_prop( EEG, 0, [33 : 48], NaN, {'freqrange' [2 40] });
pop_prop( EEG, 0, [49 : 64], NaN, {'freqrange' [2 40] });
pop_prop( EEG, 0, [65 : 80], NaN, {'freqrange' [2 40] });

% pop_prop changes the local EEG variable automatically when marked as reject
EEG.bad_components = find(EEG.reject.gcompreject);
    % include additional bad components manually
EEG.bad_components = [EEG.bad_components,];
EEG = pop_subcomp( EEG , EEG.bad_components);
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
