function [EEG, report, suffix] = atclv2_step_resample(EEG, param, ~)
%atclv_step_qtProcess Applies bandpass to EEG data.
%   Applies bandpass to EEG data.

fprintf('\n');

%% DOWNSAMPLE

EEG_CORRECTED = pop_resample(EEG, param.resampleRate);
EEG = eeg_checkset( EEG_CORRECTED );


%% CONSTRUCT SUFFIX

suffix = ['reSmpl'];


%% END FUNCTION AND RETURN TO MASTERSELECTOR

report = {param.resampleRate};

end