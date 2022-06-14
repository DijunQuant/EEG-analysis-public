function [pass, fileList, report] = atclv2_ANACRA_countEvents(~, fileList, param)
%relabels doors data event markers

fprintf('\n');



%% NOTES


%% INITIALIZE VARIABLES
report = {};
pass = {};
eventList = cell(size(fileList,1),300);
errSubList = {};



%% RENAME EVENTS TO INTERPRETABLE STRUCTURE
fprintf('I will load bunch of files... Here we go!\n')
pause(1)
for i = 1:size(fileList,1)
    
    EEG = pop_loadset(fileList{i,2});
    elTemp = {EEG.event.type};
    for j = 1:length(elTemp)
        eventList{i,j} = elTemp{j};
    end
    
end

fprintf('\n')
fprintf('Showing number of correct Inights and Analysis for each subject.. \n')
pause(1)
totINS = 0;
totANA = 0;

for k = 1:size(fileList,1)
    
    cleanStuff = eventList(k,:);
    cleanStuff = cleanStuff(~cellfun('isempty',cleanStuff));
    
    eventINS = sum(contains(cleanStuff, 'SOL-COR-INS'));
    eventANA = sum(contains(cleanStuff,'SOL-COR-ANA'));
    
    totINS = totINS + eventINS;
    totANA = totANA + eventANA;
    
%     if eventUP ~= 40 || eventDOWN ~=40
%         errSubList = [errSubList;fileList{k,2}];
%     end

    fprintf(['Subject ' fileList{k,4}(1:3) ': \t' num2str(eventINS) '\t Insight, ' num2str(eventANA) '\t Analytic\n'])
end

fprintf(['In total, there are ' num2str(totINS) ' Insights and '...
    num2str(totANA) ' Analytic Trials\n'])

fprintf('\n')
fprintf('Generating report for subjects with error. Check your outfolder.\n')
pause(1)

rowN = 1;
colN = 1;
trialN = 1;
errEvtSort = cell(90,5);
errEvtSort{1,1} = 1;

errFileDir = [pwd filesep param.outFolder filesep 'ErrorFilesDat'];
if ~exist(errFileDir, 'dir')
    mkdir(errFileDir)
end

for l = 1:size(errSubList,1)
    EEG = pop_loadset(errSubList{l});
    errEventList = {EEG.event.type};
    
    for m = 1:length(errEventList)
        
        if strcmp(errEventList{m}, 'empty') && strcmp(errEventList{m+1}, 'CFNR')
            %Just pass
        else
            
            
            if strcmp(errEventList{m}, 'CFNR')
                errEvtSort{rowN,1} = trialN;
            end
            
            if ~strcmp(errEventList{m}, 'BREAK')
                if strcmp(errEventList{m}, 'DOWN')
                    colN = 5;
                else
                    colN = colN+1;
                end
                
                errEvtSort{rowN, colN} = errEventList{m};
            end
            
            if strcmp(errEventList{m}, 'UP') || strcmp(errEventList{m}, 'DOWN')
                colN = 1;
                trialN = trialN+1;
                rowN = rowN+1;
            end
            
        end
    end
    
    table = cell2table(errEvtSort, 'VariableNames', {'TrialN', 'Click', 'Doors', 'Mouse', 'Stim'});
    writetable(table, [errFileDir filesep 'errorFile_' EEG.filename(1:3) '.csv'])
    
    rowN = 1;
    colN = 1;
    trialN = 1;
    errEvtSort = cell(90,5);
    errEvtSort{1,1} = 1;
    
    
    
end


end