function [EEG, report, suffix] = atclv2_step_regEp(EEG, param, ~)
%atclv2_step_regEp regularly epochs the data with intelligent handling of
%boundary events.
% At some point I discovered that the pop_regepochs function was deleting
% any epochs that have boundary events in them. I think this is because an
% event with a boundary is not really "regular". But there are situations
% in which you might want to retain those boundaries, e.g., if you needed
% to know where a file had been merged (so you could unmerge it later). So,
% this function accepts a parmeter param.retainBound, which, if set to 1,
% will save those epochs containing boundaries. - Brian


fprintf(['ATCLV2/' mfilename '>\n',...
    '\tCutting file into regular epochs of ' num2str(param.regEpoch) 's;\n',...
    '\n\tBoundary epoch retention = ' num2str(param.retainBound) '\n']);
%% Check data dimension

if size(EEG.data,3)>1 %if the data are already epoched
    errorMsg = sprintf([' AUTOCLAVE2 ERROR! These data are already epoched. Please make your data\n',...
        'continous before attempting to apply regular epoching.']);
    error(errorMsg)
end


%% Test for and rename boundaries

if param.retainBound == 1
    % Rename any boundary events temporarily before doing pop_regepochs.
    % this prevents pop_regepochs from identifying and deleting them.
    try
        idx = find(strcmp('boundary', {EEG.event.type}));
        [EEG.event(idx).type] = deal('bound-temp');
    catch
        fprintf(['\nATCLV2_STEP_REGEP WARNING > param.retainBound was set to 1,',...
            '/tbut no existing boundaries were found in this data.\n',...
            '/tThis is only problematic if you expected your data to have boundaries.']);
        pause(1)
    end
end


%% Regularly epoch the data

EEG = eeg_regepochs(EEG,'recurrence',param.regEpoch,'limits',[0 param.regEpoch],'rmbase',NaN);
% pretty sure that 'rmbase' 'nan' is necessary for some reason, I can't
% remember why.
EEG = pop_editeventvals( EEG, 'sort', {'epoch',0,'latency',0} ); % Re-sort events
EEG = eeg_checkset(EEG, 'eventconsistency');


%% Restore boundaries to their original labels

if param.retainBound == 1
    idx = find(strcmp('bound-temp', {EEG.event.type}));
    [EEG.event(idx).type] = deal('boundary');
end


%% END FUNCTION AND RETURN TO MASTERSELECTOR

report = {'RE length',num2str(param.regEpoch),'retain boundary epochs',num2str(param.retainBound)};
suffix = ['RE', num2str(param.regEpoch), 's'];


end