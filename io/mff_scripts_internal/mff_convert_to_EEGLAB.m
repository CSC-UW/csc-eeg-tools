% function to get EGI mff data and export to EEGLAB .set % .fdt

function EEG = mff_convert_to_EEGLAB(fileName, save_name, recording_system)

FLAG_TO_STRUCT = true;
FLAG_DOWNSAMPLE = false;

% if the filename is not specified open a user dialog
if nargin < 1
    fileName = uigetdir('*.mff');
end
if isempty(fileName)
    fileName = uigetdir('*.mff');
end

if nargin < 2
    save_name = fileName(1:end-4);
end
if isempty(save_name)
    save_name = fileName(1:end-4);
end

if nargin < 3
   recording_system = 1; 
end

% check if file name already exists
while exist([save_name ,'.set'], 'file')
    save_name = [save_name, '_1'];
end

% get the mff meta data for all the data information
mffData = mff_import_meta_data(fileName);

% EEG structure
% `````````````
% initialise EEG structure
EEG = eeg_emptyset;

% get meta info
EEG.comments        = [ 'Original file: ' fileName ];
EEG.setname 		= 'mff file';

EEG.nbchan          = mffData.signal_binaries(recording_system).num_channels - 1;
EEG.srate           = mffData.signal_binaries(recording_system).channels.sampling_rate(1);
EEG.trials          = length(mffData.epochs);
EEG.pnts            = mffData.signal_binaries(recording_system).channels.num_samples(1);
EEG.xmin            = 0; 

tmp                 = mff_convert_to_chanlocs(fileName);
EEG.chanlocs        = tmp.chanlocs;
EEG.chanlocs(257:end)=[];

% either write directly to file or to struct
if FLAG_TO_STRUCT
    
    % open a progress bar
    waitHandle = waitbar(0,'Please wait...', 'Name', 'Importing Channels');
    
    if ~FLAG_DOWNSAMPLE
        % calculate total size and pre-allocate
        EEG.data = zeros(EEG.nbchan, mffData.signal_binaries(recording_system).channels.num_samples(1), 'single');
        
        % fill the EEG.data
        for current_channel = 1 : EEG.nbchan
            
            % update the waitbar
            waitbar(current_channel/EEG.nbchan, waitHandle, sprintf('Channel %d of %d', current_channel, EEG.nbchan))
            
            % get all the data
            temp_data = mff_import_signal_binary(mffData.signal_binaries(recording_system), current_channel, 'all');
            EEG.data(current_channel, :) = temp_data.samples;
            
        end
        
    else
               
        % get the first channel
        temp_data = mff_import_signal_binary(mffData.signal_binaries(recording_system), 1, 'all');
        
        % NOTE: decimate function takes care of filtering
%         % design filter (cheby 1 _ 10th order _ nyquist)
%         filter_design = designfilt('lowpassiir', 'FilterOrder', 10, ...
%             'PassbandFrequency', temp_data.sampling_rate / 4, 'PassbandRipple', 1, 'SampleRate', temp_data.sampling_rate);
%         
%         % filter the channel
%         temp_data.samples = filtfilt(filter_design, double(temp_data.samples));
        
        % downsample the channel
        temp_data.samples = single(decimate(double(temp_data.samples), 2));
        
        % pre-allocate EEG to remaining size
        EEG.data = zeros(EEG.nbchan, length(temp_data.samples), 'single');
        EEG.data(1, :) = temp_data.samples;
        
        % loop for rest of channels
        for current_channel = 2 : EEG.nbchan
            
            % update the waitbar
            waitbar(current_channel/EEG.nbchan, waitHandle, sprintf('Channel %d of %d', current_channel, EEG.nbchan))
            
            % get all the data
            temp_data = mff_import_signal_binary(mffData.signal_binaries(recording_system), current_channel, 'all');
            temp_data.samples = single(decimate(double(temp_data.samples), 2));
            EEG.data(current_channel, :) = temp_data.samples;
            
        end
    end
    
    % delete the progress bar
    delete(waitHandle);
    
    % check the eeg for consistency
    EEG = eeg_checkset(EEG);
    
    % save the dataset
    EEG = pop_saveset(EEG, [save_name ,'.set']);
    
else
    
    % get data from bin to fdt
    % ````````````````````````
    dataName = [save_name, '.fdt'];
    % link the struct to the data file
    EEG.data = dataName;
    
    % open a file in append mode
    fid = fopen(dataName, 'a+');
    
    % open a progress bar
    waitHandle = waitbar(0,'Please wait...', 'Name', 'Importing Blocks');
    
    % loop for each block individually and append to binary file
    nBlocks = mffData.signal_binaries(recording_system).num_blocks;
    for current_channel = 1 : nBlocks
        
        % update the waitbar
        waitbar(current_channel/nBlocks, waitHandle,sprintf('Block %d of %d', current_channel, nBlocks))
        
        % loop each channel to avoid memory problems (ie. double tmpData)
        tmpData = zeros(EEG.nbchan, mffData.signal_binaries(recording_system).blocks.num_samples(current_channel));
        for nCh = 1:EEG.nbchan
            chData = mff_import_signal_binary(mffData.signal_binaries(recording_system), nCh, current_channel);
            tmpData(nCh,:) = chData.samples;
        end
        
        % write the block of data to the fdt file
        fwrite(fid, tmpData, 'single', 'l');
        
    end
    % delete the progress bar
    delete(waitHandle);
    
    % close the file
    fclose(fid);
    
    save([save_name, '.set'], 'EEG', '-mat');
end
