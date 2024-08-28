% Usage:
%   >> eegplugin_cpltoolbox(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
%
% Notes:
% This plugin is a total hack of code from the ERPlab toolbox, created by
% Javier Lopez-Calderon and Steven Luck (many many thanks!)
%
%
% Author: Paul Kieffaber
% The College of William & Mary
% Williamsburg, VA
% 2011
%
% Cognitive Psychophysiology Lab (CPL) Toolbox
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function currvers = eegplugin_cpltoolbox(fig, trystrs, catchstrs)

cpltoolboxver = '0.0.0.01'; 
currvers  = ['CPLtoolbox_' cpltoolboxver];

if nargin < 3
        error('eegplugin_erplab requires 3 arguments');
end

%
% add folder (and subfolders) to path
%
p = which('eegplugin_cpltoolbox', '-all');

if length(p)>1
        fprintf('\nERPLAB WARNING: More than one CPLtoolbox folder was found.\n\n');
end
p = p{1};
p = p(1:strfind(p,'eegplugin_cpltoolbox.m')-1);
addpath(genpath(p));

%---------------------------------------------------------------------------------------------------
%                               DBPA Import Menu
menuimport = findobj(fig, 'tag', 'import data');
    
%---------------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------------
%                               ERPLAB NEST-MENU
% **** ERPLAB at the EEGLAB Main Menu ****
if ~ispc
        posmainfig = get(gcf, 'Position');
        hframe     = findobj('parent', gcf, 'tag', 'Frame1');
        posframe   = get(hframe, 'position');
        set(gcf, 'position', [posmainfig(1:2) posmainfig(3)*1.3 posmainfig(4)]);
        set(hframe, 'position', [posframe(1:2) posframe(3)*1.31 posframe(4)]);
end

menuCPLtoolbox = findobj(fig, 'tag', 'EEGLAB');   % At EEGLAB Main Menu
%---------------------------------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        MENU      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      CALLBACKS   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Data import callbacks
comimport = [ trystrs.no_check '[FileParams,EEG,LASTCOM] = pop_loadDBPA;'  catchstrs.new_non_empty ];



% Basic menu callbacks
%
comhanFFT = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_powerspectrum(EEG);' catchstrs.new_and_hist ];
comCLF2   = [trystrs.no_check '[EEG LASTCOM] = pop_editeventlist(EEG);' catchstrs.new_and_hist ];
comSMMRZ  = [trystrs.no_check '[LASTCOM]     = pop_squeezevents(EEG);' catchstrs.add_to_hist ];
comSLFeeg = [trystrs.no_check '[EEG LASTCOM] = pop_exporteegeventlist(EEG);' catchstrs.add_to_hist ];
comRLFeeg = [trystrs.no_check '[EEG LASTCOM] = pop_importeegeventlist(EEG);' catchstrs.new_and_hist];
comCBL    = [trystrs.no_check '[EEG LASTCOM] = pop_binlister(EEG);' catchstrs.store_and_hist]; % ERPLAB 1.1.920 and higher
comMEL    = [trystrs.no_check '[EEG LASTCOM] = pop_overwritevent(EEG);' catchstrs.new_and_hist];
comEB     = [trystrs.no_check '[EEG LASTCOM] = pop_epochbin(EEG);' catchstrs.new_and_hist];
%
% Channel Operation callback
%
comCHOP   = [trystrs.no_check '[EEG LASTCOM] = pop_eegchanoperator(EEG);' catchstrs.store_and_hist ]; % ERPLAB 1.1.718 and higher
%
% Artifact rejection/correction callbacks
%
AutoBlink_clbk       = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_autoblink(EEG);' catchstrs.new_and_hist]; %Auto Blink Finder
RevAutoBlink_clbk    = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_reviewautoblink(EEG);' catchstrs.new_and_hist]; %Auto Blink Review
QC_clbk              = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_qc(EEG);' catchstrs.new_and_hist];
ICASubset_clbk       = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_subsetica(EEG);' catchstrs.new_and_hist];%run ICA on artifact-laiden subset of data
OAR_clbk             = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_findblinks(EEG);' catchstrs.new_and_hist];%find blinks automatically
qcreview_clbk        = [trystrs.no_check '[LASTCOM] = pop_cpl_qcreview(EEG);' catchstrs.add_to_hist];%find blinks automatically
interp_clbk          = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_interpolate(EEG);' catchstrs.new_and_hist];%find blinks automatically

%Event Management
appendevent_clbk     = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_appendeventdata(EEG);' catchstrs.new_and_hist];%find blinks automatically
recodeevent_clbk     = [trystrs.no_check '[EEG LASTCOM] = pop_cpl_recodeevents(EEG);' catchstrs.new_and_hist]; %recode events

comAR0     = [trystrs.no_check '[EEG LASTCOM] = pop_artextval(EEG);' catchstrs.new_and_hist]; % Extreme Values
comAR1     = [trystrs.no_check '[EEG LASTCOM] = pop_artmwppth(EEG);' catchstrs.new_and_hist]; % Peak to peak window voltage threshold
comAR3     = [trystrs.no_check '[EEG LASTCOM] = pop_artblink(EEG);' catchstrs.new_and_hist];  % Blink
comAR4     = [trystrs.no_check '[EEG LASTCOM] = pop_artstep(EEG);' catchstrs.new_and_hist];   % Step-like artifacts
comAR6     = [trystrs.no_check '[EEG LASTCOM] = pop_artdiff(EEG);' catchstrs.new_and_hist];   % sample-to-sample diff
comAR7     = [trystrs.no_check '[EEG LASTCOM] = pop_artderiv(EEG);' catchstrs.new_and_hist];  % Rate of change
comAR8     = [trystrs.no_check '[EEG LASTCOM] = pop_artflatline(EEG);' catchstrs.new_and_hist];  % Blocking & flat line
comARSUMM  = [trystrs.no_check '[goodbad histeEF histoflags  LASTCOM] = pop_summary_rejectfields(EEG);' catchstrs.add_to_hist];
comARSUMM2 = [trystrs.no_check '[acce rej histoflags  LASTCOM] = pop_summary_AR_eeg_detection(EEG);' catchstrs.add_to_hist];
comRSTAR   = [trystrs.no_check '[EEG LASTCOM] = pop_resetrej(EEG);' catchstrs.new_and_hist];  % Rate of change
%
% Utilities  callbacks
%
%comEMGH    = [trystrs.no_check '[EEG LASTCOM] = pop_emghunter(EEG);' catchstrs.new_and_hist]; % EMG hunter
Event2EV2_clbk   = [trystrs.no_check '[EV2] = Event2EV2(EEG.event);' catchstrs.add_to_hist];
comICOF    = [trystrs.no_check '[EEG LASTCOM] = pop_insertcodeonthefly(EEG);' catchstrs.new_and_hist];
comICLA    = [trystrs.no_check '[EEG LASTCOM] = pop_insertcodearound(EEG);' catchstrs.new_and_hist];
comICTTL   = [trystrs.no_check '[EEG LASTCOM] = pop_insertcodeatTTL(EEG);' catchstrs.new_and_hist];
comEXRTeeg = [trystrs.no_check '[values LASTCOM] = pop_rt2text(EEG);' catchstrs.add_to_hist];
comEXRTerp = ['[values ERPCOM] = pop_rt2text(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comEEGBDR  = [trystrs.no_check '[LASTCOM]     = pop_bdfrecovery(EEG);' catchstrs.add_to_hist];
comBCOL    = 'Bcolorerplab' ;
comFCOL    = 'Fcolorerplab' ;
%
% Filter EEG callbacks
%
comBFCD    = [trystrs.no_check '[EEG LASTCOM] = pop_basicfilter(EEG);' catchstrs.new_and_hist];
comPAS     = [trystrs.no_check '[LASTCOM] = pop_fourieeg(EEG);' catchstrs.add_to_hist];
%
% ERP processing callbacks
%
comERPBDR  = ['[ERPCOM]     = pop_bdfrecovery(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comSLFerp  = ['[ERPCOM]     = pop_exporterpeventlist(ERP);'  '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comRLFerp  = ['[ERP ERPCOM] = pop_importerpeventlist(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comAPP     = ['[ERP ERPCOM] = pop_appenderp(ALLERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comRERPBL  = ['[ERP ERPCOM]= pop_blcerp(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comCERPch  = ['[ERP ERPCOM] = pop_clearerpchanloc(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comAVG     = ['[ERP ERPCOM] = pop_averager(ALLEEG);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comBOP     = ['[ERP ERPCOM] = pop_binoperator(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comCHOP2   = ['[ERP ERPCOM] = pop_erpchanoperator(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comPLOT    = ['[ERPCOM]     = pop_ploterps(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comSCALP   = ['[ERPCOM]     = pop_scalplot(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
%
% Filter ERP callbacks
%
comFil    = ['[ERP ERPCOM] = pop_filterp(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comPASerp = ['LASTCOM = pop_fourierp(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
%
% ERP AR summary callback
%
comARSUMerp1 = ['[tacce trej histoflags  ERPCOM] = pop_summary_AR_erp_detection(ERP);' '[ERP ALLERPCOM] = erphistory(ERP, ALLERPCOM, ERPCOM);'];
comARSinc1   = [trystrs.no_check '[EEG LASTCOM] = pop_sincroartifacts(EEG);' catchstrs.new_and_hist];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        MAIN      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        MENU      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create Data import submenu
uimenu( menuimport, 'label', 'From Sensorium DBPA .dat File',  'callback', comimport,'separator','on');

% Create Main ERPLAB menu
submenu = uimenu( menuCPLtoolbox, 'Label', 'CPL', 'separator','on','tag','CPL');
set(submenu, 'position', 5); 

% Event Management
ELmenu = uimenu( submenu, 'Label', '<html><b>Event Management<b>'  , 'tag','EVTmanage'); %'CallBack', comCLF, 'separator', 'on');
uimenu( ELmenu, 'Label',  '[1] Import Behavioral Data' , 'CallBack', appendevent_clbk);
uimenu( ELmenu, 'Label',  '[2] Recode Events', 'CallBack', recodeevent_clbk);
%
% Data Pre-processing
ELmenu = uimenu( submenu, 'Label', '<html><b>Continuous Data Pre-processing<b>'  , 'tag','PreProcessMenus'); %'CallBack', comCLF, 'separator', 'on');
uimenu( ELmenu, 'Label',  '[1] Identify Bad Segments and/or Channels' , 'CallBack', QC_clbk);
uimenu( ELmenu, 'Label',  '[2] Review/Reject Bad Data','CallBack', qcreview_clbk);
uimenu( ELmenu, 'Label',  '[3] Replace Bad Channels' , 'CallBack', interp_clbk);
uimenu( ELmenu, 'Label',  '[4] Identify Ocular Artifact' , 'CallBack', OAR_clbk,'separator','on');
uimenu( ELmenu, 'Label',  '[5] Run ICA With Ocular Artifact Data Segments' , 'CallBack', ICASubset_clbk);
uimenu( ELmenu, 'Label',  '[6] Select Ocular Artifact Components Automatically' , 'CallBack', AutoBlink_clbk);
uimenu( ELmenu, 'Label',  '[7] Review Ocular Artifact Component Selection','CallBack', RevAutoBlink_clbk);

%mRTs = uimenu( ELmenu, 'Label',  'Export Reaction Times to Text'  , 'tag', 'ReactionTime','ForegroundColor', [0.6 0 0]); % Reaction Times

%
% EVENTLIST for ERP submenu
%
%uimenu( ELmenu, 'Label',  '<html>Import <b>ERP</b> EventList from text file'  , 'CallBack', comRLFerp, 'separator', 'on');
%uimenu( ELmenu, 'Label',  '<html>Export <b>ERP</b> EventList to text file'  , 'CallBack', comSLFerp);
%uimenu( submenu, 'Label', 'Assign Bins (BINLISTER)'     , 'CallBack', comCBL);
%uimenu( submenu, 'Label', 'Transfer eventinfo to EEG.event (optional)', 'CallBack', comMEL, 'separator', 'on');
%uimenu( submenu, 'Label', 'Extract Bin-based Epochs', 'CallBack', comEB, 'separator', 'on');

%
% Channel Operations and Artifact Rejection
%
uimenu( submenu, 'Label', '<html><b>EEG</b> Channel Operations'   , 'CallBack', comCHOP, 'separator','on' );

%
% Filter ERP submenus
%
mFI = uimenu( submenu,    'Label', 'Filter & Frequency Tools' , 'separator', 'on');
uimenu( mFI,'Label', '<html>Convert to Amplitude Spectrum'  , 'CallBack', comhanFFT);%, 'separator', 'on');
%uimenu( mFI,'Label', '<html>Plot Amplitude Spectrum for <b>EEG</b> data'  , 'CallBack', comPAS);
%uimenu( mFI, 'Label', '<html>Filters for <b>ERP</b> data', 'CallBack', comFil, 'separator','on' );
%uimenu( mFI,'Label', '<html>Plot Amplitude Spectrum for <b>ERP</b> data'  , 'CallBack', comPASerp);

%
% Artifact rejection submenus
%
%mAR = uimenu( submenu,    'Label', 'Artifact Detection'  , 'tag','ART','separator','on');
%uimenu( mAR, 'Label', '<html><b>EEG</b> Artifact Detection Summary Table'  , 'CallBack', comARSUMM2, 'ForegroundColor', [0 0 0.6], 'separator','on');

%
% ERP structure managment
%
%uimenu( submenu, 'Label', '<html>Compute Averaged <b>ERP</b>'   , 'CallBack', comAVG, 'separator', 'on');

%
% Create Utilities submenu (Temporay)
%
mUTI = uimenu( submenu, 'Label', 'Utilities'  , 'tag','Utilities', 'separator', 'on');
ELmenu = uimenu( submenu, 'Label', '<html><b>Utilities<b>'  , 'tag','Utilities','separator','on');
uimenu( ELmenu, 'Label',  'Export Neuroscan EV2 File' , 'CallBack', Event2EV2_clbk);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        SUPPORT   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         MENU     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%uimenu( submenu, 'Label', 'About ERPLAB', 'CallBack', 'abouterplabGUI', 'separator', 'on');


