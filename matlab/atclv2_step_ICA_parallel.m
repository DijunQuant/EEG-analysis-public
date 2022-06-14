function [pass, fileList, report] = atclv2_step_ICA_parallel(~, fileList, param)

%% NOTES

% Runs ICA with pca option as number of unrejected channel to keep full rank.

%% INITIALIZE VARIABLES

report = {};
pass = {};

parfor i = 1:size(fileList,1)
    
    % Create outFolder
    saveDir = [param.runPath param.outFolder filesep fileList{i,3}];
    
    if ~exist(saveDir, 'dir')
        mkdir(saveDir)
    end
    
    % Read EEG file
    EEG = pop_loadset(fileList{i,2});
    
    % Determine true data rank based on channel rejection record
    if isfield(EEG.etc, 'clean_channel_mask')
        trueDataRank = sum(EEG.etc.clean_channel_mask);
    else
        trueDataRank = EEG.nbchan;
    end
    
    % RUN ICA
    EEG = pop_runica(EEG, 'icatype', 'runica', 'pca', trueDataRank);
    EEG = eeg_checkset(EEG);
    
    % Save output EEG
    EEG = pop_saveset(EEG, 'filepath', saveDir, 'filename', [fileList{i,4} '_ICA.set']);
    
end

