function pass = dcd_splitSpectraAllFreq(EEG,subN,icaTransform, param)


%% INITIALIZE VARIABLES
report = {};

%% Selecting the trial and saving it separately

try



% Find number of trials
numTrialsI = count([EEG.event.type], 'SOL-COR-INS');
numTrialsA = count([EEG.event.type], 'SOL-COR-ANA');
numTrialsT = count([EEG.event.type], 'timeout');

numTrialsCRS = count([EEG.event.type], 'CRA')+count([EEG.event.type],'word','IgnoreCase',true);
%added task tag for anagrams, YY.


if isfield(param,'norm') && param.norm
    normdata = zscore(EEG.data,0,2);
    EEG.data = normdata;
end

% if numTrialsCRS ~= numTrialsI + numTrialsA + numTrialsT
%     a = 1;
%     %for sub 206
%     switch subN
%         case '206'
%             EEG.event(140) = [];
%             numTrials = numTrials-1;
%         case '222'
%             EEG.event(14) = [];
%             numTrials = numTrials-1;
%         otherwise
%         error('Something wrong with the trial numbers!')
%     end
% end



anacorCount = 0;
anaincCount = 0;
inscorCount = 0;
insincCount = 0;
toCount = 0;
lastTime = -1;

trialinfo={};
for i = 1:numTrialsCRS
    
    solType = EEG.event(i*2).type;
    probType = EEG.event(i*2-1).type;
    if contains(solType, 'INS')
        if contains(solType,'-COR-')
            inscorCount = inscorCount + 1;
            suffix =['INSCOR_' num2str(inscorCount)];
            solType='INS_COR';
        else
            insincCount = insincCount + 1;
            suffix =['INSINC_' num2str(insincCount)];
            solType='INS_INC';
        end
    elseif contains(solType, 'ANA')
        if contains(solType, '-COR-')
            anacorCount = anacorCount+1;
            suffix =['ANACOR_' num2str(anacorCount)];
            solType='ANA_COR';
        else
            anaincCount = anaincCount+1;
            suffix =['ANAINC_' num2str(anaincCount)];
            solType='ANA_INC';
        end
    elseif contains(solType, 'timeout')
        toCount = toCount+1;
        if toCount>numTrialsI+numTrialsA
            continue
        end
        suffix = ['TO_' num2str(toCount)];
        solType='TO';
    end
    
    minTime = EEG.event(1+(2*(i-1))).latency *4/1000 - param.begLat;
    minTime= max(minTime,lastTime);
    maxTime = EEG.event(i*2).latency*4/1000 + param.endLat; 
    duration = (EEG.event(i*2).latency - EEG.event(1+(2*(i-1))).latency)*4/1000;
    tmp=split(suffix,'_');
    trialinfo = [trialinfo;{solType,tmp{2},duration,probType}];
    EEG_split = pop_select(EEG, 'time', [minTime maxTime]);
    %EEG_split.event(strcmp({EEG_split.event.type}, 'boundary')) = [];
  
    lastTime=maxTime;
    
    %data = EEG_split.data;
    data = icaTransform * EEG_split.data;
   
    datasize=size(data);
    outputstep = round(datasize(2)/10);
    output=[];
    
    for compNum = 1:datasize(1)
        tmp=[];
        freqshead=[];
        for freqindex=1:length(param.freqrange)
            [ersp,itc,powbase,times,freqs] = newtimef(data(compNum, :), datasize(2), ...
                [EEG_split.xmin*1000 EEG_split.xmax*1000], EEG_split.srate, param.freqrange{freqindex}{1},...
                'baseline',[NaN], 'freqs', param.freqrange{freqindex}{2}, 'nfreqs', length(param.freqrange{freqindex}{2}),'timesout', outputstep,...
                'plotersp','off','plotitc','off','verbose','off');
            tmp=[tmp;ersp];
            freqshead = [freqshead freqs];
        end
        output = [output;[ones(length(freqshead),1)*compNum transpose([freqshead]) tmp]];
    
        %writematrix([transpose([0 freqs]), cat(1,timerow,itc)], [param.exportPath  subN filesep 'ph_' subN '_' suffix '_comp' int2str(compNum) '.csv']);
        %writematrix([transpose([0 param.freqs]) cat(1,timerow,ersp)], [param.exportPath  subN filesep 'log_' subN '_' suffix '_comp' EEG.chanlocs(compNum).labels '.csv']);
        %writematrix([transpose([0 param.freqs]), cat(1,timerow,itc)], [param.exportPath  subN filesep 'ph_' subN '_' suffix '_comp' EEG.chanlocs(compNum).labels '.csv']);

    end
    timerow=(times - EEG_split.times(end))/1000 + param.endLat;
    output = [[NaN NaN timerow]; [NaN NaN timerow+duration]; output];
    
    writematrix(output, [param.exportPath filesep subN filesep 'log_' subN '_' suffix  '.csv']);
     
    %dcd_componentSPM(EEG_split,solType,[subN '_' suffix], param);

    
end
T = cell2table(trialinfo,'VariableNames',{'solType','index','duration','probType'});
writetable(T,[param.exportPath filesep subN filesep 'trials.csv'])
catch whatthehec
    fprintf('\nError:\n%s\n',whatthehec.identifier);
    fprintf('%s\n\n',whatthehec.message);
    rethrow(whatthehec);
end

