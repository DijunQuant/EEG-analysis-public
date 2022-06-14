function [EEG, report, suffix] = atclv2_step_fullRankAvgRef(EEG, param, ~)
% Performs full-rank average reference by adding a temporary channel padded with zero
% See 'Why should we add zero-filled channel before average referencing? (07/18/2019 Updated)'
% on the website https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline
% In short, the data from electrode-based reference is not full rank, therefore average referencing
% needs to have one more channel number to be considered full-rank referenced, and this will produce
% correct ICA output.

%% NOTES
% instr not used. No regen options to set for step_interp


%% INITALIZE VARIABLES
report = {};
suffix = 'frAveRef';

%% SAVE RECORD OF REJECTED ELECTRODES

if EEG.nbchan ~= 62
   test = 2; 
end

test = 1;

%% TRANSFORM EEG

% EEG = fullRankAveRef(EEG);
% EEG = eeg_checkset(EEG);

end







        