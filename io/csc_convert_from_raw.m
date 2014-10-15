function EEG = csc_convert_from_raw(files)
% function to import and concatenate raw files into a single eeglab file 
% input should be a list of file names in a cell array or left empty

% check number of input arguments and have user select files if empty
if nargin < 1
    [files, file_path] = uigetfile('*.raw', 'multiselect', 'on');
    % change the current directory to the files
    cd(file_path);
end

% initialise the EEG structure
EEG = [];
Eventdata = [];
EEG = eeg_emptyset;

% loop through each file and downsample
for n = 1:length(files)
    % check for existence
    if exist(files{n}, 'file')
        disp(['Importing ' files{n}]);
        [Head, tmpdata, tmpevent] = readegi( files{n} );

        % concatenate the events
        Eventdata = [ Eventdata tmpevent ];  
        
        % concatenate the data
        EEG.data  = [ EEG.data  tmpdata ];
        
    else
        % if the file isn't found break the loop
        fprintf(1, '%s not found, continuing \n', files{n} );
        break;
    end  
end;

if ~exist('Head', 'var')
    fprintf(1, 'Warning: No files found, returning empty EEG \n');
    return;
end

% add EEG information
EEG.comments        = [ 'Original files: ' files{1} ' to ' files{n}];
EEG.filepath        = '';
EEG.setname 		= 'EGI file';
EEG.nbchan          = size(EEG.data,1);
EEG.srate           = Head.samp_rate;
EEG.trials          = Head.segments;
EEG.pnts            = Head.segsamps;
EEG.xmin            = 0; 
EEG.times           = [1:EEG.pnts]/EEG.srate;

% add one channel with the event data
% -----------------------------------
if ~isempty(Eventdata) && size(Eventdata,2) == size(EEG.data,2)
    EEG.data(end+1:end+size(Eventdata,1),:) = Eventdata;
end;

% importing the events
% --------------------
if ~isempty(Eventdata)
    orinbchans = EEG.nbchan;
    for index = size(Eventdata,1):-1:1
        EEG = pop_chanevent( EEG, orinbchans-size(Eventdata,1)+index, 'edge', 'leading', ...
                             'delevent', 'off', 'typename', Head.eventcode(index,:), ...
                             'nbtype', 1, 'delchan', 'on');
    end;
end;

EEG = eeg_checkset(EEG);

