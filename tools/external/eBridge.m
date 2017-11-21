function varargout = eBridge(varargin)
%eBridge.m
%Identify channels within an EEG montage forming a low-impedance
%electrical bridge.
%
%Please cite as: Alschuler et al (2014). Clin Neurophysiol, 125(3), 484-490.
%
%Usage: [EB, ED] = eBridge(EEG, {'e#1'...'e#n'}, '<flag#1>',<arg#1>...'<flag#n>',<arg#n>);
%
%Input arguments:  EEG - EEGLAB epoched or continuous data structure
%                        (required).
%      {'e#1'...'e#n'} - Optional cell array containing labels of any EEG
%                        channels to be excluded.
%     '<flag#>',<arg#> - Optional argument pairs (see detailed info).
%
%Output arguments:  EB - Summary of identified electrical bridges and EEG
%                        data information (Matlab structure).
%                   ED - Electrical distance (ED) matrix for unique
%                        pairwise differences.
%
%For more detailed information, use "eBridge /?" or "eBridge /h".
%
%The latest version of this function, along with additional information and
%help, are available at http://psychophysiology.cpmc.columbia.edu/eBridge.
%
%Copyright © 2013 by Daniel Alschuler
%Email: dmaadm@outlook.com
%GNU General Public License (http://www.gnu.org/licenses/gpl.txt)
%
%Valuable advice, testing, and feedback were provided by Jürgen Kayser and
%Craig Tenke.
%
%History:
%  v0.1.01 10/04/2013 by DA
%    -First open beta version.
%    -Only count epochs with EDs < EDcutoff.
%    -Bugfixes.

%%%%%%%%%%%%%%%%%%%%%%%
%Set initial variables.
%%%%%%%%%%%%%%%%%%%%%%%
%Version number.
EB.Info.Version = '0.1.01';
%Beginning of messages.
mBeg = 'eBridge: ';
%Series of spaces that can be used to replace mBeg.
begSpace = repmat(sprintf(' '), 1, length(mBeg));

%%%%%%%%%%%%%%%%%%%%%%%%%
%Additional help section.
%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmpi('/?',varargin)) || any(strcmpi('/h',varargin)) || any(strcmpi('help',varargin))
  %Page the output.
  moreSetting = get(0,'more');
  if strcmpi(moreSetting,'off'), more on; end
  %Display the help.
  help eBridge
  %Display the additional help.
  fprintf(['This function uses EEG data to compute an electrical distance (ED) matrix.\n',...
          '  The ED values are then plotted in a frequency distribution, which is\n',...
          '  scaled, spline interpolated, and used to determine which channels, if\n',...
          '  any, are electrically bridged.\n',...
          '\n',...
          'This function will provide more accurate results if the EEG data are\n',...
          '  filtered. The ''FiltMode'' input parameter can be used to automatically\n',...
          '  filter the data within the function; otherwise, a 0.5-30 Hz bandpass, 24\n',...
          '  dB/octave, FIR filter is recommended.\n',...
          '\n',...
          'Downsampling the data before using this function will speed up creation of\n',...
          '  the ED matrix creation, but can decrease the number of extracted epochs\n',...
          '  and thus decrease the accuracy of the function. \n',...
          '\n',...
          'Input EEG data can be continuous or epoched. If continuous, the function\n',...
          '  will extract epochs with a length that is automatically determined by\n',...
          '  the function. For this function to work, input data must consist of 30 \n',...
          '  epochs (or continuous data from which 30 epochs can be extracted.).\n',...
          '  30 s of data is recommended as the bare minimum at which reliable\n',...
          '  results may be obtained, although more data will further improve\n',...
          '  reliability. 1500 s of data is recommended as a good upper limit beyond\n',...
          '  which reliability and accuracy will probably not significantly improve.\n',...
          '\n',...
          'Any changes to the EEG data within this function will not be applied to\n',...
          '  the data in the main MATLAB workspace (i.e., even if this function\n',...
          '  epochs and filters the data, the original EEG data structure will remain\n',...
          '  unaffected).\n',...
          '\n',...
          'Usage: [EB, ED] = eBridge(EEG, {''e#1''...''e#n''}, ''<flag#1>'',<arg#1>...''<flag#n>'',<arg#n>);\n',...
          '\n',...
          'Only EEG (EEGLAB epoched or continuous data structure) is required for input.\n',...
          '\n',...
          'INPUT:\n',...
          '  EEG: A continuous or epoched EEGLAB epoched data structure, containing\n',...
          '       at least the following two fields:\n',...
          '         - .data:     Matrix of channels x samples, or channels x samples\n',...
          '                      x epochs.\n',...
          '         - .chanlocs: Structure containing channel labels under the\n',...
          '                      subfields .chanlocs.labels.\n',...
          '\n',...
          'Optional input arguments:\n',...
          'Enter with flag in single quotes (''<flag#>'' above), followed by\n',...
          'the corresponding argument (<arg#> above).\n',...
          ' {ExChans}     Cell array containing labels of any channels to be\n',...
          '               excluded. Does not require a flag.\n',...
          ' ''BinSize''     Size of bins in ED frequency distribution, before spline\n',...
          '               interpolation. Only a number whose multiplicative inverse\n',...
          '               (i.e., 1/BinSize) is an integer can be used.\n',...
          ' ''BCT''         Bridge classification threshold. Number between 0 and 1.\n',...
          '               Fraction of epochs that must be less than or equal to the\n',...
          '               automatically-calculated electrical distance cutoff for a\n',...
          '               channel to be flagged as bridged. Default is 0.5.\n',...
          ' ''PlotMode''    0  Do not plot spline-interpolated ED distribution and ED\n',...
          '                  cutoff.\n',...
          '               1  Plot only if bridged channels are found (default).\n',...
          '               2  Plot.\n',...
          ' ''Verbose''     0  Very little screen output.\n',...
          '               1  Medium amount of screen output (default).\n',...
          '               2  High screen output.\n',...
          '\n',...
          'The following input arguments are only relevant for continuous input data.\n',...
          ' ''EpLength''  Epoch length, in sample points. If set to 0 (default),\n',...
          '               epoch length will be determined automatically.\n',...
          'In addition to requiring continuous input data, the following input\n',...
          'argument also requires EEGLAB to be initialized and the MATLAB Signal\n',...
          'Processing Toolbox to be installed.\n',...
          ' ''FiltMode''    0  Do not filter continuous data (default).\n',...
          '               1  Bandpass filter continuous data using the EEGLAB\n',...
          '                  pop_eegfilt function.\n',...
          '\n',...
          'OUTPUT:\n',...
          'EB: Structure containing the following fields:\n',...
          '  .Bridged: Structure containing the following fields:\n',...
          '    .Count:   Number of bridged channels.\n',...
          '    .Indices: Row vector containing the indices of bridged channels.\n',...
          '    .Labels:  Cell vector containing the labels of bridged channels.\n',...
          '    .Pairs:   2-row cell array containing the pairs of channels that were\n',...
          '              bridged together (each column contains a bridged pair).\n',...
          '  .Info: Structure containing the following fields:\n',...
          '    .ExChans:     Cell array containing the labels of excluded channels.\n',...
          '    .Binsize:     BinSize (see input section).\n',...
          '    .BCT:         BCT (see input section).\n',...
          '    .EDcutoff:    Automatically-calculated electrical distance cutoff. If not\n',...
          '                  applicable, set to -1.\n',...
          '    .FigHandle:   Handle of figure containing plot of ED distribution.\n',...
          '    .FiltLower:   Lower cutoff for bandpass filter. If filter was not\n',...
          '                  applied, set to -1.\n',...
          '    .FiltUpper:   Upper cutoff for bandpass filter. If filter was not\n',...
          '                  applied, set to -1.\n',...
          '    .EEGtype:    Type of EEG data submitted as input. Either ''Continuous''\n',...
          '                  or ''Epoched''.\n',... 
          '    .NumChansOrg: Original number of channels (before excluded channels\n',...
          '                  subtracted).\n',...
          '    .NumChans:    New number of channels (with excluded channels\n',...
          '                  subtracted).\n',...
          '    .NumEpochs:   Number of epochs.\n',...
          '    .NumPts:      Number of sample points per epoch.\n',...
          '    .EDscale:     Factor by which all ED values are scaled \n',...
          '                  (EDscale = 100 / [median ED]) \n',...
          '    .Version:     Version number of this function.\n',...
          '\n',...'
          'ED: Triangular matrix of size channels x channels. It contains all of the\n',...
          '    unscaled pairwise electrical distance values for non-excluded channels.\n',...
          '    It will not be returned if only one output variable is assigned for\n',...
          '    the function.\n',...
          '\n',...
          'EXAMPLES:\n',...
          '[a, b] = eBridge(EEG,{''Cz'' ''Fz''},''BCT'',.5,''PlotMode'',2,''Verbosity'',0,''EpLength'',128,''FiltMode'',1);\n',...
          'This will create an output structure named "a" containing the bridging\n',...
          '  information and an output ED matrix named "b". The input structure "EEG"\n',...
          '  will be used, with Cz and Fz excluded. BCT will be set to ".5". The ED\n',...
          '  ED frequency will be plotted distribution even if no channels are\n',...
          '  bridged. Screen output will be sparse. If data are continuous, they will\n',...
          '  be filtered, and epochs with a length of 128 sample points will be\n',...
          '  extracted.\n',...
          '\n',...
          'a = eBridge(EEG);\n',...
          'This will create an output structure named "a" containing the bridging\n',...
          '  information; an output ED matrix will not be returned. The input\n',...
          '  structure "EEG" will be used with no excluded channels and all options\n',...
          '  set to their default values.\n']);
  %Return to original "more" setting.
  if strcmpi(moreSetting,'off'), more off; end
  clear moreSetting
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Configure and check all arguments.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf([mBeg 'Configuring inputs.\n']);
%Check EEG structure.
AllEEGStructs = cellfun(@isstruct,varargin);
assert(sum(AllEEGStructs) <= 1,'Only one EEG structure can be entered as an input.','')
assert(sum(AllEEGStructs) >= 1,'An EEG structure must be entered as an input.','')
EEGStructInd = find(AllEEGStructs == 1);
EEG = varargin{EEGStructInd};
assert(~isempty(fieldnames(EEG)),'Input EEG data structure "%s" is empty.', inputname(EEGStructInd))
assert(all(isfield(EEG,{'data','chanlocs','srate'})) && isfield(EEG.chanlocs,'labels'),['Problem with fields in input structure "%s". Must contain fields .data,\n',...
                                                                                        '.chanlocs, and .srate.'],inputname(EEGStructInd))
assert((ndims(EEG.data) == 3) || (ndims(EEG.data) == 2),['Input EEG data matrix "%s.data" must be an epoched 3-dimensional channels\n',...
                                                         'x samples x epochs matrix or a continuous 2-dimensional channels x samples\n',...
                                                         'matrix.'], inputname(EEGStructInd))
if ndims(EEG.data) == 2
  EBinput.EEGtype = 'Continuous';
else
  EBinput.EEGtype = 'Epoched';
end
%Check ExChan.
AllExChanCells = cellfun(@iscell,varargin);
assert(sum(AllExChanCells) <= 1,'Only one cell array can be entered as an input for excluded channels.','')
if ~any(AllExChanCells)
  EBinput.ExChans = {};
else
  EBinput.ExChans = varargin{AllExChanCells == 1};
end
clear AllEEGStructs EEGStructInd AllExChanCells
%Check flag inputs.
%flagCell contains flag names on first row and the corresponding defaults
%on the second row.
flagCell = {'BinSize','BCT','PlotMode','Verbose','EpLength','FiltMode';0.25,0.5,1,1,0,0};
for a = 1:length(flagCell)
  flagName = flagCell{1,a};
  AllFlagSize = strcmpi(flagName,varargin);
  assert(sum(AllFlagSize) <= 1,'Only one %s value can be entered as an input.',flagName)
  if ~any(AllFlagSize)
    EBinput.(flagName) = flagCell{2,a};
  else
    EBinput.(flagName) = varargin{find(AllFlagSize == 1) + 1};
    assert(isnumeric(EBinput.(flagName)) && sum(length(EBinput.(flagName))) <= 2,'%s input must be a 1x1 numeric variable.\n',flagName)
  end
end
clear flagCell flagFields flagName AllFlagSize
%Additional flag variable checks.
assert((0 < EBinput.BinSize) && (EBinput.BinSize < 100),'BinSize input must be a number greater than 0 and less than 100.\n','')
assert((0 < EBinput.BinSize) && (EBinput.BinSize < 100),'BinSize input must be a number greater than 0 and less than 100.\n','')
assert(~logical(mod((1/EBinput.BinSize),1)),'Multiplicative inverse of BinSize must be an integer.\n','')
assert((0 < EBinput.BCT) && (EBinput.BCT < 1), 'BCT input must be a number greater than 0 and less than 1.','')
assert((EBinput.PlotMode == 0) || (EBinput.PlotMode == 1) || (EBinput.PlotMode == 2),'PlotMode input must be "0", "1", or "2".','')
assert((EBinput.Verbose == 0) || (EBinput.Verbose == 1) || (EBinput.Verbose == 2),'Verbose input must be "0", "1", or "2".','')
if strcmpi(EBinput.EEGtype,'Continuous')
  assert((0 <= EBinput.EpLength) && ~logical(mod(EBinput.EpLength,1)),'EpLength input must be an integer greater than or equal to 0.','')
  assert((EBinput.FiltMode == 0) || (EBinput.FiltMode == 1),'FiltMode input must be "0" or "1".','')
  %Check that EEGLAB is initialized and Signal Processing Toolbox is installed.
  if EBinput.FiltMode == 1
    assert(logical(exist('fir1','file')),['Cannot process continuous data. The fir1 function or Signal Processing\n',...
                                          'Toolbox is missing.'],'')
    try
      evalin('base','ALLEEG; CURRENTSET;');
    catch ceException
      error(['EEGLAB is not active. EEGLAB must be initialized for filterng of\n',...
             'continuous data. Run "eeglab" function on command line, then try again.\n'],'')
    end
  end
end
%Check outputs.
assert(nargout <= 2,'A maximum of two output variables can be assigned to this function.','')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Display citation information.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if EBinput.Verbose == 2, fprintf('Please cite: Alschuler et al. (2013). Clin Neurophysiol, 2014, 125(3):484-490.\n'); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Process continuous EEG data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%If EEG.data is continuous, optionally use EEGLAB pop_eegfilt to filter the
%data then create new epoched data matrix.
if strcmpi(EBinput.EEGtype,'Continuous')
  %Bandpass filter data using pop_eegfilt.m function twice, once for lower
  %bound and once for upper bound (as recommended by the function
  %documentation).
  if EBinput.FiltMode == 1
    EB.Info.FiltUpper = 30;
    EB.Info.FiltLower = 0.5;
    %Check that there is enough data for bandpass filtering.
    hpordersec = 3  / EB.Info.FiltLower;
    hporder = ceil(hpordersec * EEG.srate);
    assert(hporder <= size(EEG.data,2),['Not enough continuous data. At least %i seconds needed for bandpass\n',...
                                        'filtering. Try again with more data or with ''FiltMode'' option set to 0.'],hpordersec)
    %Actually filter the data.
    try
      EEG = pop_eegfilt(EEG,0,EB.Info.FiltUpper,[],0,0,0,'fir1',0);
      EEG = pop_eegfilt(EEG,EB.Info.FiltLower,0,[],0,0,0,'fir1',0);
    catch filtException
      error('Filtering failed. Exception: %s\n',filtException.message)
    end
  else
    EB.Info.FiltUpper = -1;
    EB.Info.FiltLower = -1;
  end
  %Epoch data.
  %Set variables for epoching data.
  [tmpChans,tmpPts] = size(EEG.data);
  if EBinput.EpLength == 0
    %Cutoffs to follow when epoching automatically.
    maxEpochs = 1500;
    minPts = 64;
    minSecs = 0.5;
    maxSecs = 1.0;
    %Conversion of cutoffs to epoch length.
    epsEL = floor(tmpPts / maxEpochs);
    ptsEL = minPts;
    minSecsEL = floor(minSecs * EEG.srate);
    maxSecsEL = floor(maxSecs * EEG.srate);
   %Find epoch length.
    if ptsEL > maxSecsEL
      newEpLen = ptsEL;
    elseif epsEL > maxSecsEL
      newEpLen = maxSecsEL;
    else
      newEpLen = max([epsEL,ptsEL,minSecsEL]);
    end
  else
    newEpLen = EBinput.EpLength;
  end
  delPts = mod(tmpPts,newEpLen);
  newEpochs = floor(tmpPts / newEpLen);
  %Remove the last few points from the data if necessary.
  if delPts >= 1, EEG.data(:,end-delPts+1:end) = []; end
  %Epoch the data.
  EEG.data = reshape(EEG.data,tmpChans,newEpLen,newEpochs);
  if EBinput.Verbose > 0, fprintf([mBeg 'Epoch length set to %i sample points. %i epochs extracted.\n'],newEpLen,newEpochs); end
  clear tmpChans tmpPts maxEpochs minPts minSecs epsEL ptsEL secsEL newEpLen delPts newEpochs
else
  EB.Info.FiltUpper = -1;
  EB.Info.FiltLower = -1;
end
EB.Info.sRate = EEG.srate;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Get input data info.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Get dimensions of data matrix and check that there is enough data.
[EB.Info.NumChansOrg,EB.Info.NumPts,EB.Info.NumEpochs] = size(EEG.data);
%Minimum number of epochs of input data for function to run.
minEpLimit = 30;
assert(EB.Info.NumEpochs >= minEpLimit,['Only %i epochs with length %i points of input data. At least %i epochs\n',...
                                        'are required. Try again with a shorter epoch length or more data.\n'],EB.Info.NumEpochs,EB.Info.NumPts,minEpLimit)
clear minEpLimit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Get channel names and indices of excluded channels.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make list of channel names, AllChans (1 x .NumChansOrg cell array).
AllChans = {EEG.chanlocs.labels};
%Get excluded channel indices and EB.NumChans.
if ~isempty(EBinput.ExChans)
  corrEx=~ismember(upper(EBinput.ExChans),upper(AllChans));
  if ~all(ismember(upper(EBinput.ExChans),upper(AllChans)))
    fprintf([mBeg 'The following channels flagged for exclusion are not listed in\n',...
             begSpace '%s.chanlocs.labels:'],inputname(1));
    fprintf(' ''%s''',EBinput.ExChans{corrEx});
    fprintf(['.\n' begSpace 'These unrecognized channels will not be excluded.\n']);
  end
  ExChanInd = find(ismember(upper(AllChans),upper(EBinput.ExChans)) == 1);
  EB.Info.NumChans = EB.Info.NumChansOrg - length(ExChanInd);
  clear corrEx
else
  EB.Info.NumChans = EB.Info.NumChansOrg;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Make electrical difference matrix.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initialize ED (.NumChans x .NumChans-1 x .NumEpochs).
ED = zeros(EB.Info.NumChans,EB.Info.NumChans,EB.Info.NumEpochs);
ED(:,:,:) = NaN;
%Lists of channel indices to loop through, without excluded channels.
EDloop = 1:EB.Info.NumChans;
if ~isempty(EBinput.ExChans), EDloop(ismember(EDloop,ExChanInd)) = []; end
LoopLen = length(EDloop);
%Variables for number of status dots. Must be divisible by 2.
numDots = 50;
totLoops = ((EB.Info.NumChans.^2) - EB.Info.NumChans) / 2;
LoopCount = 0;
DotCount = 1;
DotHalf = (numDots - 4) / 2;
%Variables for status percentage
numPer = 100;
PerCount = 0;
%Display status bar.
dotStr1 = '';
dotStr2 = '';
spStr1 = repmat(sprintf(' '), 1, DotHalf);
spStr2 = repmat(sprintf(' '), 1, DotHalf);
fprintf([mBeg 'Computing EDs for %i/%i chans, %i epochs, and %i points/epoch.\n'],EB.Info.NumChans,EB.Info.NumChansOrg,EB.Info.NumEpochs,EB.Info.NumPts);
fprintf([begSpace '[' dotStr1 spStr1 '%3i%%' dotStr2 spStr2 ']'],PerCount);
%Loop to actually create the ED matrix.
for a = 1:(LoopLen-1)
  for b = (a+1):LoopLen
    %Increment status bar.
    LoopCount = LoopCount + 1;
    if LoopCount > ((totLoops / numPer) * PerCount)
      if LoopCount > ((totLoops / numDots) * DotCount)
        DotCount = DotCount + 1;
        if DotCount <= DotHalf
          dotStr1 = repmat(sprintf('.'), 1, DotCount);
          dotStr2 = '';
          spStr1 = repmat(sprintf(' '), 1, DotHalf-DotCount);
          spStr2 = repmat(sprintf(' '), 1, DotHalf);
        elseif DotCount >= (DotHalf + 4)
          dotStr1 = repmat(sprintf('.'), 1, DotHalf);
          dotStr2 = repmat(sprintf('.'), 1, DotCount-DotHalf-4);
          spStr1 = '';
          spStr2 = repmat(sprintf(' '), 1, numDots-DotCount);
        end
      end
      PerCount = PerCount + 1;
      revStr = repmat(sprintf('\b'), 1, numDots+1);
      if (DotCount < DotHalf ) || (PerCount == 100)
        fprintf([revStr dotStr1 spStr1 '%3i%%' dotStr2 spStr2 ']'],PerCount);
      else
        fprintf([revStr dotStr1 spStr1 '.%2i%%' dotStr2 spStr2 ']'],PerCount);
      end
    end
    %Make difference matrix, diffE (.NumChans x .NumChans).
    diffE = squeeze(EEG.data(EDloop(a),:,:) - EEG.data(EDloop(b),:,:));
    %Create ED values and add to ED.
    ED(EDloop(a),EDloop(b),:) = var(diffE,1,1);
  end
end
fprintf([repmat(sprintf('\b'), 1, numDots+2+length(mBeg))]);
clear a b ExChanInd EDloop compLoop LoopLen numDots totLoops LoopCount DotCount DotHalf
clear numPer PerCount revStr dotStr1 dotStr2 spStr1 spStr2

%%%%%%%%%%%%%%%%%%%%%%%%%
%Vectorize and scale EDs.
%%%%%%%%%%%%%%%%%%%%%%%%%
%Get vectorized upper triangular part of ED matrix, EDvect, then create
%copy of ED, ScaledED. then create scaling factor and apply to
%EDvect and ScaledED.
if EBinput.Verbose == 2, fprintf([mBeg 'Creating ED vector and scaling ED values.\n']); end
if EBinput.Verbose < 2, fprintf([mBeg 'Creating ED frequency distribution and finding bridged channels.\n']); end
%Create EDvect.
EDvect = transpose(ED(~isnan(ED)));
%Create copy of ED, ScaledED.
ScaledED = ED;
%Get scaling factor.
EB.Info.EDscale = 100 / median(EDvect);
%Apply scaling factor.
EDvect = EDvect * EB.Info.EDscale;
ScaledED = ScaledED * EB.Info.EDscale;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create ED frequency distribution.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if EBinput.Verbose == 2, fprintf([mBeg 'Creating ED frequency distribution.\n']); end
if EBinput.PlotMode == 0
  binMax = 12;
else
  binMax = 500;
end
halfBinSize = (EBinput.BinSize / 2);
binEdges = 0:EBinput.BinSize:binMax;
binCenters = halfBinSize:EBinput.BinSize:(binMax - halfBinSize);
EDcounts = histc(EDvect,binEdges);
EDcounts = EDcounts(:,1:end-1);
%Run spline interpolation.
BinSizeSPL = 0.05;
binCentersSPL = 0:BinSizeSPL:binMax;
EDcountsSPL = interp1(binCenters,EDcounts,binCentersSPL,'spline');
clear halfBinSize binEdges binCenters EDcounts

%%%%%%%%%%%%%%%%%
%Find local peak.
%%%%%%%%%%%%%%%%%
%%%Find first peak between 0 and LPcutoff.
LPcutoff = 3;
if EBinput.Verbose == 2, fprintf([mBeg 'Finding ED cutoff.\n']); end
%Size of peak search window.
PeakSpan = 1 / BinSizeSPL;
%Create vector consisting of zero-padded early (0 to 5) part of ED
%distribution to search for peaks.
fPeakVect = [zeros(1,PeakSpan) EDcountsSPL(1,1:(LPcutoff+1)/BinSizeSPL)];
%Variable to hold index of peak.
PeakBinMin = [];
for a = (PeakSpan+1):LPcutoff/BinSizeSPL
  if all(fPeakVect(1,a) > fPeakVect(1,[(a - PeakSpan):(a - 1) (a + 1):(a + PeakSpan)]))
    PeakBinMin = a - PeakSpan;
    break
  end
end
clear PeakSpan fPeakVect

%%%%%%%%%%%%%%%
%Find EDcutoff.
%%%%%%%%%%%%%%%
%X-value of min between peak and LMcutoff is EDcutoff.
LMcutoff = 5;
if isempty(PeakBinMin)
  EB.Info.EDcutoff = -1;
else
  EDbinIndsMin = (PeakBinMin + 1):(LMcutoff / BinSizeSPL);
  [~,EDcoAllIndsMin] = min(EDcountsSPL(1,EDbinIndsMin));
  EDcoIndMin = PeakBinMin + EDcoAllIndsMin(1,1);
  EB.Info.EDcutoff = binCentersSPL(EDcoIndMin);
end
clear PeakBinMin EDbinIndsMin EDcoAllIndsMin EDcoIndMin

%%%%%%%%%%%%%%%%%%%%%%%
%Find bridged channels.
%%%%%%%%%%%%%%%%%%%%%%%
if EBinput.Verbose == 2, fprintf([mBeg 'Finding bridged channels.\n']); end
%No ED cutoff.
if EB.Info.EDcutoff == -1
  EB.Bridged.Labels = cell(1,1);
  EB.Bridged.Pairs= cell(2,1);
  EB.Bridged.Indices = [];
  EB.Bridged.Count = 0;
else
  preBridged = ScaledED < EB.Info.EDcutoff;
  finBridged = squeeze(sum(preBridged,3));
  [BRrow,BRcol] = find(finBridged >= (EBinput.BCT * EB.Info.NumEpochs));
  BRrow = squeeze(transpose(BRrow));
  BRcol = squeeze(transpose(BRcol));
  BRallIndsUnq = unique([BRrow BRcol]);
  if ~isempty(BRallIndsUnq)
    %ED cutoff exists, there are bridged channels.
    EB.Bridged.Labels = AllChans(BRallIndsUnq);
    EB.Bridged.Pairs(1,:) = AllChans(BRrow);
    EB.Bridged.Pairs(2,:) = AllChans(BRcol);
    EB.Bridged.Indices = BRallIndsUnq;
    EB.Bridged.Count = length(BRallIndsUnq);
  else
    %ED cutoff exists, no bridged channels.
    EB.Bridged.Labels = cell(1,1);
    EB.Bridged.Pairs = cell(2,1);
    EB.Bridged.Indices = [];
    EB.Bridged.Count = 0;
  end
  clear ScaledED preBridged finBridged BRrow BRcol BRallIndsUnq
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plot distribution and EDcutoff.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (EBinput.PlotMode == 2) || ((EBinput.PlotMode == 1) && (EB.Bridged.Count ~= 0))
  if EBinput.Verbose > 0, fprintf([mBeg 'Plotting ED frequency distribution and cutoff.\n']); end
  %Close previous figures created by this function.
  preEBfig = findobj('Type','Figure');
  for a = 1:length(preEBfig)
    if strcmpi(get(get(gca(preEBfig(a)),'title'),'string'), 'Spline-interpolated ED distribution');
      close(preEBfig(a));
    end
  end
  %Plot the distribution.
  EB.Info.FigHandle = figure('Name',[mBeg inputname(1)]);
  plot(binCentersSPL, EDcountsSPL, 'b-')
  set(gca,'XLim',[0 binMax]);
  %Plot EDcutoff.
  if EB.Info.EDcutoff ~= -1
    oldYLim = get(gca,'YLim');
    hold on
    plot([EB.Info.EDcutoff EB.Info.EDcutoff], [0 oldYLim(1,2) * 2], 'g-');
    hold off
    set(gca,'YLim',[0 oldYLim(1,2)]);
  end
  %Add title and axis labels.
  title('Spline-interpolated ED distribution');
  xlabel('Electrical Distance (ED)');
  ylabel('Number of epochs');
  %Add annotation.
  EDplotText = cell(5,1);
  EDplotText(1,1) = cellstr(['eBridge.m ', char(169), 'D. Alschuler 2013']);
  EDplotText(2,1) = cellstr('Alschuler et al. (2014)');
  EDplotText(3,1) = cellstr('Clin Neurophysiol 125(3):484-490');
  PlotChanStr = [num2str(EB.Info.NumChans), '/' num2str(EB.Info.NumChansOrg)];
  PlotEpStr = num2str(EB.Info.NumEpochs);
  PlotStrLen = max([length(PlotChanStr), length(PlotEpStr)]);
  PlotChanSp = repmat(' ',1,PlotStrLen-length(PlotChanStr));
  PlotEpSp = repmat(' ',1,PlotStrLen-length(PlotEpStr));
  EDplotText(4,1) = cellstr(['Channels: ' PlotChanSp PlotChanStr]);
  EDplotText(5,1) = cellstr(['Epochs: ' PlotEpSp PlotEpStr]);
  text(0.97,0.97,EDplotText,'Units','Normalized','HorizontalAlignment','Right','VerticalAlignment','Top','FontSize',8,'FontName','FixedWidth');
  clear OldYLim PlotChanStr PlotEpStr PlotStrLen PlotChanSp PlotEpSp EDplotText
else
  EB.Info.FigHandle = [];
end
clear binMax binCentersSPL EDcountsSPL

%%%%%%%%%%%%%%
%Finalization.
%%%%%%%%%%%%%%
EB.Info.BCT = EBinput.BCT;
EB.Info.BinSize = EBinput.BinSize;
EB.Info.EEGtype = EBinput.EEGtype;
EB.Info.ExChans = EBinput.ExChans;
EB.Bridged = orderfields(EB.Bridged);
EB.Info = orderfields(EB.Info);
EB = orderfields(EB);
varargout{1} = EB;
if nargout == 2, varargout{2} = ED; end
fprintf([mBeg 'Number of bridged channels: %i\n'], EB.Bridged.Count);
if EBinput.Verbose > 0
  fprintf([mBeg 'Bridged channel labels:    ']);
  if isempty(EB.Bridged.Labels{1,1});
    fprintf(' NONE');
  else
    labelspace = sprintf(' %s', EB.Bridged.Labels{1,:});
    fprintf('%s',labelspace);
  end
  fprintf('\n');
end
if EBinput.Verbose == 2
  fprintf([mBeg 'Bridged channel pairs:     ']);
  if isempty(EB.Bridged.Pairs{1,1})
    fprintf(' NONE');
  else
    for a = 1:size(EB.Bridged.Pairs,2), fprintf(' (%s,%s)', EB.Bridged.Pairs{1,a}, EB.Bridged.Pairs{2,a}); end
  end
  fprintf('\n')
end
clear a EB ED