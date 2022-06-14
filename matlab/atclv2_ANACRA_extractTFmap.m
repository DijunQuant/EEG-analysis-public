function [pass, fileList, report] = atclv2_ANACRA_extractTFmap(pass, fileList, param)

report = {};
header = {'Subject', 'Type', 'Trial', 'CRA_idx', 'Response_idx'};
idxRows = {};
idxRows = [idxRows; header];

for i = 1:size(fileList,1) % Loop through number of files
    
    % Get subject and trial information
    filePart = split(fileList{i,4}, '_');
    
    subN = fileList{i,3};
    probType = filePart {end-1};
    trialN = filePart{end};
    featuretype = filePart{1};
    
    
    % Load SPM-EEG data
    D = spm_eeg_load(fileList{i,2});
    
    % Get channel labels
    chanlabels = D.chanlabels;
    
    % Get event variable
    event = D.events;
    
    % Get index of time for events
    tCRA = 251;
    tRSP = length(D.time)-125;
       
    % Create subject outfolder
    savePath = [param.runPath param.outFolder filesep subN filesep featuretype filesep probType '_' trialN];
    
    if ~exist(savePath, 'dir')
        mkdir(savePath)
    end
    
    % Loop through the channels, extract TF map and save as csv file
    % also, take information about the trigger time
    for j = 1:D.nchannels % Loop through the channels
        
        timeRow = D.time-D.time(tRSP);
        extract = squeeze(selectdata(D, chanlabels{j}, [], [], []));
        
        combined = [timeRow;extract];
        writematrix(combined, [savePath filesep subN '_' probType '_' trialN '_' chanlabels{j} '.csv']);
    end
    
    % Stack indices of trigger timepoints
    idxRows = [idxRows; {subN, probType, trialN, tCRA, tRSP}];

end

writecell(idxRows, [param.runPath param.outFolder filesep 'timeIndices_' featuretype '.csv'])


end