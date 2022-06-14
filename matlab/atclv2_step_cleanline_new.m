function [EEG, report, suffix] = atclv2_step_cleanline_new(EEG, ~, ~)
% application of cleanline function based on Makoto Miyakoshi's recommendation
% (https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline)

fprintf('\n');

%% CLEANLINE

EEG = pop_cleanline(EEG, 'chanlist', [1:length(EEG.chanlocs)], 'ComputeSpectralPower', 1, ...
                         'SignalType', 'Channels', 'VerboseOutput',1,...
                         'SlidingWinLength',2,'SlidingWinStep',2,...
                         'LineAlpha',0.1);
                     
%% CONSTRUCT SUFFIX

suffix = 'CL';


%% END FUNCTION AND RETURN TO MASTERSELECTOR

report = {'winsize', '3' ,'winstep', '3'};


end