%function []=KenyaCleaning()
%START EEGlab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%Select files for cleaning
warning('Please select the files to include in your protocol')
[filelist, pathname, filterindex] = uigetfile('*.vhdr','Pick the files to include','MultiSelect', 'on');
if ~iscell(filelist)
    filelist={filelist};
end
for sub=1:length(filelist)
    thisfile=filelist{sub};

    EEG = pop_loadbv(pathname, thisfile);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',thisfile,'gui','off');
    EEG = eeg_checkset( EEG );
    addpath(fullfile(what('dipfit').path, 'standard_BESA'))
    chanlocfile = which('standard_BESA.mat');
    EEG=pop_chanedit(EEG, 'lookup','standard_1005.elc'); %'C:\\Users\\Paul\\Documents\\MATLAB\\eeglab2022.1\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    %USE NOTCH FILTER FOR HEOG and VEOG
    EEG = pop_eegfiltnew(EEG, 'locutoff',49,'hicutoff',51,'revfilt',1,'channels',{'HEOG','VEOG'});
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
    EEG = eeg_checkset( EEG );
    
    %Label electrode types
    for i=1:34
        EEG.chanlocs(i).type='EEG';
    end
    for i=35:37
        EEG.chanlocs(i).type='EMG';
    end
    EEG = eeg_checkset( EEG );
    
    EEG = pop_resample( EEG, 125);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off'); 
    EEG = eeg_checkset( EEG );

    %Apply band-pass
    EEG  = pop_basicfilter( EEG,  1:34 , 'Boundary', 'boundary', 'Cutoff',  1.5, 'Design', 'butter', 'Filter', 'highpass', 'Order',  4 );  % GUI: 18-Nov-2022 09:46:56
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off');
    EEG = eeg_checkset( EEG );
    
    EEG = pop_select( EEG, 'channel',{'HEOG','VEOG','Fpz','AF3','AF4','AFz','Fz','F3','F7','F4','F8','FCz','FC1','FC5','FT9','FC2','FC6','Cz','C3','C4','CPz','CP1','CP5','CP2','CP6','Pz','P3','P7','P4','P8','POz','Oz','O1','O2'});
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off');
    EEG = eeg_checkset( EEG );

    pop_eegplot( EEG, 1, 1, 1);
    waitfor( findobj('parent', gcf, 'string', 'REJECT'), 'userdata');
    %[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'overwrite','on','gui','off');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );

    %pause(1)
    %fig = get(groot,'CurrentFigure');
    %uiwait(fig);
    
    %get figure handle
    %answer = questdlg('are you ready to continue?');

    
    %EEG = eeg_checkset( EEG );
    %eeglab redraw
    %pause
    %Ask about bad channels  
    list = {EEG.chanlocs.labels};
    [indx,tf] = listdlg('ListString',list,'PromptString',{'Select all the', ...
                                'channels you want', 'to use for ICA'});
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on','chanind',indx);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    %MOVE ICA decomposition to original data
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0); 
    EEG = eeg_checkset( EEG );
    EEG = pop_editset(EEG, 'run', [], 'icaweights', 'ALLEEG(2).icaweights', 'icasphere', 'ALLEEG(2).icasphere', 'icachansind', 'ALLEEG(2).icachansind');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    eeglab redraw
    ALLEEG = pop_delset( ALLEEG, [2] ); %08/28/24 changed EEG to ALLEEG
    eeglab redraw
    
    EEG = pop_iclabel(EEG, 'default');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    EEG = pop_icflag(EEG, [NaN NaN;0.7 1;0.7 1;NaN NaN;0.7 1;NaN NaN;NaN NaN]);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    %Inspect/Reject ICA components
    pop_eegplot( EEG, 0, 1, 1);
    pop_selectcomps(EEG,[1:size(EEG.icaweights,1)]); %08/28/24 changed from icaact to icaweights
    waitfor( findobj('parent', gcf, 'string', 'OK'), 'userdata');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = pop_subcomp( EEG, [], 0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %Select Channels for Interpolation
    list = {EEG.chanlocs.labels};
    [indx,tf] = listdlg('ListString',list,'PromptString',{'Select any', ...
                                'channels you want', 'to interpolate'});
    EEG = pop_interp(EEG, [indx], 'spherical');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %SAVE CLEAN DATA
    [newname,newpath]=uiputfile('.set','Save your Clean data');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'savenew',fullfile(newpath,newname),'gui','off'); 
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    eeglab redraw
end