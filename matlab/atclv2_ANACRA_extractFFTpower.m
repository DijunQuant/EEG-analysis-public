function [pass, fileList, report] = atclv2_ANACRA_extractFFTpower(~, fileList, param)

% Written by Yongtaek Oh, to extract power from FFT transformed EEG data

try

pass={};
table = {};
report = {};

% Band Power Definitions
deltaBand = [1,3];
thetaBand = [4,7];
alphaBand = [8,13];
betaBand = [14,30];
gammaBand = [31,50];

freqLabel = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
freqRange = {deltaBand;
              thetaBand;
              alphaBand;
              betaBand;
              gammaBand};


% Loop through the SPM files and extract the power values
for i = 1:size(fileList,1)
    filename = fileList{i,2};
    D = spm_eeg_load(filename); % Load eeg file
    
    % Selects data using channel labels, time and condition labels as indices
    % FORMAT res = selectdata(D, chanlabel, timeborders, condition)
    %      res = selectdata(D, chanlabel, freqborders, timeborders, condition)
    %
    % D - meeg object
    % chanlabel   - channel label, cell array of labels or [] (for all channels)
    % timeborders - [start end] in sec or [] for all times
    % freqborders - [start end] in Hz or [] for all frequencis (for TF datasets only)
    % condition   - condition label, cell array of labels or [] (for all conditions)
    
    extractRS{i} = selectdata(D, [],[],[], {'Undefined'});
    
    % Get subject information [subjectN, Day, EyeCondition]
    headerSubInfo(i,:) = split(fileList{i,3}, '-')';    
end

% Define list of channels
chanLabs = chanlabels(D);
searchChan = param.channelsToUse;
chanIdx = [];

% Create header, in the format of Chan_Freq
for s = 1:length(searchChan)
            chanIdx = [chanIdx; find(strcmp(chanLabs, searchChan{s}))];
    for t = 1:length(freqLabel)        
        tableHeader{t+(5*(s-1))} = [searchChan{s} '_' freqLabel{t}];
    end
    
end

% Combine [Subject EyeCondition] and Chan_Freq headers
tableHeader = ['Subject', 'Day', 'Condition', tableHeader];

if ~exist([param.runPath param.outFolder], 'dir')
    mkdir([param.runPath param.outFolder])
end

% Take the mean of power values along the frequency range for each channel and each subject
for l = 1:length(extractRS)
    for m = 1:length(chanIdx)
        for k = 1:length(freqLabel)
            
            powerExt{l,k+(5*(m-1))} = mean(extractRS{1,l}(chanIdx(m),freqRange{k}));
            
        end 
    end
end

% Combine [Subject EyeCondition] with power values
outputTable = [headerSubInfo, powerExt];

% Create and save table
tableOut = cell2table(outputTable, 'VariableNames', tableHeader);


writetable(tableOut,...
        [param.runPath param.outFolder filesep 'powerExtract.csv'])



catch whatsup
   keyboard 
end

end

