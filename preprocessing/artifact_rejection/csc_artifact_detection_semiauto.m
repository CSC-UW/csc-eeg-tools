function csc_artifact_detection_semiauto(subject)

%bc = bad channels (optional argurment)

if nargin < 3
    bc=[]; 
end

filenameall=[subject '_fftANok'];

%% threshold for artifact detection single channel (default= p95)

eval(['load ',filenameall,'.mat']);
nch=size(fftNREM_SWAar,1);

badchannels=zeros(1,nch);
NREMepAll=~isnan(fftNREM_SWAar(1,:));
araus_ndx=[]; araus_epsixstart=[]; 
araus_epsixend=[];

yscale=[];
for c = 1: nch;
    %    ndx185=inside185(:); int=intersect(c,ndx185);
    figure('Units','characters','Position',[5 5 250 50]);
    if find(bc==c)
        bc_string=['BAD CHANNEL'];
    else
        bc_string=[''];
    end
 
figure    
hold on; set(gca,'Ylim',[0 2000]); title(['SWA Epochrange  ch= ',num2str(c)  ],'Fontsize',20);
   
    plot(fftNREM_SWAar(c,:));
    %
    hold on;plot(araus_epsixstart,yscale,'ro');hold on; plot(araus_epsixend,yscale,'go');   title(['channel=' num2str(c) bc_string],'Fontsize',20); hold on;


    %     for c=1:size(lenghtofSleepep_sixsec,1);
    %     line([lenghtofSleepep_sixsec(c,1) lenghtofSleepep_sixsec(c,1)],[0 2000],'LineWidth',2,'Color','black');hold on;
    %     line([lenghtofSleepep_sixsec(c,2) lenghtofSleepep_sixsec(c,2)],[0 2000],'LineWidth',2,'Color','r');hold on;
    %     end
    p90=prctile(fftNREM_SWAar(c,:),90);line([0 5000], [p90 p90],'linewidth',4,'color','r');
    p99=prctile(fftNREM_SWAar(c,:),99.5);line([0 5000], [p99 p99],'linewidth',4,'color','black'); % Change upper cutoff to 99 perrcentile (was 99.9)
    
    if isnan (p99)
    else
        ylimitp99=2*p99;
        axis([0 5000 0 ylimitp99])
    end
    
    %newthr= [];
    newthr=input(['channel=' num2str(c) ' change threshold?   '],'s');
        
%     while ~isempty(newthr) && isnan(str2double(newthr))
%         display('MUST RE-ENTER: You entered a threshold that was not numeric');
%         newthr=input(['channel=' num2str(c) ' change threshold?   '],'s');
%     end
newthr=str2double(newthr);
    
    if isempty(newthr)
        p99all(c)=p99;
    else
        p99all(c)= newthr;
        if newthr==0;
            badchannels(c)=c;
        end
    end
    clear newthr;
    figure('Units','characters','Position',[5 5 300 70]);
%     for cy=1:size(lenghtofSleepep_sixsec,1);
%         p=patch([lenghtofSleepep_sixsec(cy,1); lenghtofSleepep_sixsec(cy,1);lenghtofSleepep_sixsec(cy,2); lenghtofSleepep_sixsec(cy,2)],[0; 2000; 2000; 0],'y'); set(p,'EdgeColor',[1 1 1]);
%         hold on; p=patch([lenghtofSleepep_sixsec(cy,3); lenghtofSleepep_sixsec(cy,3); lenghtofSleepep_sixsec(cy,4);lenghtofSleepep_sixsec(cy,4)],[0; 2000; 2000; 0],'r'); set(p,'EdgeColor',[1 1 1]);
%         hold on;
%     end
    hold on;plot(fftNREM_HFar(c,:));set(gca,'Ylim',[0 4]);title(['HF Epochrange  ch= ',num2str(c), '  Yes 185'],'Fontsize',20);hold on;
    hold on;plot(araus_epsixstart,yscale,'ro');hold on; plot(araus_epsixend,yscale,'go');hold on;
    %     for c=1:size(lenghtofSleepep_sixsec,1);
    %     line([lenghtofSleepep_sixsec(c,1) lenghtofSleepep_sixsec(c,1)],[0 800],'LineWidth',2,'Color','black');hold on;
    %     line([lenghtofSleepep_sixsec(c,2) lenghtofSleepep_sixsec(c,2)],[0 800],'LineWidth',2,'Color','r');hold on;
    %     end
    p90h=prctile(fftNREM_HFar(c,:),90);line([0 5000], [p90h p90h],'linewidth',4,'color','r');
    p98=prctile(fftNREM_HFar(c,:),99.5);line([0 5000], [p98 p98],'linewidth',4,'color','black');% Change upper cutoff to 99 perrcentile (was 99.5)
    
    % newthr= [];
    newthr=input(['channel=' num2str(c) ' change threshold?   '],'s');

%     while ~isempty(newthr) && isnan(str2double(newthr))
%         display('MUST RE-ENTER: You entered a threshold that was not numeric');
%         newthr=input(['channel=' num2str(c) ' change threshold?   '],'s');
%     end
newthr=str2double(newthr);
    
    if isempty(newthr)
        p98all(c)=p98;
    else
        p98all(c)= newthr;
        if newthr==0;
            badchannels(c)=c;
        end
    end
    clear newthr p98 p99 int; close all
end
eval(['save ',filenameall,'.mat p98all p99all araus_epsixend -append -v7.3']);


%% artifacts detection with moving average and final bad channels rejection
badepallch=cell(nch,1);
fftNREM_SWAartest=fftNREM_SWAar; fftNREM_HFartest=fftNREM_HFar;
Epochrange=6;Factor_SWA=2;Factor_HF=5;
for ch=1:nch;
    if  badchannels(ch)>0;
        fftNREM_SWAartest(ch,:)=NaN;
    else
        for i=1:numepo;
            p99=p99all(ch);
            SlidingMean(i)=nanmean(fftNREM_SWAar(ch,max(i-Epochrange,1):min(i+Epochrange,numepo)));
            if SlidingMean(i)==NaN;
                continue
            else
                if fftNREM_SWAartest(ch,i)>=(1+Factor_SWA)*SlidingMean(i)||fftNREM_SWAartest(ch,i)>=p99;
                    fftNREM_SWAartest(ch,i)=NaN;
                end;
            end
        end
    end

    goodepchSWA(ch)=sum(~isnan(fftNREM_SWAartest(nch,:)));
    goodepchHF(ch)=sum(~isnan(fftNREM_HFartest(nch,:)));

    araus_ndx=[];araus_epsixstart=[]; araus_epsixend=[];
    yscale=repmat(15,length(araus_ndx),1);
    figure('Units','characters','Position',[5 5 300 70]);
%     for cy=1:size(lenghtofSleepep_sixsec,1);
%         p=patch([lenghtofSleepep_sixsec(cy,1); lenghtofSleepep_sixsec(cy,1);lenghtofSleepep_sixsec(cy,2); lenghtofSleepep_sixsec(cy,2)],[0; 2000; 2000; 0],'y'); set(p,'EdgeColor',[1 1 1]);
%         hold on; p=patch([lenghtofSleepep_sixsec(cy,3); lenghtofSleepep_sixsec(cy,3); lenghtofSleepep_sixsec(cy,4);lenghtofSleepep_sixsec(cy,4)],[0; 2000; 2000; 0],'r'); set(p,'EdgeColor',[1 1 1]);
%         hold on;
%     end
    hold on;plot(fftNREM_SWAartest(ch,:));set(gca,'Ylim',[0 800]);  title([''],'Fontsize',20);
%     SWA Epochrange  ch=' ,num2str(ch),'  Yes 185  ep=',num2str(goodepchSWA(ch)),'/',num2str(NREMepAll))
    hold on; plot(araus_epsixstart,yscale,'ro');hold on; plot(araus_epsixend,yscale,'go');hold on;
    
     if ch == 1
    gosignal=input(['ok'],'s');

    while ~isempty(gosignal) 
    end
    gosignal= [];
     end
    %     for c=1:size(lenghtofSleepep_sixsec,1);x
    %     line([lenghtofSleepep_sixsec(c,1) lenghtofSleepep_sixsec(c,1)],[0 800],'LineWidth',2,'Color','black');hold on;
    %     line([lenghtofSleepep_sixsec(c,2) lenghtofSleepep_sixsec(c,2)],[0 800],'LineWidth',2,'Color','r');hold on;
    %     end
%     finrej=input('reject channel?   ');
%     if isempty(finrej)
%         close all;
%         continue
%     else
%         badchannels(nch)=nch;
%         fftNREM_SWAartest(nch,:)=NaN;
%     end; 
close all;
end
clear SlidingMean p99 finrej  yscale
yscale=repmat(0.1,length(araus_ndx),1);
for ch=1:nch;

    if  badchannels(ch)>0;
        fftNREM_HFartest(ch,:)=NaN;
    else
        for i=1:numepo;
            p98=p98all(ch);
            SlidingMean(i)=nanmean(fftNREM_HFar(ch,max(i-Epochrange,1):min(i+Epochrange,numepo)));
            if SlidingMean(i)==NaN;
                continue
            else
                if fftNREM_HFartest(ch,i)>=(1+Factor_HF)*SlidingMean(i)||fftNREM_HFartest(ch,i)>=p98;
                    fftNREM_HFartest(ch,i)=NaN;
                end;
            end
        end
    end
    figure('Units','characters','Position',[5 5 300 70]);
%     for cy=1:size(lenghtofSleepep_sixsec,1);
%         p=patch([lenghtofSleepep_sixsec(cy,1); lenghtofSleepep_sixsec(cy,1);lenghtofSleepep_sixsec(cy,2); lenghtofSleepep_sixsec(cy,2)],[0; 2000; 2000; 0],'y'); set(p,'EdgeColor',[1 1 1]);
%         hold on; p=patch([lenghtofSleepep_sixsec(cy,3); lenghtofSleepep_sixsec(cy,3); lenghtofSleepep_sixsec(cy,4);lenghtofSleepep_sixsec(cy,4)],[0; 2000; 2000; 0],'r'); set(p,'EdgeColor',[1 1 1]);
%         hold on;
%     end
    hold on;plot(fftNREM_HFartest(ch,:));set(gca,'Ylim',[0 0.8]);title(['' ],'Fontsize',20);
%     HF Epochrange  ch= ',num2str(ch),'  Yes 185  ep=',num2str(goodepchHF(ch)),'/',num2str(NREMepAll),' (',num2str(goodepchHF/NREMepAll*100),' %)
    hold on;plot(araus_epsixstart,yscale,'ro');hold on; plot(araus_epsixend,yscale,'go');hold on;
    %     for c=1:size(lenghtofSleepep_sixsec,1);
    %     line([lenghtofSleepep_sixsec(c,1) lenghtofSleepep_sixsec(c,1)],[0 800],'LineWidth',2,'Color','black');hold on;
    %     line([lenghtofSleepep_sixsec(c,2) lenghtofSleepep_sixsec(c,2)],[0 800],'LineWidth',2,'Color','r');hold on;
    %     end
    
%      if ch == 1
%     gosignal=input(['ok'],'s');
% 
%     while ~isempty(gosignal) 
%     end
%     gosignal= [];
%      end
    
    
%     finrej=input('reject channel?   ');
%     if isempty(finrej)
%         close all;
%         continue
%     else
%         badchannels(ch)=ch;
%         fftNREM_HFartest(ch,:)=NaN;
%     end; 
    close all;
end

%add the user defined bad channels to the index
% for i=1:length(bc)
%    badchannels(bc(i))=bc(i); 
% end
   %%%added: badchannels(bc)=bc; 3/6/10 FF%%
badchannels(bc)=bc;
badchannelsNdx=find(badchannels>0);goodchNdx=find(badchannels==0);close all;

%%%%%added 
filenameFFTAN=[subject '_fftANok'];
%pack;
load(filenameFFTAN,'ffttot')
ffttot(badchannelsNdx,:,:)=NaN;
%save (filenameFFTAN, 'ffttot', '-v7.3', '-append')

eval(['save ',filenameFFTAN,'_AR.mat ffttot badchannels badchannelsNdx goodchNdx badepallch fftNREM_SWAartest fftNREM_HFartest goodepchSWA goodepchHF -v7.3']);
clear ffttot 
%%%%added
%% optional - save separate mat file with rejection matrix only
%save([filenameall 'rejection_matrices'], 'fftNREM_SWAartest', 'fftNREM_HFartest');



