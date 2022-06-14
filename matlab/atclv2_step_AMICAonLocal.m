function [pass, fileList, report] = atclv2_step_AMICAonLocal(~, fileList, param)
%% NOTES
% Need AMICA plugin and post-AMICA utility plugin in order to run
% 
%% INITIALIZE VARIABLES
tic
pass = {};
report = {};

try param.numModels; catch; param.numModels = 1; end
try param.max_iter; catch; param.max_iter = 2000; end
%min_dll = 1e-7; %change from default 1e-9

try
    %parfor can be used to run entire fileList in parallel
    parfor i = 1:size(fileList,1)
    %for i = 1:size(fileList,1)
        EEG = pop_loadset(fileList{i,2});
        
        if isfield(EEG.etc, 'clean_channel_mask')
            trueDataRank = sum(EEG.etc.clean_channel_mask);
        else
            trueDataRank = EEG.nbchan;
        end
        
        subjID = fileList{i,3};
        outdir = [param.runPath param.outFolder filesep subjID filesep];
        
        if ~exist(outdir, 'dir')
            mkdir(outdir)
        end
        
        [W,S,mods] = runamica15(EEG.data, 'num_chans', EEG.nbchan, 'outdir' ,outdir,...
            'max_threads', 2, 'pcakeep', trueDataRank, 'num_models',param.numModels,...
            'max_iter',param.max_iter);
        
        
        EEG.icaweights = W;
        EEG.icasphere = S(1:size(W,1),:);
        EEG.icawinv = mods.A(:,:,1);
        EEG.mods = mods;
              
        
        % Load AMICA information to input files through postAMICAutility toolbox
        AMICAoutputFolder = [param.runPath param.outFolder filesep subjID];      
        
        EEG = pop_loadmodout(EEG, AMICAoutputFolder);
        
        eeg_checkset(EEG);

        EEG = pop_saveset(EEG, 'filename', [fileList{i,4} '_AMICA'],...
            'filepath', [param.runPath param.outFolder param.pd subjID]);
    end
     
catch whatthehec
    keyboard
end

toc

end
