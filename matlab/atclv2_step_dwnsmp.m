function [EEG, report, suffix] = atclv2_step_dwnsmp(EEG, param, ~)
%atclv_step_qtProcess Applies bandpass to EEG data.
%   Applies bandpass to EEG data.

fprintf('\n');


%% DOWNSAMPLE

EEG_CORRECTED = pop_select(EEG, 'channel', param.downsampleToList);
EEG = eeg_checkset( EEG_CORRECTED );

%% IN CASE OF CAPITALIZED CHANNEL NAMES (e.g. AFZ instead of AFz), change them
for i = 1:length(EEG.chanlocs)
    
    % Test for presence of capital Z and change it to lowercase z
    testZ = strfind(EEG.chanlocs(i).labels, 'Z');
    if ~isempty(testZ)
        EEG.chanlocs(i).labels(testZ) = 'z';
    end
    
    % Test for presence of capital FP and change it to lowercase Fp
    testFP = strfind(EEG.chanlocs(i).labels, 'FP');
    if ~isempty(testFP)
        EEG.chanlocs(i).labels(testFP+1) = 'p';
    end
    
%% CONSTRUCT SUFFIX

suffix = ['ds'];


%% END FUNCTION AND RETURN TO MASTERSELECTOR

report = {param.downsampleToList};

end