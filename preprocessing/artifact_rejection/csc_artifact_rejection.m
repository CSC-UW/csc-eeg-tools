function EEG = csc_artifact_rejection(EEG, method, varargin)

% make the method lowercase for compatibility
method = lower(method);

switch method
    case 'eeglab'
        
        [~, EEG.bad_regions] = pop_rejcont(EEG,...
            'freqlimit',        [20, 40],...    % lower and upper limits of frequencies
            'epochlength',      5,...           % window size to examine (in s)
            'overlap',          2,...           % amount of overlap in the windows
            'threshold',        10,...          % frequency upper threshold in dB
            'contiguous',       2,...           % number of contiguous epochs necessary to label a region as artifactual
            'addlength',        0.5,...         % seconds to add to each artifact side
            'onlyreturnselection', 'on',...     % do not actually remove it, just label it
            'taper',            'hamming',...   % taper to use before FFT
            'verbose',          'off');
        
    case 'wispic'
        
        % process the options
        options = csc_ar_options(EEG, varargin);
        
        % calculate the fft
        % ~~~~~~~~~~~~~~~~~
        [fft_all, freq_range] = csc_average_reference_and_FFT(EEG, options);
               
        % run the artifact detection
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~
        % calculate the bad epochs using thresholding of the band of
        % interest (2nd parameters)
        % TODO: bands of interest should be an option as well
        EEG.bad_epochs = csc_artifact_detection_fft(fft_all, freq_range, options);
        
%         % calculate the bad epochs in time
%         bad_epochs_time = (find(bad_epochs) * options.epoch_length) - options.epoch_length;
%         
%         % rearrange the time stamps into regions
%         EEG.bad_regions = [bad_epochs_time', bad_epochs_time' + options.epoch_length];
        
    otherwise
        fprintf(1, 'Error: unrecognised option call: %s', method);
end


function options = csc_ar_options(EEG, varargin)
% process additional arguments
% set default options
% ~~~~~~~~~~~~~~~~~~~

saveName = [EEG.filename(1:end-4), '_fftANok.mat'];

% get the first cell of varargin since its a passed variable
varargin = varargin{1};

options = struct(...
    'ave_ref', 0, ...
    'bad_channels', [], ...
    'bands_of_interest', [1, 5], ...
    'default_percentile', 99, ...
    'method', 'semi_automatic', ...
    'save_file',  0, ...
    'save_name', saveName, ...
    'epoch_length', 6, ...
    'freq_limit', 40 );

% read the acceptable names
optionNames = fieldnames(options);

% count arguments
nArgs = length(varargin);
if round(nArgs/2)~=nArgs/2
    error('optional arguments needs propertyName/propertyValue pairs')
end

% process any additional arguments
for pair = reshape(varargin,2,[]) % pair is {propName;propValue}
    inpName = lower(pair{1}); % make case insensitive
    
    if any(strmatch(inpName, optionNames))
        options.(inpName) = pair{2};
    else
        fprintf(1, '%s is not a recognized parameter name', inpName);
    end
end


