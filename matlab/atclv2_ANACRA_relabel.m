function [EEG, report, suffix] = atclv2_ANACRA_relabel(EEG, param, ~)
%relabels doors data event markers

fprintf('\n');



%% NOTES



%% INITIALIZE VARIABLES
report = {};

try
    
    %% REMOVE BOUNDARY EVENT IF ANY
    
evtList = {EEG.event.type};
boundaryInd = find(strcmp('boundary', evtList));

if ~isempty(boundaryInd)
        EEG.event(boundaryInd) = [];
end
        
    
    
%% RENAME EVENTS TO INTERPRETABLE STRUCTURE
for i = 1:length(EEG.event)
    
    if i ~= length(EEG.event)
        
        if strcmp(EEG.event(1,i).type, 'CRA')
            
            if strcmp(EEG.event(1,i+1).type, 'timeout')
                EEG.event(1,i).type = [retCode(EEG.event(1,i).type), '-' ,...
                    retCode(EEG.event(1,i+1).type)]; % Click For Next Round
            else
                EEG.event(1,i).type = [retCode(EEG.event(1,i).type), '-' ,...
                    retCode(EEG.event(1,i+2).type), '-',...
                    retCode(EEG.event(1,i+3).type)]; % Click For Next Round
            end
        end
        
        if strcmp(EEG.event(1,i).type, 'Solution')
            EEG.event(1,i).type = [retCode(EEG.event(1,i).type), '-' ,...
                retCode(EEG.event(1,i+1).type), '-',...
                retCode(EEG.event(1,i+2).type)]; % Click For Next Round
        end
    end
    
end

    


%% CONSTRUCT SUFFIX

suffix = ['relabeled'];

catch what
    keyboard
end

end

function returnStr = retCode(inputStr)
    switch inputStr
        case 'CRA'
            returnStr = 'CRA';
        case '4Word'
            returnStr = '4WW';
        case '5Word'
            returnStr = '5WW';
        case '4Nonword'
            returnStr = '4NW';
        case '5Nonword'
            returnStr = '5NW';
        case 'Correct'
            returnStr = 'COR';
        case'Incorrect'
            returnStr = 'INC';
        case 'Insight'
            returnStr = 'INS';
        case 'Methodical'
            returnStr = 'ANA';
        case 'Solution'
            returnStr = 'SOL';
        case 'timeout'
            returnStr = 'STO';
        otherwise
            returnStr = inputStr;
    end
end