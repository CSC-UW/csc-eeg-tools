function concatFFTtot(subject)
%concats all the ffttot into one larege variable

ffttotAN=[];
numepoAN=0;

    filenameFFT=[subject '_fftANok.mat'];
   load(filenameFFT);
    
    
    
    ffttotAN=cat(3,ffttotAN,ffttot);
    clear ffttot;
    numepoAN=numepoAN+numepo; %+1; %comment next time
    


ffttot=ffttotAN; clear ffttotAN;
numepo=numepoAN; clear numepoAN;

%% calculate SWA and spindle power
% tic

bins=1/6:1/6:(1/6*240); epochsize=30; withinsize=6;
swabins=4:27;allspindlesbins=72:90;lowspindlesbins=72:84;highspindlesbins=85:90;
fftswa_wn=[];fftlowspi_wn=[];ffthighspi_wn=[];


fftswa_ss=squeeze(mean(ffttot(:,swabins,:),2));fftswa_wn=[fftswa_wn fftswa_ss];
fftlowspi_ss=squeeze(mean(ffttot(:,lowspindlesbins,:),2));fftlowspi_wn=[fftlowspi_wn fftlowspi_ss];
ffthighspi_ss=squeeze(mean(ffttot(:,highspindlesbins,:),2));ffthighspi_wn=[ffthighspi_wn ffthighspi_ss];
clear fftswa_ss fftlowspi_ss ffthighspi_ss



highrangeart=121:180;
off=0;fftNREM_SWAar=NaN(size(fftswa_wn,1),size(fftswa_wn,2));fftNREM_HFar=NaN(size(fftswa_wn,1),size(fftswa_wn,2));


fftNREM=ffttot;
for ch=1:size(fftNREM,1);
    fftNREM_SWA=squeeze(nanmean(fftNREM(ch,(swabins),:),2)); fftNREM_SWAar(ch,:)=fftNREM_SWA; %avg_SWA=nanmean(fftNREM_SWA,2);              %mean or median...
    fftNREM_HF=squeeze(nanmean(fftNREM(ch,(highrangeart),:),2)); fftNREM_HFar(ch,:)=fftNREM_HF; %avg_HF=nanmean(fftNREM_HF,2);
end

clear  fftNREM;
% pack


% save ([filenameFFTAN '2'], 'ffttot')
filenameFFT=[subject '_fftANok.mat'];
save(filenameFFT, 'numepo','fftNREM_SWAar', 'fftNREM_HFar',  'fftswa_wn', 'fftlowspi_wn', 'ffthighspi_wn', 'bins', '-v7.3', '-append');

% saveFFT=toc
