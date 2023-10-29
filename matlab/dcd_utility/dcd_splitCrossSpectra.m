function pass = dcd_splitCrossSpectra(EEG,subN,icaTransform, param)


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


insCount = 0;
anaCount = 0;
toCount = 0;
lastTime = -1;

trialinfo={};

for i = 1:numTrialsCRS
    solType = EEG.event(i*2).type;
    if contains(solType, 'INS')
        insCount = insCount + 1;
        if insCount>10
            continue
        end
        suffix =['INS_' num2str(insCount)];
        solType='INS';
    elseif contains(solType, 'ANA')
        anaCount = anaCount+1;
        if anaCount>10
            continue
        end
        
        suffix =['ANA_' num2str(anaCount)];
        solType='ANA';
    elseif contains(solType, 'timeout')
        toCount = toCount+1;
        if toCount>10
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
    trialinfo = [trialinfo;{solType,tmp{2},duration}];
    EEG_split = pop_select(EEG, 'time', [minTime maxTime]);
    %EEG_split.event(strcmp({EEG_split.event.type}, 'boundary')) = [];
    timelist=EEG_split.times;
  
    lastTime=maxTime;
    
    %data = EEG_split.data;
    data = icaTransform * EEG_split.data;
   
    datasize=size(data);
    outputstep = round(datasize(2)/10);
    output=[];
    
    for compNum1 = 1:(datasize(1)-1)
        for compNum2 = (compNum1+1):datasize(1)
            tmp=[];
            freqshead=[];
            for freqindex=1:length(param.freqrange)
                evalc('[coh,mcoh,timerow,freqs] = newcrossf(data(compNum1, :),data(compNum2, :), datasize(2),[EEG_split.xmin*1000 EEG_split.xmax*1000],EEG_split.srate, param.freqrange{freqindex}{1},"baseline",[NaN], "freqs", param.freqrange{freqindex}{2}, "nfreqs", length(param.freqrange{freqindex}{2}), "timesout", outputstep,"type","phasecoher","plotmean","off","plotphase","off","plotamp", "off");');
                tmp=[tmp;mean(coh)];
                freqshead = [freqshead param.freqrange{freqindex}{2}(1)];
            end
            output = [output;[ones(length(freqshead),1)*compNum1 ones(length(freqshead),1)*compNum2 transpose([freqshead]) tmp]];
        end
    end
    timerow=(timerow - timelist(end))/1000 + param.endLat;
    output = [[NaN NaN NaN timerow]; [NaN NaN NaN timerow+duration]; output];
    
    writematrix(output, [param.exportPath  subN filesep 'cross_' subN '_' suffix  '.csv']);
     
    %dcd_componentSPM(EEG_split,solType,[subN '_' suffix], param);

    
end
%T = cell2table(trialinfo,'VariableNames',{'solType','index','duration'});
%writetable(T,[param.exportPath  subN filesep 'trials.csv'])
catch whatthehec
    fprintf('\nError:\n%s\n',whatthehec.identifier);
    fprintf('%s\n\n',whatthehec.message);
    rethrow(whatthehec);
end

