function [EEG,report,suffix] = atclv2_step_loadChanLocs(EEG, param, ~)
%atclv_step_blr adds channel locations to the EEG data.
%   Adds channel locations to the EEG data with intelligent handling of
%   existing locations.


%% CHECK FOR CHANNEL LOCATIONS FILEPATH

if ~isfield(param,'channelFile')
    errormsg = sprintf(['\nAUTOCLAVE2 ERROR! Path to channel locations file was not set.\n',...
        'Please set param.channelFile to the name of your channel locations file,\n',...
        'which should be placed in the utilities folder inside the run folder.']);
    error(errormsg);
end

chanlocsFilepath = [param.utilPath, param.channelFile];

if ~exist(chanlocsFilepath, 'file')
    errormsg = sprintf(['\nAUTOCLAVE2 ERROR! The specified channel locations file: \n"',...
        chanlocsFilepath,'"\ndoes not exist. Please check that you have passed the correct filename to\n',...
        '"param.channelFile", and that your channel locations file is in\n',...
        'the utilities folder inside the run folder.']);
    error(errormsg);
end

%% LOAD CHANNEL LOCATIONS

fprintf(['ATCLV2/' mfilename '>\n',...
    '\tAdding channel locations to data from channel location file:\n\t"',...
    chanlocsFilepath '"\n']);
EEG = pop_chanedit(EEG,'lookup',chanlocsFilepath);


%% END FUNCTION AND RETURN TO MASTERSELECTOR
report = {chanlocsFilepath};
suffix = 'chlc';


end