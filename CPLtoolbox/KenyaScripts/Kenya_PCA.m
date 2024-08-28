clear; clc;

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%Placeholder for pcadata
PCAdata=[];
%Placeholder for output
SPCAout=struct();
   
%Select files for PCA
moFiles='Yes';
PCAfiles={};
while strmatch(moFiles,'Yes')
    warning('Please select all ERP files for PCA')
    [filelist, pathname, filterindex] = uigetfile('*.erp','Pick the files to include','MultiSelect', 'on');
    if ~iscell(filelist)
        filelist={filelist};
    end
    PCAgroup=1;
    for i=1:length(filelist)
        if size(PCAfiles,1)>1
            if ~strncmp(PCAfiles{end,2},pathname,length(pathname))
                PCAgroup=PCAgroup+1;
            end
        end
        PCAfiles=cat(1,PCAfiles,{filelist{i} pathname PCAgroup});
    end  
    moFiles = questdlg('Do you have more files to load?', ...
	'Select Files');
end
SPCAout.PCAfiles=PCAfiles;

%Run the PCA
varStruct=[]; %placeholder for group and condition labels
for sub=1:size(PCAfiles,1)
    thisfile=PCAfiles{sub,1};
    pathname=PCAfiles{sub,2};
    %Load the ERP
    ERP = pop_loaderp( 'filename', thisfile, 'filepath', pathname );
    
    if exist('BINindx')~=1 %if BINidx is not a variable in workspace
        %Select the bins you want to use
        [BINindx,tf] = listdlg('ListString',ERP.bindescr,'PromptString',{'Select the Bin(s)', ...
            'you want to analyze'},'SelectionMode','multi');
    end
    
    %Find out if user wants to subtract one of the bins for the PCA
    if exist('diffBIN')~=1
        diffBIN=0;
        DoDiff = questdlg('Do you want to run PCA on a difference between conditions?', 'Subract Bins?');
        if strncmp(DoDiff,'Yes',3)
            [diffBIN,tf] = listdlg('ListString',ERP.bindescr,'PromptString',{'Select the condition', ...
                'you want to subtract', 'from the other conditions', 'prior to PCA analysis'},'SelectionMode','single');
        end
    end
    %Set times for analysis window
    if exist('PCAwin')~=1 %if 'PCAwin' is not a variable in the workspace
            list = {};
            for t=1:length(ERP.times)
                list{t}=num2str(ERP.times(t));
            end
            [indx,tf] = listdlg('ListString',list,'PromptString',{'Select the START', ...
                                'time for the', 'PCA analysis'},'SelectionMode','single');
            PCAwin=indx;
            [indx,tf] = listdlg('ListString',list,'PromptString',{'Select the STOP', ...
                                'time for the', 'PCA analysis'},'SelectionMode','single');
            PCAwin=cat(2,PCAwin,indx);
            SPCAout.PCAtimes=ERP.times(PCAwin(1):PCAwin(2));
    end
    
    if ~isfield(SPCAout,'PCAchanlocs') %
        %Select Channels for Interpolation
        list = {ERP.chanlocs.labels};
        [indx,tf] = listdlg('ListString',list,'PromptString',{'Select the', ...
                                'channels you want', 'to include'});
        SPCAout.PCAchanlocs=ERP.chanlocs(indx);
        SPCAout.PCAchans=indx;
    end
    
    %Set up factor structure for data files [sub group condition]
    varStruct=cat(1,varStruct,[repmat(sub,length(BINindx)-double(diffBIN>0),1) repmat(PCAfiles{sub,3},length(BINindx)-double(diffBIN>0),1) [1:length(BINindx)-double(diffBIN>0)]']);
    
    if diffBIN>0
        Bins2Include=BINindx(BINindx~=diffBIN);
        for i=1:length(Bins2Include)
            ERP.bindata(:,:,Bins2Include(i))=ERP.bindata(:,:,Bins2Include(i))-ERP.bindata(:,:,diffBIN);
        end
    end
        
    %Add ERP to PCAdata (points x conditions x subjects  X  channels) 
    PCAdata=cat(1,PCAdata,reshape(ERP.bindata(SPCAout.PCAchans,PCAwin(1):PCAwin(2),BINindx(BINindx~=diffBIN)),length(SPCAout.PCAchans),length(SPCAout.PCAtimes)*(length(BINindx)-double(diffBIN>0)))');
    
    %IF USING DIFF BINS
    %PCAdata=cat(1,PCAdata,ERP.bindata(SPCAout.PCAchans,PCAwin(1):PCAwin(2),1)'-ERP.bindata(SPCAout.PCAchans,PCAwin(1):PCAwin(2),2)');
end
%quick reference variable for number of conditions
nCond=length(BINindx)-double(diffBIN>0);
SPCAout.ConditionLabels=ERP.bindescr(BINindx(BINindx~=diffBIN));

%figure out the number of components to retain
%90 percent rule
ncomps90=find(cumsum(flipud(eig(cov(PCAdata))))./sum(eig(cov(PCAdata)))>=.9,1);
disp(['90% Rule = ' num2str(ncomps90) ' spatial components'])

%parallel test
[latent, latentLow, latentHigh] = pa_test(PCAdata, 100, .05);
ncomps=find(latentHigh>latent,1)-1;
disp(['Parallel test = ' num2str(ncomps) ' spatial components'])

%run pca using Dien's pca toolbox thingy
[SPCAout.Spatial] = ep_doPCA('spat', 'Promax', 3, 'SVD', 'COV', ncomps, PCAdata', 'K');
 
%Attach varStruct
SPCAout.Spatial.varStruct=varStruct;

%Reorganize component scores for virtual ERP plots and measures
SPCAout.Spatial.vERPs=[];
for i=1:length(SPCAout.PCAtimes):size(SPCAout.Spatial.FacScr,1)
    SPCAout.Spatial.vERPs=cat(1,SPCAout.Spatial.vERPs,SPCAout.Spatial.FacScr(i:i+length(SPCAout.PCAtimes)-1,:)');
end

%remove baseline from vERPs for good measure (if min(PCAtimes)<0)
if min(SPCAout.PCAtimes)<0
    zerotime=find(SPCAout.PCAtimes==min(abs(SPCAout.PCAtimes-0)));
    for i=1:size(SPCAout.Spatial.vERPs,1)
        SPCAout.Spatial.vERPs(i,:)=SPCAout.Spatial.vERPs(i,:)-mean(SPCAout.Spatial.vERPs(i,1:zerotime));
    end
end

%--------------- Now do Temporal PCA --------------------
%figure out the number of components to retain
%90 percent rule
ncomps90=find(cumsum(flipud(eig(cov(SPCAout.Spatial.vERPs))))./sum(eig(cov(SPCAout.Spatial.vERPs)))>=.9,1);
disp(['90% Rule = ' num2str(ncomps90) ' temporal components'])

%parallel test
[latent, latentLow, latentHigh] = pa_test(SPCAout.Spatial.vERPs, 500, .05);
ncomps=find(latentHigh>latent,1)-1;
disp(['Parallel test = ' num2str(ncomps) ' temporal components'])

%run pca using Dien's pca toolbox thingy
[SPCAout.Temporal] = ep_doPCA('temp', 'Promax', 3, 'SVD', 'COV', ncomps, SPCAout.Spatial.vERPs, 'K');

%Reorganize component scores to match varStruct 
   %   (condition*subject X temporal component X spatial component)
SPCAout.Temporal.vERPs=[];
for i=1:SPCAout.Spatial.numFacs
    temp=SPCAout.Temporal.FacScr(i:SPCAout.Spatial.numFacs:end,:);
    size(temp)
    SPCAout.Temporal.vERPs=cat(3,SPCAout.Temporal.vERPs,SPCAout.Temporal.FacScr(i:SPCAout.Spatial.numFacs:end,:));
end

%Convert vERPs to Subject*Condition X Time X Component matrix
   %this just made it easier to use with 'varStruct' matrix
temp=SPCAout.Spatial.vERPs;
SPCAout.Spatial.vERPs=[];
for i=1:SPCAout.Spatial.numFacs
    SPCAout.Spatial.vERPs(:,:,i)=temp(i:SPCAout.Spatial.numFacs:end,:);
end


%Now setup output file
%STpcascores=reshape(SPCAout.Temporal.FacScr',SPCAout.Spatial.numFacs*SPCAout.Temporal.numFacs*nCond,size(PCAfiles,1))';
%Initialize full output
SPCAout.SPSS=table({PCAfiles{:,1}}',SPCAout.Spatial.varStruct(1:nCond:end,2),'VariableNames',{'PID', 'Group'});

    %generate column labels
    STcompLabels={};
    for scomp=1:SPCAout.Spatial.numFacs
        for cond=1:nCond
            for tcomp=1:SPCAout.Temporal.numFacs
                %STcompLabels=cat(2,STcompLabels,{eval(['''SC' num2str(scomp) 'TC' num2str(tcomp) strip(SPCAout.ConditionLabels{cond}) ''''])});
                STcompLabel=['SC' num2str(scomp) 'TC' num2str(tcomp) strip(SPCAout.ConditionLabels{cond})];
                SPCAout.SPSS = addvars(SPCAout.SPSS,SPCAout.Temporal.vERPs(SPCAout.Spatial.varStruct(:,3)==cond,tcomp,scomp),'NewVariableNames',STcompLabel);
            end
        end
    end
%Add Spatio-temporal scores
% for scom
% for cond=1:nCond
% for i=1:size(SPCAout.Temporal.vERPs,2)
%     SPCAout.SPSS = addvars(SPCAout.SPSS,SPCAout.Temporal.vERPs(SPCAout.Spatial.varStruct(:,3)==cond,i,scomp),'NewVariableNames',STcompLabels{i});
% end
% end
%Compute condition and Group averages for Spatial components


%Plot Results
colors='kbrmc';
styles={'-',':','--'};
conditionvec=unique(SPCAout.Spatial.varStruct(:,3));
groupvec=unique(SPCAout.Spatial.varStruct(:,2));
for comp=1:SPCAout.Spatial.numFacs
    figure;
    subplot(2,2,1)
    topoplot(SPCAout.Spatial.FacPat(:,comp),SPCAout.PCAchanlocs,'electrodes','on','emarker',{'o','k',10,1},'shading','interp','numcontour',0,'whitebk','on','gridscale',100);
    set(gcf,'color','white');
    caxis([-1 1]);
    colorbar
    subplot(2,2,3)
    hold on;
    title(['Component #' num2str(comp)])
    for g=1:length(groupvec)
        for i=1:length(conditionvec)
            plot(SPCAout.PCAtimes,squeeze(mean(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==conditionvec(i),:,comp),1)),[styles{g} colors(i)],'linewidth',5);
        end
        
        for i=1:length(conditionvec)
            plot(SPCAout.PCAtimes,squeeze(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==conditionvec(i),:,comp)),[styles{g} colors(i)]);
        end
    end
    legend(SPCAout.ConditionLabels)
    
    subplot(2,2,2)
    hold on;
    title(['Component #' num2str(comp)])
    legendtext={};
    for g=1:length(groupvec)
        for i=1:length(conditionvec)
            plot(SPCAout.PCAtimes,squeeze(mean(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==conditionvec(i)&SPCAout.Spatial.varStruct(:,2)==groupvec(g),:,comp),1)),[styles{i} colors(g)],'linewidth',5);
            legendtext=cat(2,legendtext,['Group' num2str(g) '.' SPCAout.ConditionLabels{i}]);
        end
    end
    legend(legendtext)
    
    subplot(2,2,4)
    plot(SPCAout.PCAtimes,SPCAout.Temporal.FacPat','linewidth',3)
    tcomplegend={};
    for i=1:SPCAout.Temporal.numFacs
        tcomplegend=cat(2,tcomplegend,['Tcomp' num2str(i)]);
    end
    legend(tcomplegend)
end
warning('PRESS ANY KEY TO CONTINUE')
pause

peakPick='Yes';
comp=1;
while strncmp(peakPick,'Yes',3)
    peakPick = questdlg('Do you want to find peaks and latencies?', 'Find Peaks?');
    if strncmp(peakPick,'Yes',3)
        prompt = {'Enter component label:','Enter polarity (''positive'' or ''negative''):'};
        dlgtitle = 'Peak Parameters';
        dims = [1 35];
        definput = {'ERP','positive'};
        answer = inputdlg(prompt,dlgtitle,dims,definput);
        %Plot For Peak Picking
        colors='kbrmc';
        styles={'-','--',':'};
        conditionvec=unique(SPCAout.Spatial.varStruct(:,3));
        groupvec=unique(SPCAout.Spatial.varStruct(:,2));
        for comp=1:SPCAout.Spatial.numFacs
            fig=figure();
            hold on;
            title(['Component #' num2str(comp)])
            for g=1:length(groupvec)
                for i=1:length(conditionvec)
                    ax=plot(SPCAout.PCAtimes,squeeze(mean(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==conditionvec(i),:,comp),1)),[styles{g} colors(i)],'linewidth',5);
                end
                legend(SPCAout.ConditionLabels)
            end
            
            thisComp = questdlg('Do you want to measure from this component?', 'Use this component?');
            if strncmp(thisComp,'Yes',3)
                [x y]=ginput(2);
                x(1)=round(x(1)/5)*5; %round to nearest 5
                x(2)=round(x(2)/5)*5;
                eval(['SPCAout.ERPdetails.' strtrim(answer{1}) '.tStart=x(1);'])
                eval(['SPCAout.ERPdetails.' strtrim(answer{1}) '.tStop=x(2);'])
                close
                %NOW MEASURE PEAK/mean AMPS, LATS, and FRAC AREA LATS
                for c=1:length(conditionvec)
                    %MAKE FAKE ERPset in order to use ERPlab functions
                    tempERP=ERP;
                    tempERP.times=SPCAout.PCAtimes;
                    tempERP.bindata=squeeze(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==c,:,comp));
                    tempERP.nchan=size(tempERP.bindata,1);
                    tempERP.nbin=1;
                    
                    %MEAN AMPLITUDE
%                     temp=squeeze(mean(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==c,SPCAout.PCAtimes>=x(1)&SPCAout.PCAtimes<=x(2),comp),2));
%                     eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,temp,''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) 'meanAmp'');'])
                    
                    %MEAN AMP ERPlab
                    ALLERP = pop_geterpvalues( tempERP, [x(1) x(2)], [1],  1:size(tempERP.bindata,1) , 'Baseline', 'none', 'Binlabel', 'on', 'FileFormat', 'wide', 'Fracreplace', 'NaN',...
                         'InterpFactor',  1, 'Measure', 'meanbl', 'PeakOnset',  1, 'Resolution',  3, 'SendtoWorkspace', 'on' );
                     eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,ERP_MEASURES'',''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) num2str(x(1)) '-' num2str(x(2)) 'meanAmp'');']);
                     
                    %PEAK AMP ERPlab
                    ALLERP = pop_geterpvalues( tempERP, [x(1) x(2)], [1],  1:size(tempERP.bindata,1) , 'Baseline', 'none', 'Binlabel', 'on', 'FileFormat', 'wide', 'Fracreplace', 'NaN',...
                    'InterpFactor',  1, 'Measure', 'peakampbl', 'Neighborhood',  3, 'PeakOnset',  1, 'Peakpolarity', lower(answer{2}), 'Peakreplace', 'absolute',...
                    'Resolution',  3, 'SendtoWorkspace', 'on' );
                    eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,ERP_MEASURES'',''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) num2str(x(1)) '-' num2str(x(2)) 'peakAmp'');']);
                    
                    %Trough-to-Peak / Peak-to-trough
                    prevPeakTrough=[];
                    prevPeakTroughlat=[];
                    minIDX=find(abs(tempERP.times-x(1))==min(abs(tempERP.times-x(1))));
                    maxIDX=find(abs(tempERP.times-x(2))==min(abs(tempERP.times-x(2))));
                    switch strtrim(answer{2})
                        case 'positive'
                            for subc=1:size(tempERP.bindata,1)
                                [peaks,locs]=findpeaks(tempERP.bindata(subc,(minIDX-(maxIDX-minIDX)):minIDX,1)*-1,tempERP.times((minIDX-(maxIDX-minIDX)):minIDX));
                                if ~isempty(peaks)
                                    prevPeakTrough=cat(1,prevPeakTrough,peaks(end)*-1);
                                    prevPeakTroughlat=cat(1,prevPeakTroughlat,locs(end));
                                else
                                    [amp,lat]=min(tempERP.bindata(subc,(minIDX-(maxIDX-minIDX)):minIDX,1));
                                    prevPeakTrough=cat(1,prevPeakTrough,amp);
                                    temp=tempERP.times((minIDX-(maxIDX-minIDX)):minIDX);
                                    prevPeakTroughlat=cat(1,prevPeakTroughlat,temp(lat));
                                end
                            end
                            eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,prevPeakTrough,''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) num2str(x(1)) '-' num2str(x(2)) 'prevTroughamp'');']);
                            eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,prevPeakTroughlat,''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) num2str(x(1)) '-' num2str(x(2)) 'prevTroughlat'');']);
                        case 'negative'
                            for subc=1:size(tempERP.bindata,1)
                                [peaks,locs]=findpeaks(tempERP.bindata(subc,(minIDX-(maxIDX-minIDX)):minIDX,1),tempERP.times((minIDX-(maxIDX-minIDX)):minIDX));
                                if ~isempty(peaks)
                                    prevPeakTrough=cat(1,prevPeakTrough,peaks(end));
                                    prevPeakTroughlat=cat(1,prevPeakTroughlat,locs(end));
                                else
                                    [amp,lat]=max(tempERP.bindata(subc,(minIDX-(maxIDX-minIDX)):minIDX,1));
                                    prevPeakTrough=cat(1,prevPeakTrough,amp);
                                    temp=tempERP.times((minIDX-(maxIDX-minIDX)):minIDX);
                                    prevPeakTroughlat=cat(1,prevPeakTroughlat,temp(lat));
                                end
                            end
                            eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,prevPeakTrough,''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) num2str(x(1)) '-' num2str(x(2)) 'prevPeakamp'');']);
                            eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,prevPeakTroughlat,''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) num2str(x(1)) '-' num2str(x(2)) 'prevPeaklat'');']);
                    end
                
                    %PEAK LATENCY ERPlab
                    ALLERP = pop_geterpvalues( tempERP, [ x(1) x(2)], [1],  1:size(tempERP.bindata,1) , 'Baseline', 'none', 'Binlabel', 'on', 'FileFormat', 'wide', 'Fracreplace', 'NaN',...
                    'InterpFactor',  1, 'Measure', 'peaklatbl', 'Neighborhood',  3, 'PeakOnset',  1, 'Peakpolarity', lower(answer{2}), 'Peakreplace', 'absolute',...
                    'Resolution',  3, 'SendtoWorkspace', 'on' );
                    eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,ERP_MEASURES'',''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) num2str(x(1)) '-' num2str(x(2)) 'peakLat'');']);
                    
                    % 50%Frac Area Latency
                    ALLERP = pop_geterpvalues( tempERP, [x(1) x(2)], [1],  1:size(tempERP.bindata,1) , 'Afraction',  0.5, 'Baseline', 'none', 'Binlabel', 'on', 'FileFormat', 'wide',...
                        'Fracreplace', 'errormsg', 'InterpFactor',  1, 'Measure', 'fareatlat', 'PeakOnset',  1, 'Resolution',  3, 'SendtoWorkspace', 'on' );
                    eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,ERP_MEASURES'',''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) num2str(x(1)) '-' num2str(x(2)) '50pctAreaLat'');']);
                end
            else
                close
            end
        end
    end
end

writeOUT = questdlg('Do you want to save results to a file?', ...
	'Save output?');
if strncmp(writeOUT,'Yes',3)
    fname=inputdlg('Please enter a name for the output file');
    writetable(SPCAout.SPSS,[fname{1} '.csv']);
end


    