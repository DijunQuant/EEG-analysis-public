function [output, chanlabels,tCRA, tRSP] = atclv2_ANACRA_extractTFmap_YY(file, param)

report = {};


%output is a 3-D array, the first 2 is frequency by time
%third dimension is channel;
output = [];





% Get subject and trial information
%filePart = split(fileList{i,4}, '_');

%subN = fileList{i,3};
%probType = filePart {end-1};
%trialN = filePart{end};
%featuretype = filePart{1};


% Load SPM-EEG data
D = spm_eeg_load(file);

% Get channel labels
chanlabels = D.chanlabels;

% Get event variable
event = D.events;

% Get index of time for events
%tCRA = 251;
tCRA = 1500/4+1; %change epoch start from 1.5 sec before onset, YY
tRSP = length(D.time)-125;

% Create subject outfolder
%savePath = [param.runPath param.outFolder filesep subN filesep featuretype filesep probType '_' trialN];

%if ~exist(savePath, 'dir')
%    mkdir(savePath)
%end

% Loop through the channels, extract TF map and save as csv file
% also, take information about the trigger time
for j = 1:D.nchannels % Loop through the channels

    timeRow = D.time-D.time(tRSP);
    extract = squeeze(selectdata(D, chanlabels{j}, [], [], []));

    combined = [timeRow;extract];
    freqcol=[0,D.frequencies]';
    
    
    output=cat(3,output,[freqcol combined]);


    %writematrix(combined, [savePath filesep subN '_' probType '_' trialN '_' chanlabels{j} '.csv']);
end

% Stack indices of trigger timepoints




%writecell(idxRows, [param.runPath param.outFolder filesep 'timeIndices_' featuretype '.csv'])


end