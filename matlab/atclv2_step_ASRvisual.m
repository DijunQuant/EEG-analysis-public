function [pass, fileList, report] =atclv2_step_ASRvisual(~, fileList, param)
%relabels doors data event markers

fprintf('\n');



%% NOTES


%% INITIALIZE VARIABLES
report = {};
pass = {};

oldFiles = {fileList{1:size(fileList,1)/2,2}};
newFiles = {fileList{(size(fileList,1)/2)+1:end,2}};
    
if length(oldFiles) ~= length(newFiles)
    error('Number of files doesn''t match!!!')
end



%% RENAME EVENTS TO INTERPRETABLE STRUCTURE
for i = 1:length(oldFiles)
    oEEG = pop_loadset(oldFiles{i});
    nEEG = pop_loadset(newFiles{i});

    vis_artifacts(nEEG, oEEG);
    
    keyboard
   
    try
    close Figure 1
    close Figure 2
    catch
    end

end