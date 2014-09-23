function EEG = csc_artifact_rejection(EEG, method)

method = lower(method);

switch method
    case 'eeglab'
        
        [~, EEG.bad_regions] = pop_rejcont(EEG,...
            'freqlimit',    [20, 40],...  % lower and upper limits of frequencies
            'epochlength',  5,...         % window size to examine (in s)
            'overlap',      2,...         % amount of overlap in the windows
            'threshold',    10,...        % frequency upper threshold in dB
            'contiguous',   2,...         % number of contiguous epochs necessary to label a region as artifactual
            'addlength',    0.5,...       % seconds to add to each artifact side
            'onlyreturnselection', 'on',... % do not actually remove it, just label it
            'taper',        'hamming',... % taper to use before FFT
            'verbose',      'off');
        
    case 'wispic'
               
        [fft_all, freq_range] = csc_average_reference_and_FFT(EEG);
        
        csc_concatenate_FFTs(subname)
        
        csc_artifact_detection_semiauto(subname)
        
        filenameall=[subname '_fftANok_AR.mat'];
        load(filenameall, 'fftNREM_SWAartest', 'fftNREM_HFartest');
        
        badepSWA = [];
        badepHF = [];
        for ch = 1:EEG.nbchan
            if isnan(nanmean(fftNREM_SWAartest(ch,:)))
            else
                badepSWA = [badepSWA find(isnan(fftNREM_SWAartest(ch,:)))];
            end
            if isnan(nanmean(fftNREM_HFartest(ch,:)))
            else
                badepHF = [badepHF find(isnan(fftNREM_HFartest(ch,:)))];
            end
        end
        
        badepSWA = unique(badepSWA);
        badepHF = unique(badepHF);
        
        WISPICbadsamples = [];
        for iepoch = 1:size(badepSWA,2)
            WISPICbadsamples = [WISPICbadsamples (((badepSWA(iepoch)-1)*(6*200))+1):(badepSWA(iepoch)*(6*200)) ];
        end
        for iepoch = 1:size(badepHF,2)
            WISPICbadsamples = [WISPICbadsamples (((badepHF(iepoch)-1)*(6*200))+1):(badepHF(iepoch)*(6*200)) ];
        end
        
        WISPICbadsamples = unique(WISPICbadsamples);
        %EEG.bad_samples = round(WISPICbadsamples);
        EEG.bad_samples = sort(EEG.bad_samples);
        
    otherwise
        fprintf(1, 'Error: unrecognised option call: %s', method);
end

