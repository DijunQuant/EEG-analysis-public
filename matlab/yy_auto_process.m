% =====================================
% ============ Super-Auto ============
% =====================================

% Author: Yongtaek Oh, Drexel Univerrsity
% Based on Brian Erickson's Autoclave

% Fully automatic pipeline based on Makoto Miyakoshi (UCSD)'s recommendation
% (https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline) on processing order
% and Neuroscience Gateway Portal (https://www.nsgportal.org/) to run AMICA
% and reject artifactual ICs using MARA (Multiple Artifact Rejection Algorithm)

% Developed under Matlab R2021a and EEGLAB 2019_0_2



%% README!!!!

% 1. Your project folder is structured in the following hierarchy:
%    - Project Folder
%      * utilities (The name 'utilities' is hard-coded, so use the exact name)
%      * Step folder (e.g. cra_a_raw)
%          * Subject Folder (e.g. 101)
%            * File (e.g. 101craps.mbi, 101craps.mb2)

% 2. Move 'utilities' folder in your project folder

% 3. Set your project folder as working directory

% 4. You should have EEGLAB and SPM12 downloaded and added in your path
%    - Download EEGLAB: https://sccn.ucsd.edu/eeglab/download.php
%    - Download SPM: https://www.fil.ion.ucl.ac.uk/spm/software/download/

% 5. Run EEGLAB by typing 'eeglab' in the command window, and click File -> Manage EEGLAB extensions

% 6. Add the following EEGLAB extensions:
%    - Fileio - to be used when importing .EEG and .mb2 extension (BrainProducts and MANSCAN)
%    - AMICA
%    - MARA
%    - Cleanline
%    - clean_rawdata()
%    - fullRankAveRef

% 7. Run SPM by typing 'spm eeg' to add necessary paths

% 8. Now it's good to go!!


%% global setup

includeSteps={'pre','asr','interp','rmEvt','epoch','ica','mara','stratify','gICA','wavelet','wavelet_chan','chunkICA'};
includeSteps={'pre','asr','interp','rmEvt','epoch','ica','mara','stratify','gICA','wavelet'};
includeSteps={'wavelet_chan'};
dataFolder = '/projects/p31274/Drexel/rawdata/';
sessionType='cra'; %or ana, 

export_prefix='/projects/p31274/Drexel/export/';
exportFolder=[export_prefix sessionType];

param.includeID={'102','103','104','106','107',...
    '110','111','112','114','115','117','118','120',...
    '123','124','126','203','206','208','209','210',...
    '211','212','215','216','217','218','219','220','221','222','223','224','225'};


param.useAbsoluteInput=false;
param.seeds = [1];
channel84={...
        'T7','C3', 'FT9', 'FT7', 'F7', 'F3', 'F9', 'AF3', 'FP1', 'FPZ', 'AFZ',...
        'FZ', 'FCZ', 'FP2', 'AF4', 'F4', 'F10', 'F8', 'FT8', 'FT10', 'CZ',...
        'C4', 'T8', 'TP9', 'TP7', 'P9', 'P7', 'P3', 'O1','IZ','OZ','POZ','PZ',...
        'CPZ','O2','P4','P8','P10','TP8','TP10','O9', 'PO9','PO7','PO3',...
        'PO355','P1','P5','CP5','CP3','CP1','CP155','C1','C5', 'FC5','FC3','FC1',...
        'C155','F1','F5','AF7','AF355','AF455','F155','F255','AF8','F2','C255',...
        'C2','CP255','CP2','P2','P6','PO455','PO4','PO8','O10','PO10','F6',...
        'FC6','FC4','FC2','C6','CP6','CP4'};
channel19={'Fp1','Fp2','F7','F3','Fz','F4','F8','T7','C3','Cz',...
                        'C4','T8','P7','P3','Pz','P4','P8','O1','O2'};

%% for slurm
%parpool('local', 28); %each node has at least 28 cores


%%
%% PRE-ICA PROCESSING
    
% // PATHS
if any(strcmp(includeSteps,'pre'))
    param.useAbsoluteInput=true;
    param.inFolder = [dataFolder sessionType '_a_raw/']; % Path ending in slash

    param.outFolder = [sessionType '_b_prep_basic']; % Path ending in slash

    param.fileType = '*/*.mb2'; % file extension to look for. For concatenated files use ".vhdr"

    param.resampleRate = 250; % Downsample to 250Hz
    param.sessionType = sessionType;

    param.locutoff = 1; % Hz Cutoff for high-pass filter
    % Reduce number of channels using channel names
    param.downsampleToList = channel84;

    param.channelFile = 'EEGLAB - Besa Derived 84ch w MANSCAN Labels.ced';

    % // CALL TO FUNCTION
    funct = {...
        @atclv2_ANACRA_relabel,...
        @atclv2_ANACRA_correctMANSCANEvent,...
        @atclv2_step_resample,...
        @atclv2_step_hipass,...
        @atclv2_step_dwnsmp,...
        @atclv2_step_loadChanLocs,...
        @atclv2_step_cleanline_new

        }; % cell of @functionHandles

    fullReport = atclv2_masterSelector(param,funct,...
        'auto',1,'save',1,'vol',1,'global',0);
    param.useAbsoluteInput=false;
end


%% CLEAN THE DATA USING ASR
    
if any(strcmp(includeSteps,'asr'))
    param.inFolder = [sessionType '_b_prep_basic']; % Path ending in slash
    %param.inFolder = 'anagram_b_prep_basic'; % Path ending in slash
    param.outFolder = [sessionType '_c_prep_asr']; % Path ending in slash
    %param.outFolder = 'anagram_c_prep_asr'; % Path ending in slash
    param.fileType = '*/*.set'; % file extension to look for.

    param.asrSD = 15;
    param.winCr = .80;
    param.chanC = .75;

    %param.includeID={'102'};

    % // CALL TO FUNCTION
    funct = {@atclv2_step_cleanRawData}; % cell of @functionHandles

    fullReport = atclv2_masterSelector(param,funct,...
        'auto',1,'save',1,'vol',1,'global',0);
end


%% INTERPOLATE REJECTED CHANNEL(S)

%CHECK THIS!!!!!

if any(strcmp(includeSteps,'interp'))
    param.inFolder = [sessionType '_c_prep_asr'];  % Path ending in slash
   
    param.outFolder = [sessionType '_d_interp']; % Path ending in slash
  
    param.fileType = '*/*.set'; % file extension to look for


    % The file should be located at YourProjectFolder/utilities/File.mat
    % Currently, the interpolation reference file is based on 84 channel montage.
    % Let me know if you need a version with reduced number of electrodes.
    param.chanLocInterpFile = 'MANSCANchanlocs4Interp.mat';

    % // CALL TO FUNCTION
    funct = {@atclv2_step_interp}; % cell of @functionHandles
    fullReport = atclv2_masterSelector(param,funct,...
        'auto',1,'save',1,'vol',1,'global',0);
end

%% filter out short trials
if any(strcmp(includeSteps,'rmEvt'))    
    % PATHS  
    param.inFolder =  [sessionType '_d_interp']; % Path ending in slash
 
    param.outFolder = [sessionType '_e_rmShortEvt']; % Path ending in slash
  
    param.fileType = '*/*.set'; % file extension to look for

    param.eventList = {'SOL-COR-INS', 'SOL-COR-ANA', 'SOL-INC-INS', 'SOL-INC-ANA'};
    if strcmp(sessionType,'cra')
        param.TW = 2000; % Threshold in miliseconds
    else
        param.TW = 2500; %Anagram onset contains 500ms cross
    end

    funct = { @atclv2_ANACRA_rmShrtEvents}; % cell of @functionHandles
    fullReport = atclv2_masterSelector(param,funct,...
        'auto',1,'save',1,'vol',1,'global',0); 
end
%% EPOCH 

if any(strcmp(includeSteps,'epoch'))    

    param.inFolder = [sessionType '_e_rmShortEvt']; % Path ending in slash
  
    param.outFolder = [sessionType '_f_epoch']; % Path ending in slash

    param.fileType = '*/*.set'; % file extension to look for


    if strcmp(sessionType,'cra')
        param.begLat = 1.5; % Pre-stimulus period, in seconds
        param.endLat = 0.5; % Post-response period, in seconds
    else
        param.begLat = 1.; % Pre-stimulus period, in seconds, Anagram onset contains 500 ms
        param.endLat = 0.5; % Post-response period, in seconds
    end


    param.epEvents = {'SOL-COR-INS', 'SOL-COR-ANA', 'timeout'};


    % // CALL TO FUNCTION
    funct = {@atclv2_ANACRA_epoch_MB}; % cell of @functionHandles
    fullReport = atclv2_masterSelector(param,funct,...
        'auto',1,'save',1,'vol',1,'global',0);
end
%% RUN AMICA

% // PATHS

if any(strcmp(includeSteps,'ica'))    
    param.inFolder = [sessionType '_f_epoch']; % Path ending in slash
    param.outFolder = [sessionType '_g_AMICA']; % Path ending in slash

    param.fileType = '*/*.set';

    param.numModels = 1;
    %param.max_iter = 10; %for testing only
    param.max_iter = 2000;

    funct = {@atclv2_step_AMICAonLocal}; % cell of @functionHandles

    fullReport = atclv2_masterSelector(param,funct,...
        'auto',1,'save',1,'vol',1,'global',1);

end


%% RUN ICA in Parallel - ALTERNATIVE OPTION!!!

% % // PATHS
% param.inFolder = 'cra_g_epoch'; % Path ending in slash
% param.outFolder = 'cra_h_ICA'; % Path ending in slash
% 
% param.fileType = '*/*.set';
% 
% funct = {
%     @atclv2_step_ICA_parallel;...
% 	}; % cell of @functionHandles
% 
% fullReport = atclv2_masterSelector(param,funct,...
% 	'auto',1,'save',1,'vol',1,'global',1);

%% AUTOMATICALLY REJECT ARTIFACTUAL IC USING MARA
if any(strcmp(includeSteps,'mara'))   
    param.inFolder = [sessionType '_g_AMICA']; % Path ending in slash
    param.outFolder = [sessionType '_h_MARA']; % Path ending in slash

    param.fileType = '*/*.set'; % file extension to look for
    % MARA input options
    % - 1x5 array specifing optional operations, default is [0,0,0,0,0]
    % - option(1) = 1 => filter the data before MARA classification
    % - option(2) = 1 => run ica before MARA classification
    % - option(3) = 1 => plot components to label them for rejection after MARA classification
    %                    (for rejection)  
    % - option(4) = 1 => plot MARA features for each IC 
    % - option(5) = 1 => automatically reject MARA's artifactual components without inspecting them

    funct = {
        @atclv2_step_MARAautoICreject_parallel;...
        }; % cell of @functionHandles

    fullReport = atclv2_masterSelector(param,funct,...
        'auto',1,'save',1,'vol',1,'global',1);
end

%% split trials and do wavelet on original channels
if any(strcmp(includeSteps,'wavelet_chan')) 
    param.inFolder = [sessionType '_h_MARA']; % Path ending in slash
    param.runPath = pwd;
    param.channelsToUse = channel84;

    param.norm=true;
    
    if strcmp(sessionType, 'cra')
        param.begLat = 1.5; % Pre-stimulus period, in seconds
        param.endLat = 0.5; % Post-response period, in seconds
    else
        param.begLat = 1; % Pre-stimulus period, in seconds, Anagram onset contains 500 ms
        param.endLat = 0.5; % Post-response period, in seconds
    end
    param.freqrange = {{3,[4.3, 4.8, 5.5, 6.5, 7.7]},...
                       {4,[8.3, 9.0, 9.7]}, ...
                       {5,[10.7,11.9,13.4]}, ...
                       {6,[14.6, 16.0, 17.5]},...
                       {8,[19.2, 21.5, 24.2]}, ...
                       {10,[26.0, 27.5, 29]}, ....
                       {12,[35.1, 39]},...
                       {18,[43.2, 47.9]}};

    param.exportPath = [export_prefix sessionType '_chan'];
    subList=param.includeID;
    for i=1:length(subList)
        subid = subList{i};
        datapath=[filesep subid filesep];
        setfile=rdir([[param.runPath filesep param.inFolder] datapath '*set']);
        [setpath, setfilename]=fileparts(setfile.name);
        EEG=pop_loadset('filename', [setfilename '.set'],'filepath', setpath);
        if isfield(param,'channelsToUse')
            EEG = pop_select(EEG,'channel',param.channelsToUse);
        end

        icaTransform = eye(length(param.channelsToUse));
        mkdir([param.exportPath filesep subid filesep]);
        dcd_splitSpectra(EEG,subid,icaTransform, param);

    end
end

%% split trials and do wavelet
if any(strcmp(includeSteps,'wavelet')) 
    param.inFolder = [sessionType '_h_MARA']; % Path ending in slash
    param.runPath = pwd;
    param.icaFolder=[param.runPath filesep sessionType '_y_all_pca'];
    param.channelsToUse = channel84;

    param.norm=true;
    
    if strcmp(sessionType, 'cra')
        param.begLat = 1.5; % Pre-stimulus period, in seconds
        param.endLat = 0.5; % Post-response period, in seconds
    else
        param.begLat = 1; % Pre-stimulus period, in seconds, Anagram onset contains 500 ms
        param.endLat = 0.5; % Post-response period, in seconds
    end
    param.freqrange = {{3,[4.3, 4.8, 5.5, 6.5, 7.7]},...
                       {4,[8.3, 9.0, 9.7]}, ...
                       {5,[10.7,11.9,13.4]}, ...
                       {6,[14.6, 16.0, 17.5]},...
                       {8,[19.2, 21.5, 24.2]}, ...
                       {10,[26.0, 27.5, 29]}, ....
                       {12,[35.1, 39]},...
                       {18,[43.2, 47.9]}};
    %param.freqs = [4.3, 4.8, 5.5, 6.5, 7.7,8.3, 9.0, 9.7,10.7,11.9,13.4,14.6, 16.0, 17.5,...
    %                19.2, 21.5, 24.2,26.0, 27.5, 29,35.1,39,43.2, 47.9];
    %param.cycles = [3,3,3,3,3,4,4,4,5,5,5,6,6,6,8,8,8,...
    %                    10,10,10,12,12,18,18];
    param.exportPath = exportFolder;
    subList=param.includeID;
    for i=1:length(subList)
        subid = subList{i};
        datapath=[filesep subid filesep];
        setfile=rdir([[param.runPath filesep param.inFolder] datapath '*set']);
        [setpath, setfilename]=fileparts(setfile.name);
        EEG=pop_loadset('filename', [setfilename '.set'],'filepath', setpath);
        if isfield(param,'channelsToUse')
            EEG = pop_select(EEG,'channel',param.channelsToUse);
        end
        EEG = pop_loadmodout(EEG,[param.icaFolder filesep]);

        icaTransform = EEG.icaweights * EEG.icasphere;
        mkdir([param.exportPath filesep subid filesep]);
        dcd_splitSpectra(EEG,subid,icaTransform, param);

    end
end

%% split trials and do wavelet
if any(strcmp(includeSteps,'wavelet_onPC')) 
    param.inFolder = [sessionType '_h_MARA']; % Path ending in slash
    param.runPath = pwd;
    param.retainPC = 20;
    param.channelsToUse = channel84;
   
    param.norm=true;
    
    if strcmp(sessionType, 'cra')
        param.begLat = 1.5; % Pre-stimulus period, in seconds
        param.endLat = 0.5; % Post-response period, in seconds
    else
        param.begLat = 1; % Pre-stimulus period, in seconds, Anagram onset contains 500 ms
        param.endLat = 0.5; % Post-response period, in seconds
    end
    param.freqrange = {{3,[4.3, 4.8, 5.5, 6.5, 7.7]},...
                       {4,[8.3, 9.0, 9.7]}, ...
                       {5,[10.7,11.9,13.4]}, ...
                       {6,[14.6, 16.0, 17.5]},...
                       {8,[19.2, 21.5, 24.2]}, ...
                       {10,[26.0, 27.5, 29]}, ....
                       {12,[35.1, 39]},...
                       {18,[43.2, 47.9]}};
    %param.freqs = [4.3, 4.8, 5.5, 6.5, 7.7,8.3, 9.0, 9.7,10.7,11.9,13.4,14.6, 16.0, 17.5,...
    %                19.2, 21.5, 24.2,26.0, 27.5, 29,35.1,39,43.2, 47.9];
    %param.cycles = [3,3,3,3,3,4,4,4,5,5,5,6,6,6,8,8,8,...
    %                    10,10,10,12,12,18,18];
    param.exportPath = [export_prefix sessionType '_byPC'];

    pcTransform = dcd_runPCA([pwd filesep sessionType '_z_split'],param);
    
    subList=param.includeID;
    for i=1:length(subList)
        subid = subList{i};
        datapath=[filesep subid filesep];
        setfile=rdir([[param.runPath filesep param.inFolder] datapath '*set']);
        [setpath, setfilename]=fileparts(setfile.name);
        EEG=pop_loadset('filename', [setfilename '.set'],'filepath', setpath);
        if isfield(param,'channelsToUse')
            EEG = pop_select(EEG,'channel',param.channelsToUse);
        end
       

        
        mkdir([param.exportPath filesep subid filesep]);
        dcd_splitSpectra(EEG,subid,pcTransform(1:param.retainPC,:), param);

    end
end

%% stratify
%only include the amount of TO trials no more than the sum of ins and ana
if any(strcmp(includeSteps,'stratify')) 
    startpath=pwd;
    inFolder=[sessionType '_h_MARA'];

    param.channelsToUse = channel84;

    if strcmp(sessionType, 'cra')
        param.begLat = 1; % Pre-stimulus period, in seconds, for ICA do not need extra buffer time
        param.endLat = 0; % Post-response period, in seconds
    else
        param.begLat = 0.5; % Pre-stimulus period, in seconds, Anagram onset contains 500 ms
        param.endLat = 0; % Post-response period, in seconds
    end

    %param.splitN=5;
    param.splitN=1;
    sprintf(['run stratify ', int2str(param.splitN), ' folds. \n\n']);

    for i=1:length(param.includeID)
        subid = param.includeID{i};
        datapath=[filesep subid filesep];
        param.savePath=[pwd filesep sessionType '_z_split' filesep subid];

        setfile=rdir([[startpath filesep inFolder] datapath '*set']);
        [setpath, setfilename]=fileparts(setfile.name);
        EEG=pop_loadset('filename', [setfilename '.set'],'filepath', setpath);
        dcd_stratefiedSplit(EEG, param);
    end

end
%% chunkICA
if any(strcmp(includeSteps,'chunkICA')) 
    startpath=pwd;

    param.channelsToUse = {'Fp1','Fp2','F7','F3','Fz','F4','F8','T7','C3','Cz',...
                        'C4','T8','P7','P3','Pz','P4','P8','O1','O2'};

    setpath=[startpath filesep sessionType '_z_split'];
    
    sublist=rdir(setpath,'isdir',1);
    for i = 1:length(sublist)
        tmp=split(sublist(i).name,filesep);
        sublist(i).name=tmp{2};
    end

    param.splitN=5;
    param.outFolder=[startpath filesep sessionType '_y_group'];
    param.inFolder=setpath;
    param.numModels = 1;
    param.max_iter = 2000;
    %param.max_iter = 500;
    sprintf(['run group ICA for ', int2str(length(param.includeID)), '\n\n']);
    dcd_subICA(sublist,param,param.seeds);

end

%% gICA
if any(strcmp(includeSteps,'gICA')) 
    startpath=pwd;
    setpath=[startpath filesep sessionType '_z_split'];
    
    sublist=rdir(setpath,'isdir',1);
    for i = 1:length(sublist)
        tmp=split(sublist(i).name,filesep);
        sublist(i).name=tmp{2};
    end
    
    param.pcakeep=20;
    param.splitN=1;
    param.outFolder=[startpath filesep sessionType '_y_all_pca'];
    param.inFolder=setpath;
    param.numModels = 1;
    param.max_iter = 2000;
    %param.max_iter = 10;
    sprintf(['run all group ICA for ', int2str(length(param.includeID)), '\n\n']);
    dcd_subICA(sublist,param,[]);

end


