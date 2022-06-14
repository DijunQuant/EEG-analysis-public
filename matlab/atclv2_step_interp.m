function [EEG, report, suffix] = atclv2_step_interp(EEG, param, ~)
%atclv_step_interp interpolates missing channels in dataset.
%   Interpolates missing channels in dataset. Uses a reference set with
%   full channel location information as reference.

%% NOTES

%% INITALIZE VARIABLES
report = {};
suffix = 'int';

%% TRANSFORM EEG

load([param.utilPath, param.chanLocInterpFile]);
EEG = pop_interp(EEG, chanlocs, 'spherical');
EEG = eeg_checkset(EEG);

end







        