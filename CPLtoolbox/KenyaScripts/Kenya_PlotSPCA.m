function [SPCAout]=Kenya_PlotSPCA(SPCAout,ERP)

%Plot Results
colors='kbrmc';
styles={'-','--',':'};
conditionvec=unique(SPCAout.Spatial.varStruct(:,3));
groupvec=unique(SPCAout.Spatial.varStruct(:,2));
for comp=1:SPCAout.Spatial.numFacs
    figure;
    subplot(2,2,[1 3])
    topoplot(SPCAout.Spatial.FacPat(:,comp),SPCAout.PCAchanlocs,'electrodes','on','emarker',{'o','k',10,1},'shading','interp','numcontour',0,'whitebk','on','gridscale',100);
    set(gcf,'color','white');
    subplot(2,2,2)
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
            figure;
            hold on;
            title(['Component #' num2str(comp)])
            for g=1:length(groupvec)
                for i=1:length(conditionvec)
                    plot(SPCAout.PCAtimes,squeeze(mean(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==conditionvec(i),:,comp),1)),[styles{g} colors(i)],'linewidth',5);
                end
                legend(SPCAout.ConditionLabels)
            end
            thisComp = questdlg('Do you want to measure from this component?', 'Use this component?');
            if strncmp(thisComp,'Yes',3)
                [x y]=ginput(2);
                close
                %NOW MEASURE PEAK/mean AMPS, LATS, and FRAC AREA LATS
                for c=1:length(conditionvec)
                    %MAKE FAKE ERPset in order to use ERPlab functions
                    tempERP=ERP;%ERP;
                    tempERP.times=SPCAout.PCAtimes;
                    tempERP.bindata=squeeze(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==c,:,comp));
                    tempERP.nchan=size(tempERP.bindata,1);
                    tempERP.nbin=1;
                    %MEAN AMPLITUDE
                    temp=squeeze(mean(SPCAout.Spatial.vERPs(SPCAout.Spatial.varStruct(:,3)==c,SPCAout.PCAtimes>=x(1)&SPCAout.PCAtimes<=x(2),comp),2));
                    eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,temp,''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) 'meanAmp'');'])
                    %eval(['C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) 'meanAmp=temp;']);
                    
                    %MEAN AMP ERPlab
                    ALLERP = pop_geterpvalues( tempERP, [x(1) x(2)], [1],  1:size(tempERP.bindata,1) , 'Baseline', 'none', 'Binlabel', 'on', 'FileFormat', 'wide', 'Fracreplace', 'NaN',...
                         'InterpFactor',  1, 'Measure', 'meanbl', 'PeakOnset',  1, 'Resolution',  3, 'SendtoWorkspace', 'on' );
                     eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,ERP_MEASURES'',''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) 'meanAmpERPlab'');']);
                     
                    %PEAK AMP ERPlab
                    ALLERP = pop_geterpvalues( tempERP, [x(1) x(2)], [1],  1:size(tempERP.bindata,1) , 'Baseline', 'none', 'Binlabel', 'on', 'FileFormat', 'wide', 'Fracreplace', 'NaN',...
                    'InterpFactor',  1, 'Measure', 'peakampbl', 'Neighborhood',  3, 'PeakOnset',  1, 'Peakpolarity', lower(answer{2}), 'Peakreplace', 'absolute',...
                    'Resolution',  3, 'SendtoWorkspace', 'on' );
                    eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,ERP_MEASURES'',''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) 'peakAmp'');']);
                    
                    %PEAK LATENCY ERPlab
                    ALLERP = pop_geterpvalues( tempERP, [ x(1) x(2)], [1],  1:size(tempERP.bindata,1) , 'Baseline', 'none', 'Binlabel', 'on', 'FileFormat', 'wide', 'Fracreplace', 'NaN',...
                    'InterpFactor',  1, 'Measure', 'peaklatbl', 'Neighborhood',  3, 'PeakOnset',  1, 'Peakpolarity', lower(answer{2}), 'Peakreplace', 'absolute',...
                    'Resolution',  3, 'SendtoWorkspace', 'on' );
                    eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,ERP_MEASURES'',''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) 'peakLat'');']);
                    
                    % 50%Frac Area Latency
                    ALLERP = pop_geterpvalues( tempERP, [x(1) x(2)], [1],  1:size(tempERP.bindata,1) , 'Afraction',  0.5, 'Baseline', 'none', 'Binlabel', 'on', 'FileFormat', 'wide',...
                        'Fracreplace', 'errormsg', 'InterpFactor',  1, 'Measure', 'fareatlat', 'PeakOnset',  1, 'Resolution',  3, 'SendtoWorkspace', 'on' );
                    eval(['SPCAout.SPSS = addvars(SPCAout.SPSS,ERP_MEASURES'',''NewVariableNames'',''C' num2str(comp) strtrim(SPCAout.ConditionLabels{c}) strtrim(answer{1}) '50pctAreaLat'');']);
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
    writetable(SPCAout.SPSS,'KenyaPCAresults.csv');
end
end