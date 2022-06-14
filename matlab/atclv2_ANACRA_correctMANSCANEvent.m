function [EEG, report, suffix] = atclv2_ANACRA_correctMANSCANEvent(EEG, param, ~)
% Reads excel file (manually edited) containing correct event markers
% and corrects event information in the EEG file

fprintf('\n');

try
    
%% LOAD EVENT CORRECTION TABLE

% Find subject number from filename
subNumTemp = strsplit(EEG.comments, filesep);
subNumTest = cell2mat(cellfun(@(x) length(x) == 3, subNumTemp, 'UniformOutput', false)) & ~isnan(str2double(subNumTemp));
subNum = subNumTemp{subNumTest};

evtCorTablePath = dir([param.utilPath 'eventCorrectionTable' filesep param.sessionType filesep '*' subNum '*']);
evtCorTablePath = [evtCorTablePath.folder filesep evtCorTablePath.name];
corTable = readtable(evtCorTablePath);

% Remove rows (trials) that have empty EEG record
corTableMod = corTable(~cell2mat(cellfun(@(x) isempty(x), corTable.Sol_EEG, 'UniformOutput', false)),:);

%% CREATE EVENT LIST FROM EEG DATA

selEvtList = {'timeout', 'SOL-COR-INS', 'SOL-COR-ANA', 'SOL-INC-INS', 'SOL-INC-ANA', 'NoSolution', 'SolutionBimanFail'};
eegEvtList = {EEG.event.type};
eegEvtSel = {};
eegEvtInd = [];

for iEvt = 1:length(eegEvtList)
    
    if ~strcmp(eegEvtList{iEvt}, 'SolutionBimanFail')
        if any(strcmp(eegEvtList{iEvt}, selEvtList))
            eegEvtSel = [eegEvtSel; eegEvtList{iEvt}];
            eegEvtInd = [eegEvtInd, iEvt];
        end
    elseif contains(eegEvtList{iEvt+1}, {'Correct', 'Incorrect'})
        if any(strcmp(eegEvtList{iEvt}, selEvtList))
            eegEvtSel = [eegEvtSel; eegEvtList{iEvt}];
            eegEvtInd = [eegEvtInd, iEvt];
        end
    end
end

%% CORRECT INCORRECT LABELS

% Check whether number of events from EEG is equal to eprime-derived event list (trimmed)

if length(eegEvtSel) ~= size(corTableMod,1)
    error('Something wrong with number of events in the EEG and Excel record!')
end

% Get solution match indices
solMismatch = ~corTableMod.SolMatch;
solMismatchInd = find(solMismatch);

if ~isempty(solMismatchInd)
    
    for i = 1:length(solMismatchInd)
        iMismatch = solMismatchInd(i);
        solEpr = corTableMod.Sol_Epr{iMismatch};
        
        % Why use switch statement?
        % There are cases where Eprime trigger name is weird (e.g. 'INC'),
        % so we want to take trials that have complete trigger name
        switch solEpr
            case {'COR-ANA', 'COR-INS', 'INC-ANA', 'INC-INS'}
                labelWrong = EEG.event(eegEvtInd(iMismatch)).type;
                labelCorrect = ['SOL-' solEpr];
                EEG.event(eegEvtInd(iMismatch)).type = labelCorrect;
                disp(['EEG.event ' num2str(eegEvtInd(iMismatch)) ' corrected from ' labelWrong ' to ' labelCorrect]); 
            otherwise
                % We are only interested in correct/incorrect flip.
                % NoSolution won't be considered as Timeout for this pipeline.
        end
    end
end

fprintf('\n')

%% CONSTRUCT SUFFIX

suffix = 'solCorrected';


%% END FUNCTION AND RETURN TO MASTERSELECTOR

report = length(solMismatchInd);

catch what
    length(eegEvtSel)
    length(corTableMod.Sol_EEG)
    test = [eegEvtSel(1:end-1),  num2cell(eegEvtInd(1:end-1))', corTableMod.Sol_EEG];
    test = [eegEvtSel,  num2cell(eegEvtInd)', corTableMod.Sol_EEG(1:end-1)];
    keyboard
end
