function [EEG, report, suffix] = atclv2_ANACRA_SPM_preproc_MB_update(EEG, param, ~)
tic
spm('defaults', 'eeg');

report = {};

%% INITIALIZE 
S = [];
S.dataset = [EEG.filepath filesep EEG.filename];

[~, subjectFolder] = fileparts(EEG.filepath);
trlCountTemp = split(EEG.filename, '_');
trlCount = trlCountTemp{end}(end-4);
name = EEG.filename(1:end-4);

savePath = strcat([param.runPath, param.outFolder, filesep, subjectFolder, filesep]);
mkdir(savePath);

%% CONVERT FILE

S.outfile = [savePath, name];
S.channels = 'all';

if param.isSpectral && param.isTF
    S.mode = 'continuous';
elseif param.isSpectral && ~param.isTF
    S.mode = 'epoched';
end
S.blocksize = 3276800;
S.checkboundary = 1;
S.usetrials = 1;
S.datatype = 'float32-le';
S.eventpadding = 0;
S.saveorigheader = 0;

% begTimePoint = (round(EEG.event(end).latency) * -4)+4; %To get time in milliseconds
% endTimePoint = (EEG.xmax - (round(EEG.event(end).latency) / 250)) * 1000;
% 
% %S.timewin = [begTimePoint endTimePoint];%[EEG.xmin EEG.xmax]*1000;%
% S.timewin = [EEG.xmin EEG.xmax]*1000-(EEG.xmax*1000-500);%[EEG.xmin EEG.xmax]*1000;%


fnTemp = split(name , '_');
solType = fnTemp{end-1};

switch solType
    case 'INS'   
        S.conditionlabels = 'Insight';
        S.trialdef(1).conditionlabel = 'Insight';
        S.trialdef(1).eventtype = 'trigger';
        S.trialdef(1).eventvalue = 'SOL-COR-INS';
        
    case 'ANA'
        S.conditionlabels = 'Analytic';
        S.trialdef(1).conditionlabel = 'Analytic';
        S.trialdef(1).eventtype = 'trigger';
        S.trialdef(1).eventvalue = 'SOL-COR-ANA';
        
    case 'TO'
        S.conditionlabels = 'timeout';
        S.trialdef(1).conditionlabel = 'timeout';
        S.trialdef(1).eventtype = 'trigger';
        S.trialdef(1).eventvalue = 'timeout';
        
end

S.channels = param.channelsToUse;

S.inputformat = [];
S.continuous = true;
S.type = 'continuous';
D = spm_eeg_convert(S);

%% SET CHANNEL TYPE TO 'EEG'

S = [];
S.D = [savePath,name];
S.task = 'settype';
S.type = 'EEG';
S.ind = 1:length(param.channelsToUse);
S.save = 1;
D = spm_eeg_prep(S);
 
%% CHANNEL LOCATIONS
S = [];
S.D = [savePath,name];
S.task = 'defaulteegsens';
S.save = 1;
D = spm_eeg_prep(S);

%% Processing depending on mode and spectral options

% There are 3 options for param.mode and param.isSpectral combination:
% -------------------------------------------------------------------------------------------
%|   |  Mode   | isSpectral | isTF | outFolder  |           Description                      |
%|---+---------+------------+------+------------+--------------------------------------------|
%| 1 | evoked  |     0      |   0  |    ERP     | This will be ERP analysis                  |
%| 2 | evoked  |     1      |   1  | TF_evoked  | TF analysis for phase-locked condition     |
%| 3 | induced |     1      |   1  | TF_induced | TF analysis for non-phase-locked condition |
%| 4 | induced |     1      |   0  |    FFT     | Fast-Fourier Transform analysis            |
% -------------------------------------------------------------------------------------------

% Option for induced and nonspectral doesn't make sense.

prefixStack = [];


if strcmp(param.mode, 'evoked') || param.isSpectral == 0
        
    %% Average to calculate ERP
    tic
    
    S = [];
    S.D = [savePath, name,'.mat'];
    S.circularise = false;
    S.robust = 1;
    S.prefix = 'm_';
    D = spm_eeg_average(S);
    
    prefixStack = ['m_' prefixStack];
    
    toc
    
end
    
if param.isSpectral == 1
    if param.isTF == 1
        %% Morlet Transform
        
        tic
        
        S = [];
        S.D = [savePath, prefixStack name,'.mat'];
        S.channels = {'all'};
        S.frequencies = param.freqrange;
        S.timewin = param.timeWin;
        S.phase = 0;
        S.method = 'morlet';
        S.settings.ncycles = param.tfcycles;
        S.settings.timeres = 0;
        S.settings.subsample = 1;
        S.prefix = 'mor';
        D = spm_eeg_tf(S);
        
        prefixStack = ['mortf_' prefixStack];
        
        toc
    else
        
        %% FFT w/HANNING
                
        S = [];
        S.D = [savePath prefixStack name,'.mat'];
        S.channels = {'all'};
        S.frequencies = param.freqrange;
        S.timewin = [-Inf Inf];
        S.phase = 0;
        S.method = 'mtmfft';
        S.settings.taper = 'hanning';
        S.prefix = 'fft';
        D = spm_eeg_tf(S);
        
        prefixStack = ['ffttf_' prefixStack];
    end
    
    %% TF RESCALE
    
    tic
    
    S = [];
    S.D = [savePath, prefixStack, name,'.mat'];
    S.method = param.tfrescale;
    S.prefix = [S.method '_'];
    S.timewin = [-Inf Inf]; %inf 0?
    D = spm_eeg_tf_rescale(S);
    
    prefixStack = [S.prefix prefixStack];
    
    toc
    
end


if strcmp(param.mode, 'induced')
    %% Averaging (robust)
    tic
    
    S = [];
    S.D = [savePath, prefixStack, name,'.mat'];
    S.circularise = false;
    S.robust.removebad = false;
    S.robust.savew = false;
    S.robust.bycondition = false;
    S.robust.ks = 3;
    S.prefix = 'm_';
    D = spm_eeg_average_TF(S);
    
    prefixStack = ['m_' prefixStack];     
    
    toc
end

%% CONTRAST
% % S = [];
% S.D = [savePath, prefixStack name,'.mat'];
% S.c = param.con;
% S.label = param.conlabel;
% S.weighted = 1;
% S.prefix = 'CON_';
% D = spm_eeg_contrast(S);




%% Closing statement to make autoclave work
suffix = {};
EEG = {};

end