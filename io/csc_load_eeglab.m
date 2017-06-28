function EEG = csc_load_eeglab(filename)
% easier loading of .set files without all the checking and bloat of EEGLAB

% load the set file
load('-mat', filename);

if flag_load
    % load the data
    % ^^^^^^^^^^^^^
    % open the file
    fid = fopen( EEG.datfile , 'r', 'ieee-le'); % little endian (see also pop_saveset)
    
    % read from the file (attempt to read as "single" directly)
    EEG.data = fread(fid, [EEG.nbchan EEG.pnts], '*single');
    
    % close the file
    fclose(fid);
    
else
    % memory map the data
    tmp = memmapfile(EEG.data,...
                'Format', {'single', [EEG.nbchan EEG.pnts * EEG.trials], 'eegData'});
    EEG.data = tmp.Data.eegData;
    
end


% eeglab saves the data using:
% fid = fopen(fname,'wb',fform);
% fwrite(fid,A,'float');