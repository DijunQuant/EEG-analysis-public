function [EEG, report, suffix] = atclv2_step_cleanRawData(EEG, param, ~)
% application of clean_rawdata plugin
% (https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline)

% clean_rawdata plug-in uses Artifact Subspace Reconstruction (ASR) algorithm to

% cleanEEG = clean_rawdata(EEG, arg_flatline,
%                               arg_highpass,
%                               arg_channel,
%                               arg_noisy,
%                               arg_burst,
%                               arg_window,
%                               optionalInputCells);

% Explanation of each parameter:

%     FlatlineCriterion: Maximum tolerated flatline duration. In seconds. If a channel has a longer
%                        flatline than this, it will be considered abnormal. Default: 5
%                        THIS WILL BE TURNED OFF (-1) BECAUSE FLAT LINE OCCURS MOSTLY IN DRY EEG
%  
%     Highpass :         Transition band for the initial high-pass filter in Hz. This is formatted as
%                        [transition-start, transition-end]. Default: [0.25 0.75].
%                        THIS WILL BE TURNED OFF (-1) BECAUSE WE ALREADY HIGH-PASS FILTERED
%  
%     ChannelCriterion : Minimum channel correlation. If a channel is correlated at less than this
%                        value to a reconstruction of it based on other channels, it is considered
%                        abnormal in the given time window. This method requires that channel
%                        locations are available and roughly correct; otherwise a fallback criterion
%                        will be used. (default: 0.85)
                            
%  
%     LineNoiseCriterion : If a channel has more line noise relative to its signal than this value, in
%                          standard deviations based on the total channel population, it is considered
%                          abnormal. (default: 4)
%                        THIS WILL BE TURNED OFF (-1) BECAUSE WE ALREADY USED CLEANLINE FUNCTION
%  
%     BurstCriterion : Standard deviation cutoff for removal of bursts (via ASR). Data portions whose
%                      variance is larger than this threshold relative to the calibration data are
%                      considered missing data and will be removed. According to Chang et al. (2018).
%                      "Evaluation of Artifact Subspace Reconstruction for Automatic EEG Artifact Removal.
%                      Conf Proc IEEE Eng Med Biol Soc. 2018", the recommended value here is 10-100.
%                      For more detail, see https://sccn.ucsd.edu/wiki/Artifact_Subspace_Reconstruction_(ASR)#Comments_to_the_HAPPE_paper.2C_and_how_to_choose_the_critical_parameters
%                      I put the default value of 20 here.
%                        THIS NEEDS WORK FOR OPTIMIZATION, BUT WE WILL START WITH RECOMMENDED 20
%  
%                      (Original description: separated by Makoto, 03/26/2019) The most aggressive value that can
%                      be used without losing much EEG is 3. For new users it is recommended to at
%                      first visually inspect the difference between the original and cleaned data to
%                      get a sense of the removed content at various levels. A quite conservative
%                      value is 5. Default: 5.
%  
%     WindowCriterion :  Criterion for removing time windows that were not repaired completely. This may
%                        happen if the artifact in a window was composed of too many simultaneous
%                        uncorrelated sources (for example, extreme movements such as jumps). is is
%                        the maximum fraction of contaminated channels that are tolerated in the final
%                        output data for each considered window. Generally a lower value makes the
%                        criterion more aggressive. Default: 0.25. Reasonable range: 0.05 (very
%                        aggressive) to 0.3 (very lax).
%                        THIS NEEDS WORK FOR OPTIMIZATION, BUT WE WILL START WITH RECOMMENDED .25



fprintf('\n');

%% APPLY CLEAN_RAWDATA FUNCTION
% -----------------------------------------------------------------------------------------------------------------------------
%       |       Criterion          | Values            |  Explanation                                                         |
% ----------------------------------------------------------------------------------------------------------------------------|
inputs = {'FlatlineCriterion',       'off',...       % | Maximum tolerated flatline duration in seconds (def: 5)              |
         'ChannelCriterion',         param.chanC,... % | Rej if chan is correlated with others less than thresh (def: .85)    |
         'LineNoiseCriterion',       'off',...       % | Rej if chan has more line noise than signal in unit of SD (def: 4)   |
         'Highpass',                 'off',...       % | Apply high-pass filter to the data, but already done (def: 'off')    |
         'BurstCriterion',           param.asrSD,... % | Find segment of data to clean based on cleanest portion (def: 20)    |
         'WindowCriterion',          param.winCr,... % | Tolerance for maximum percentage of contamintion for chan (def: .25) |
         'BurstRejection',           'off',...       % | Removes bad data caught by ASR instead of correcting (def: 'on')     |
         'Distance',                 'Euclidian',... % | Which type of distance metric to use (def: 'Euclidian')              |
         'WindowCriterionTolerances',[-Inf,7]};      % | Noise threshold for labeling a chan as contaminated (def: [-Inf 7])  |
% ----------------------------------------------------------------------------------------------------------------------------- 

EEG = pop_clean_rawdata(EEG, inputs{:});


%% CONSTRUCT SUFFIX
BCRcorr = num2str(inputs{4});
try BCRcorr = BCRcorr(3:4); catch BCRcorr = [BCRcorr(3) '0']; end
WINcr = num2str(inputs{12});
try WINcr = WINcr(3:4); catch WINcr = [WINcr(3) '0']; end

suffix = ['ASR_BCRcorr_p' BCRcorr ,'_ASRsd_', num2str(inputs{10}), '_WINcr_p' ,WINcr];


%% END FUNCTION AND RETURN TO MASTERSELECTOR

report = {'BCRcorr', ['p' BCRcorr] ,'ASRsd', num2str(inputs{10}), 'WINcr' ,WINcr};


end
