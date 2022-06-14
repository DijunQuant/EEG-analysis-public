function [EEG, report, suffix] = atclv2_ANACRA_SpltTrial(EEG, param, ~)
% To split CRA recordings into diffrent trial files with different length



%% INITIALIZE VARIABLES
report = {};

%% Selecting the trial and saving it separately

try
    
subN = EEG.filename(1:3);

% Find number of trials
numTrialsI = count([EEG.event.type], 'SOL-COR-INS');
numTrialsA = count([EEG.event.type], 'SOL-COR-ANA');
numTrialsT = count([EEG.event.type], 'timeout');

numTrialsCRS = count([EEG.event.type], 'CRA')+count([EEG.event.type],'word','IgnoreCase',true);
%added task tag for anagrams, YY.
if isfield(param,'channelsToUse')
     EEG = pop_select(EEG,'channel',param.channelsToUse);
end

if isfield(param,'norm') && param.norm
    normdata = zscore(EEG.data,0,2);
    EEG.data = normdata;
end

if numTrialsCRS ~= numTrialsI + numTrialsA + numTrialsT
    a = 1;
    %for sub 206
    switch subN
        case '206'
            EEG.event(140) = [];
            numTrials = numTrials-1;
        case '222'
            EEG.event(14) = [];
            numTrials = numTrials-1;
        otherwise
        error('Something wrong with the trial numbers!')
    end
end


    
subN = EEG.filename(1:3);
savePath = [param.runPath, param.outFolder, param.pd, subN];
mkdir(savePath);

insCount = 0;
anaCount = 0;
toCount = 0;
lastTime = -1;
for i = 1:numTrialsCRS
    
    solType = EEG.event(i*2).type;
    if contains(solType, 'INS')
        insCount = insCount + 1;
        saveFilename = [EEG.filename(1:end-4), '_splt_INS_', num2str(insCount), '.set'];
    elseif contains(solType, 'ANA')
        anaCount = anaCount+1;
        saveFilename = [EEG.filename(1:end-4), '_splt_ANA_', num2str(anaCount), '.set'];
    elseif contains(solType, 'timeout')
        toCount = toCount+1;
        saveFilename = [EEG.filename(1:end-4), '_splt_TO_', num2str(toCount), '.set'];
    end
    
    minTime = EEG.event(1+(2*(i-1))).latency *4/1000 - param.begLat;
    minTime= max(minTime,lastTime);
    maxTime = EEG.event(i*2).latency*4/1000 + param.endLat; 
    EEG_split = pop_select(EEG, 'time', [minTime maxTime]);
    EEG_split.event(strcmp({EEG_split.event.type}, 'boundary')) = [];
  
    lastTime=maxTime;
     
    pop_saveset(EEG_split, 'filename', saveFilename, 'filepath', savePath);
    %fprintf('\n%s\n%s\n',['> File saved as: ', saveFilename],['in ', savePath])

    
end

catch whatthehec
    fprintf('\nError:\n%s\n',whatthehec.identifier);
    fprintf('%s\n\n',whatthehec.message);
    rethrow(whatthehec);
end

suffix = 'split';
