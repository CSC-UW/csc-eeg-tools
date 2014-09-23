function AvgRef_FFT_AllChannels(dataf, badchannels, subject)

%reference the signals to the average of 185 channels

% load insidenew;
% load inside185new;
%sRateRatioNumerator=128;
sRate = 200;

%figure out when the first six second epoch is in the file
epoch_offset=1;
% data_offset=0;

    nch=size(dataf,1);
    dataf(badchannels,:)=NaN; %set the bad channels to NAN


    %average reference
    average=nanmean(dataf(:,:),1); % 256 channels
    %average=nanmean(dataf(insidenew(inside185),:),1); % 185 channels
    for channel=1:nch
        dataref(channel,:)=dataf(channel,:)-average;
    end

    numepo=floor((size(dataref,2)/sRate)/6);
    ffttot=NaN(nch,240,numepo+1);
    
    
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %temporarily create an ffttot of the average signal
%     ffttotAvg=NaN(1,240,numepo+1);
%     epoch_count=1;
%     for epochNum=epoch_offset:epoch_offset+numepo-1
%             epochNum;
%             start= sesscoringinfoss(epochNum,1);
%             ending=start+(128*6);
%             ffte=pwelch(average(start:ending),[],[],6*sRateRatioNumerator,sRateRatioNumerator);
%             ffte=ffte(1:240);
%             ffttotAvg(1,:,epoch_count)=ffte;
%             epoch_count=epoch_count+1;
%     end
%         
%     epoch_offset=epoch_offset+numepo+1
%     filenameFFT=[apath numfilstr basefilename '_fftAvg'];
%     save(filenameFFT, 'ffttotAvg', 'numepo');
%     clear ffttotAvg ffte data datax dataref
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    for channel=1:nch
        channel
        epoch_count=1;
        for epochNum=1:numepo
            epochNum;
            start= ((epochNum-1)*(sRate*6))+1;
            ending=start+(sRate*6);
            [ffte,F]=pwelch(dataref(channel,start:ending),[],[],6*sRate,sRate);
            ffte=ffte(1:240);
            ffttot(channel,:,epoch_count)=ffte;
            epoch_count=epoch_count+1;
        end
    end
    
    %epoch_offset=epoch_offset+numepo+1
    filenameFFT=[subject '_fftANok.mat'];
    save(filenameFFT, 'ffttot', 'F', 'numepo', '-v7.3');
    clear ffttot ffte dataref

