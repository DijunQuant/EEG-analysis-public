function [pass, fileList, report] = atclv2_step_MARAautoICreject_parallel(~, fileList, param)
%% NOTES

%% INITIALIZE VARIABLES

report = {};
pass = {};

%parfor i = 1:size(fileList,1)
for i = 1:size(fileList,1)
    
    % Create outFolder
    saveDir = [param.runPath param.outFolder filesep fileList{i,3}];
    
    if ~exist(saveDir, 'dir')
        mkdir(saveDir)
    end
    
    % Read EEG file
    EEG = pop_loadset(fileList{i,2});
    
    try
        
        ALLEEG = EEG;
        CURRENTSET = 1;
        
        MARAinput = [0,0,0,0,0];
        
        [~,EEG,~] = processMARA(ALLEEG, EEG, CURRENTSET, MARAinput);
        tmpRejectData=EEG.reject;
        save([saveDir,'/reject.mat'],'tmpRejectData');
        EEG = pop_subcomp(EEG, []);
        
        suffix = 'MARA';
        
        % Save output EEG
        EEG = pop_saveset(EEG, 'filepath', saveDir, 'filename', [fileList{i,4} '_MARA.set']);
        
    catch whatthehec
        keyboard
    end
    
end