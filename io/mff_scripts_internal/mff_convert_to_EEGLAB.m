% function to get EGI mff data and export to EEGLAB .set % .fdt

function EEG = mff_convert_to_EEGLAB(fileName, save_name)

FLAG_TO_STRUCT = true;

% if the filename is not specified open a user dialog
if nargin < 1
    fileName = uigetdir('*.mff');
end

if nargin < 2
    save_name = fileName(1:end-4);
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

EEG.nbchan          = mffData.signal_binaries(1).num_channels;
EEG.srate           = mffData.signal_binaries(1).channels.sampling_rate(1);
EEG.trials          = length(mffData.epochs);
EEG.pnts            = mffData.signal_binaries(1).channels.num_samples(1);
EEG.xmin            = 0; 

tmp                 = mff_convert_to_chanlocs(fileName);
EEG.chanlocs        = tmp.chanlocs;
EEG.chanlocs(258:end)=[];

% either write directly to file or to struct
if FLAG_TO_STRUCT
    
    % calculate total size and pre-allocate
    EEG.data = zeros(EEG.nbchan, mffData.signal_binaries(1).channels.num_samples(1), 'single');
    
    % open a progress bar
    waitHandle = waitbar(0,'Please wait...', 'Name', 'Importing Channels');
    
    % fill the EEG.data
    for current_channel = 1 : EEG.nbchan
        
        % update the waitbar
        waitbar(current_channel/EEG.nbchan, waitHandle, sprintf('Channel %d of %d', current_channel, EEG.nbchan))
               
        % get all the data
        temp_data = mff_import_signal_binary(mffData.signal_binaries(1), current_channel, 'all');
        EEG.data(current_channel, :) = temp_data.samples;
        
    end
    
    % delete the progress bar
    delete(waitHandle);
    
else
    
    % get data from bin to fdt
    % ````````````````````````
    
    dataName = [save_name, '.fdt'];
    % link the struct to the data file
    EEG.data = dataName;
    
    % open a file in append mode
    fid = fopen(dataName, 'a+');
    
    % open a progress bar
    waitHandle = waitbar(0,'Please wait...', 'Name', 'Importing Channels');
    
    % loop for each block individually and append to binary file
    nBlocks = mffData.signal_binaries(1).num_blocks;
    for current_channel = 1 : nBlocks
        
        % update the waitbar
        waitbar(current_channel/nBlocks, waitHandle,sprintf('Block %d of %d', current_channel, nBlocks))
        
        % loop each channel to avoid memory problems (ie. double tmpData)
        tmpData = zeros(EEG.nbchan, mffData.signal_binaries(1).blocks.num_samples(current_channel));
        for nCh = 1:EEG.nbchan
            chData = mff_import_signal_binary(mffData.signal_binaries(1), nCh, current_channel);
            tmpData(nCh,:) = chData.samples;
        end
        
        % write the block of data to the fdt file
        fwrite(fid, tmpData, 'single', 'l');
        
    end
    % delete the progress bar
    delete(waitHandle);
    
    % close the file
    fclose(fid);
end

% check the eeg for consistency
EEG = eeg_checkset(EEG);

% save the dataset
EEG = pop_saveset(EEG, [save_name ,'.set']);
