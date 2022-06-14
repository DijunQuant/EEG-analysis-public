function [EEG, report, suffix] = atclv2_step_hipass(EEG, param, ~)
%atclv_step_qtProcess Applies bandpass to EEG data.
%   Applies bandpass to EEG data.

fprintf('\n');

%% APPLY HIGH-PASS FILTER

%09/30/19: Yong tried using only 3 paramters, EEG, locutoff, hicutoff.
EEG = pop_eegfiltnew(EEG, param.locutoff, []);


%% CONSTRUCT SUFFIX

lc = strrep(num2str(param.locutoff), '.', 'p');
suffix = ['HP', lc];


%% END FUNCTION AND RETURN TO MASTERSELECTOR

report = {};


end