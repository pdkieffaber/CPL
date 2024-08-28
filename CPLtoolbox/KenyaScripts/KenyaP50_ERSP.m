
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
SFPCAout=struct();

%Select files for Averaging
warning('Please select file(s)')
[filelist, pathname, filterindex] = uigetfile('*.set','Pick the files to include','MultiSelect', 'on');
if ~iscell(filelist)
    filelist={filelist};
end

%select save directory
%save_dir = uigetdir('','Where do you want to save the ERPs?');

%select the BINLIST file
[binfile,binpath]=uigetfile('*.txt','Select the BINLIST file');

%select epoch window
start=inputdlg('Enter start time for trial segmentation');
start=str2double(start);
stop=inputdlg('Enter stop time for trial segmentation');
stop=str2double(stop);


for sub=1:length(filelist)
    thisfile=filelist{sub};
    
    %Load File
    EEG = pop_loadset('filename',thisfile,'filepath',pathname);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

    %Modify original event codes for compatibility with ERPlab
    temp=EEG.event;
    for i=1:length(EEG.event)
        switch EEG.event(i).type
            case 'S  1' %Recode S1 Events
                temp(i).type=10;
                temp(i).code=10;
            case 'S  2' %Recode these guys
                temp(i).type=100;
                temp(i).code=100;
            case 'R  8' %Recode these guys
                temp(i).type=200;
                temp(i).code=200;
            otherwise
                temp(i).type=999;%needed to clear out some BrainVision events
                temp(i).code=999;
        end
    end
    EEG.event=temp;
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    %ADD S2 Events
    S1eventlats=[];
    for i=1:length(EEG.event)
        switch EEG.event(i).type
            case 10
                S1eventlats=cat(1,S1eventlats,EEG.event(i).latency);
        end
    end
    for i=1:length(S1eventlats)
        %ADD S2 events
        EEG = pop_editeventvals(EEG,'insert',{1,[],[],[],[]},'changefield',{1,'latency',(S1eventlats(i)/EEG.srate)+0.5},'changefield',{1,'duration',0},'changefield',{1,'type',20},'changefield',{1,'code',20});
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = eeg_checkset( EEG );
    end

    
    %re-reference to common average
    %EEG = pop_reref( EEG, [],'exclude',[1 2 35 36:37] );
    %[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off');
    %EEG = eeg_checkset( EEG );

    %Bandpass filter
    %EEG  = pop_basicfilter( EEG,  1:34 , 'Boundary', 'boundary', 'Cutoff', [ 5 50], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  4 ); % GUI: 21-Nov-2022 19:08:55
    %[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %Create eventlist
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } ); % GUI: 21-Nov-2022 19:10:44
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

    %Epoch bins
    EEG  = pop_binlister( EEG , 'BDF', fullfile(binpath,binfile), 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' ); % GUI: 21-Nov-2022 19:11:12
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = pop_epochbin( EEG , [start-500  stop+500],  'pre'); % GUI: 21-Nov-2022 19:12:05
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

    %Flag artifacts in EEG channels
    EEG  = pop_artextval( EEG , 'Channel',  3:34, 'Flag',  1, 'LowPass',  -1, 'Threshold', [ -100 100], 'Twindow', [ -100 500] ); % GUI: 21-Nov-2022 19:13:50
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
     
    %Detect bad trials with more than 15% (N=5) bad channels
    BadTrials=find(sum(EEG.reject.rejmanualE)>5);
    
    %Detect good trials with bad electrodes
    NaughtyTrials=find(sum(EEG.reject.rejmanualE)<=5 & sum(EEG.reject.rejmanualE)>0);
    
    %Interpolate electrodes in good trials with <15% bad channels
    for NT=1:length(NaughtyTrials)
        junk=EEG;
        junk.data=junk.data(:,:,NaughtyTrials(NT)); junk.trials=1;
        chans2interp=find(EEG.reject.rejmanualE(:,NaughtyTrials(NT)));
        junk=eeg_interp(junk,chans2interp,'spherical');
        EEG.data(:,:,NaughtyTrials(NT))=junk.data(:,:,1);
        EEG.reject.rejmanual(NaughtyTrials(NT))=0;
    end
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    eeglab redraw
    
    %Move our new "bad trials" back to ERPlab's EVENTLIST
    EEG = pop_syncroartifacts(EEG, 'Direction','eeglab2erplab');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %Select Bins for SFPCA
    list = {EEG.EVENTLIST.bdf.description};
    [binindx,tf] = listdlg('ListString',list);
    
    %Select Channels to include
    list = {EEG.chanlocs.labels};
    [chanindx,tf] = listdlg('ListString',list,'PromptString',{'Select all', ...
                                'channels you want', 'to include in the SFPCA'});
    
    %Select SFPCA parameters
    ERSPbase=[-800 0];
    
    %Loop over bins > channels
    for bin=1:length(binindx)
        tempEEG = pop_selectevent( EEG, 'latency','0<=0', 'bini',binindx(bin),'deleteevents','off','deleteepochs','on','invertepochs','off');
        %[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
        tempEEG = eeg_checkset( tempEEG );
        for channel = 1:length(chanindx)
            %figure; pop_newtimef( EEG, 1, 1, [-100  499], [3         0.8] , 'baseline',[0], 'plotphase', 'off', 'padratio', 1, 'winsize', 100);
            [SFPCAout.ersp(:,:,bin,channel,sub), SFPCAout.itc(:,:,bin,channel,sub), powbase, SFPCAout.times, SFPCAout.freqs] = pop_newtimef( tempEEG, 1, chanindx(channel), [start-500  stop+500], [3 0.8] , 'baseline', [ERSPbase(1) ERSPbase(2)],'freqscale','log', 'plotphase', 'off', 'padratio', 2,'plotersp','off','maxfreq',75); % 'winsize', 128);
            close
        end
    end
        
    %Generate ERPs
    %ERP = pop_averager( EEG , 'Criterion', 'good', 'DQ_custom_wins', 0, 'DQ_flag', 1, 'DQ_preavg_txt', 0, 'ExcludeBoundary', 'on', 'SEM', 'on' );
    %Save ERPlab files
    %ERP = pop_savemyerp(ERP, 'erpname', 'thisismyerp', 'filename', [thisfile '.erp'], 'filepath', save_dir,'Warning', 'on');
    %STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    eeglab redraw
end