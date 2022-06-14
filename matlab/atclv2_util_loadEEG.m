function EEG = atclv2_util_loadEEG(subject,param)

%% LOAD FILE WITH CORRECT BACKEND

% if ~isfield(param,'loader')
%     loader = '';
% else
%     loader = param.loader
% end

subject.fileExt = lower(subject.fileExt);

fprintf(['ATCLV2/' mfilename '>\n',...
    '\tInput path: "' subject.filePath '"\n']);

if strcmp(subject.fileExt,'.sss') % || strcmp(loader,'bci2000')
    EEG = pop_loadBCI2000(subject.filePath);
    
elseif strcmp(subject.fileExt,'.bdf')||strcmp(subject.fileExt,'.edf')
    % custom for biosig
    % requires biosigRefChan or you lose huge SNR!
    EEG = pop_biosig(subject.filePath,'ref',param.biosigRefChan);
    
elseif strcmp(subject.fileExt,'.set')
    % if it's a set just load normally
    try
        EEG = pop_loadset(subject.filePath);
    catch
        [setpath, setfilename]=fileparts(subject.filePath);
        EEG = pop_loadset('filename', [setfilename '.set'],'filepath', setpath);
    end
    
elseif strcmp(subject.fileExt,'.nii') || strcmp(subject.fileExt,'.dat') || strcmp(subject.fileExt,'.mat')
    EEG = subject.filePath;
    
else
    % general loader tries it
    EEG = pop_fileio(subject.filePath);
    
    
end


end

