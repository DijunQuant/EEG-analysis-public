function fullReport = atclv2_masterSelector(param, funct, varargin)

%% NOTES

% Glossary:
% "file" means filename with extension
% "filename" means filename without extension
% "filepath" means filename with extension and path from root
% "folder" means foldername
% "path" means path from root
% dnm is an internal warning "do not modify"; usually used for
% recordkeeping or variables that you should think twice before changing...

% DEV: include removed channel list in report variable
% DEV: search inpath for incorrect path delimiter and change it?

%% NAME VALUE PAIRS

% Default settings
auto = 0;
save = 1;
vol = 1;
action = 'list';

% Switch trap parses the varargin inputs
len = length(varargin);
% check "len" for even number
if mod(len,2) > 0
    error('Wrong arguments: must be name-value pairs.');
end
for i = 1:2:len
    switch lower(varargin{i})
        case 'auto'
            if varargin{i+1}==1
                action = 'next';
                auto = 1;
            end
        case 'save'
            save=varargin{i+1};
        case 'vol'
            vol=varargin{i+1};
        case 'global'
            if varargin{i+1}==1
                action = 'global';
                break
            end
        otherwise
            % neglect invalid option
    end
end

% rest of code
%% INITIALIZE VARIABLES

global EEG
% declaring globals this way is not recommended but I had to do it. global
% EEG enables functionality with the EEGLAB artifact screening GUI program.
% for more information on this hack and why it is necessary, see
% atclv2_step_gabcr. Testing has so far revealed no bugs due to global
% declaration, but keep this in mind if experiencing strange behavior,
% especially a set not saving correctly.

beep off % because I hate the beep
fullReport={}; % this will concatenate info about each file and function output
param.timestamp = datestr(now,'yymmddHHMM'); % dnm. Timestamp when MS was started
idx = 0; % file index, starts at 0
param.pd = atclv2_util_pathType(); % get path delimiter for this system
topDiv = sprintf('\n-----------------------------\n');
botDiv = sprintf('-----------------------------\n');


%% SETUP PATHS

param.runPath = [pwd, param.pd];
% The current folder in matlab is used as the run folder. The run folder
% should contain a utilities folder and a folder contianing the raw data.
% Subsequent folders will be created in the run folder by executing
% processing steps.

param.utilPath = [param.runPath, 'utilities', param.pd];
% Setup path to utilities folder. Any utilities that will be used by your
% run, e.g., a channel file, should be set here.

if isfield(param,'useAbsoluteInput') && param.useAbsoluteInput
    param.stepPath = param.inFolder;
else
    param.stepPath = [param.runPath, param.inFolder, param.pd];
end
% Setup path to current processing step input. Masterselector will
% recursively list any files it finds here that correspond to the file
% extension you specify.


%% Define Cleanup Function

onCleanup(@()exitClean(vol,param)); % cleanup function executes exitClean when you quit

    function exitClean(vol,param)
        % SPM sometimes changes the current directory to the outfolder.
        % Here, make sure it is set to the run path.
        cd(param.runPath);
        
        fprintf('\n     ATCLV2 > EXITING. PLEASE HAVE AN EXCELLENT WAKE CYCLE.\n\n');
        atclv2_util_playSound('missthedarkness.ogg',vol);
        beep on; % just turn the stupid thing back on, whatever
	end


%% SHARP STARTUP
% just some fun stuff to keep it interesting
% sounds don't work on matlab version - commented out by Shreya

fprintf('\n%s\n%s\n%s\n%s\n\n%s\n%s\n\n',' \\\\\\\\\\  //////////',' \\\\\ AUTOCLAVE2 /////',' /// MASTERSELECTOR \\\',' //////////  \\\\\\\\\\',...
    ' Autoclave2 is copyright Brian Erickson 2016',...
    ' Do not distribute source without written permission')

% atclv2_util_playSound({'richwithinfo.ogg','knowmore.ogg','knowledge.ogg',...
%     'whatelse.ogg','muchtolearn.ogg','closerlook.ogg','humans.ogg',...
%     'whatsecrets.ogg','highconcentration.ogg'},vol);
%atclv2_util_playSound('creat.wav',1);


%% BUILD FILELIST

% Check that the specified input directory exists
if ~exist(param.stepPath, 'dir')
    % if not, error message
    errorMsg = sprintf([' AUTOCLAVE2 ERROR! The input directory: ', param.stepPath, ' does not exist.\n',...
        ' Check that the current MATLAB folder and your input path are correct.']);
    error(errorMsg)
end


% Get the subject numbers from the directory
[filePaths, fileDirs, fileNames, fileExtns, ~] = atclv2_util_readDir(param.stepPath,param.fileType);

% if no files matched the search string
if isempty(fileNames)
    errorMsg = sprintf(['     AUTOCLAVE2 WARNING!!! No files found matching: \n',...
        '     "',param.stepPath, param.fileType,'" \n',...
        '     Please check your input path. All files must be in subject subfolders.\n\n']);
    error(errorMsg)
end

if isfield(param,'includeID')
    includedIndex=cellfun(@(x) find(strcmp(fileDirs,x)),param.includeID,'UniformOutput',false);
    includedIndex=[includedIndex{:}];

    filePaths=filePaths(includedIndex);
    fileDirs=fileDirs(includedIndex);
    fileNames=fileNames(includedIndex);
    fileExtns=fileExtns(includedIndex);
end

% Create the list of files
fileList = [num2cell(1:length(fileNames))',filePaths,fileDirs,fileNames,fileExtns];


%% ACTIONS
    while action
    switch action
        
        case 'next' % move to the next file
            if idx == size(fileList,1) % if we already indexed the final file, exit
                fprintf('\n     ATCLV2 > End of file list.\n')
                action = 'end';
            else
                idx = idx + 1; % index next file
                action = 'load';
            end
            
        case 'list' % User has asked to return to file list 
            fprintf('\n     APPLYING FUNCTION(S):\n')
            for f=1:length(funct)
                fprintf(['\t- ', func2str(funct{1,f}),'\n'])
                pause(.25/size(funct,2))
            end
            pause(.25)
            % Print the file match string
            fprintf('\n     TO FILES MATCHING:')
            pause(.15)
            fprintf(['\n\t"',param.stepPath, param.fileType,'"\n\n'])
            pause(.15)
            fprintf('     SELECT FILE:\n')
            pause(.15)
            % print relevant information from fileList and ask for selection
            % print the functions that will be run on any selected files, in order
            for k = 1:size(fileList,1)
                fprintf('\t- %s\t[%s]\t%s\n', fileList{k,3}, num2str(fileList{k,1}), [fileList{k,4},fileList{k,5}]);
                pause(.75/size(fileList,1))
            end
            fprintf('\t- Quit\t[q]\n\n')
            prompt = sprintf('\tSelect> ');
            allowed = [arrayfun(@num2str,1:size(fileList,1),'unif',0),'q'];
            warning = sprintf('\tNot recognized - please try again\n');
            response = atclv2_util_checkInput(prompt,allowed,100,warning); % this code is pretty hacky. update
            if strcmp(response,'q') % Handle user input
                action = 'end';
            else
                idx = str2double(response); % convert input to number
                action = 'load';
            end
            
            
        case 'load' % load selected file 
            subject.filePath    = fileList{idx,2};
            subject.folder      = fileList{idx,3};
            subject.fileName    = fileList{idx,4};
            subject.fileExt     = fileList{idx,5};
            subject.file        = [fileList{idx,4},fileList{idx,5}];
            
            fprintf(['\n     ATCLV2 > Loading File ', subject.file ,'\n'])
            fprintf(topDiv);
            tic
            EEG = atclv2_util_loadEEG(subject,param); % Load file using loadPath
            dur = toc;
            fprintf(botDiv);
            fprintf(['\n     ATCLV2 > Successfully loaded file in ',num2str(dur),'s\n'])
            action = 'run';
            
        case {'run','global'} % apply functions
            report = {};
            suffix = {};
            pass = {};
            subTime = tic;
			try
			subReport = {subject.file,subject.filePath};
			catch
				disp('fixme');
			end
            for f = 1:length(funct)
                tic
                switch action
                    case 'global'
                        fprintf(['\n     ATCLV2 > Starting execution of function (',...
                            num2str(f) '/' num2str(length(funct)) '), "',...
                            func2str(funct{1,f}),'"\n\ton file list at ' datestr(now) '\n']);
                        fprintf(topDiv);
                        [pass,fileList,report{f}] = funct{1,f}(pass,fileList,param);
                        target = 'file list';
						fullReport = report; % fix this line for global functions
                        
                    otherwise
                        fprintf(['\n     ATCLV2 > Starting execution of function (',...
                            num2str(f) '/' num2str(length(funct)) '), "',...
                            func2str(funct{1,f}),'"\n\ton file "',subject.file,'" at ' datestr(now) '\n']);
                        fprintf(topDiv);
                        [EEG,report{f},suffix{f}] = funct{1,f}(EEG, param, subject);
                        EEG = eeg_checkset(EEG);
						
						subReport = [subReport,func2str(funct{1,f}),report(f)];
                        target = ['file ', subject.file];
                end
                dur = toc;
                fprintf(botDiv);
                fprintf(['\n     ATCLV2 > Finished execution of function (',...
                    num2str(f) '/' num2str(length(funct)) '), "', func2str(funct{1,f}),...
                    '"\n\tin ',num2str(dur), 's on ',target,'"\n']);
                
                
			end
			try
			fullReport = [fullReport;subReport];
			catch
				disp('fixme');
            end
            
            %Yong commented out line 254~258
% 			if isfield(EEG,'fullReport')
% 				EEG.fullReport = {EEG.fullReport;fullReport};
%             else
%                 EEG.fullReport = {fullReport};
%             end
            
            
            subTime = toc(subTime);
            fprintf(['\n     ATCLV2 > Finished processing ' target ' in ' num2str(subTime) 's total.\n\n']);
            clear target
            % DEV: coallate a fullReport and the file suffix for this subject, across
            % functions that have been applied
            
            if strcmp(action,'global')
                action = 'end';
            elseif auto == 1
                action = 'save';
            else
                action = 'query';
            end
            
        case 'query'
            
            atclv2_util_playSound('extraordinary.ogg',vol); % alert that subject is done
            
            if idx==size(fileList,1)
                next = sprintf('Save & exit (you are at the last file)');
            else
                nextSubFile = [fileList{idx+1,4},fileList{idx+1,5}];
                next = sprintf(['Save & process next file: "',nextSubFile,'"']);
            end
            fprintf(['     SELECT OPTION:\n',...
                '\t[0] Discard changes & reload current file\n',...
                '\t[1] ', next, '\n',...
                '\t[2] Save & return to list\n',...
                '\t[3] Save file & exit\n',...
                '\t[4] Save file, exit, and load in EEGLAB GUI\n',...
                '\t[5] Discard & return to list\n',...
                '\t[6] Discard & exit\n']);
            prompt = sprintf('\n\tSelect> ');
            warning = sprintf('\t\nATCLV2 WARNING: input not recognized - please reenter\n');
            response = atclv2_util_checkInput(prompt,{'0','1','2','3','4','5','6'},1,warning);
            response = str2double(response);
            if response == 0
                fprintf('\n\n     ATCLV2 > All changes discarded. Reloading file.');
                action = 'load';
            elseif response == 1
                action = 'save'; nextAction = 'next';
            elseif response == 2
                action = 'save'; nextAction = 'list';
            elseif response == 3
                action = 'save'; nextAction = 'end';
            elseif response == 4
                action = 'save'; nextAction = 'eeglab';
            elseif response == 5
                fprintf('\n\n     ATCLV2 > All changes discarded. Returning to file list.');
                action = 'list';
            elseif response == 6
                fprintf('\n\n     ATCLV2 > All changes discarded. Exiting.');
                action = 'end';
            end
            clear response;
            
            
        case 'save'
            if save == 0
                fprintf('\n     WARNING: NO FILES SAVED; ATCLV2 > save=0 in run file.\n')
                pause(2)
            else
                if length(suffix)>1
                    suffix = ['_',strjoin(suffix, '_')]; % This works at Labmac, probably matlab2015b accepts this syntax.
%                   suffix = ['_',strjoin('_',suffix)];
                else
                    suffix = ['_',suffix{1}];
                end
                saveFilename = [fileList{idx,4},suffix];
                savePath = [param.runPath, param.outFolder, param.pd, subject.folder];
                fprintf(topDiv)
                fprintf(['ATCLV2/' mfilename '>\n\tSaving file as "' saveFilename '"\n\tin path "' savePath '"\n'])
                mkdir(savePath);
                pop_saveset(EEG,'filename',saveFilename,'filepath',savePath);
                fprintf(botDiv)
                fprintf('\n     ATCLV2 > File saved\n')
            end
            
            if auto == 1
                action = 'next';
            else
                action = nextAction;
                clear nextAction;
            end
            
        case 'eeglab'
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
            EEG = pop_loadset('filename',[saveFilename,'.set'],'filepath',savePath);
            [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
            eeglab redraw
            action = 'end';
            
        case 'end'
            clear param
            %close all
            break
            
    end
    end

end