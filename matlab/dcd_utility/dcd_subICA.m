
function pass=dcd_subICA(sublist,param,seeds)
    if length(seeds)==0
        runICA(sublist,param);
    else
        for i=1:length(seeds)
            pass=concateAndICA(sublist,param,seeds(i));
        end
    end
end

function pass=concateAndICA(sublist,param,seed)

    subN=length(sublist);

    sampleList=zeros(subN,param.splitN);
    rng(seed);
    for i=1:subN
        sampleList(i,:)=randperm(param.splitN);
    end


    for j=1:param.splitN
        thisSample={};
        eegSave=[];
        for i=1:subN
            if ~ismember(sublist(i).name,param.includeID)
                continue
            end
            if exist([param.inFolder filesep sublist(i).name filesep 'chunk_' int2str(sampleList(i,j)) '.set'])
                thisSample{end+1}={sublist(i).name,sampleList(i,j)};
                currentEEG=pop_loadset('filename', ['chunk_' int2str(sampleList(i,j)) '.set'],...
                    'filepath', [param.inFolder  filesep sublist(i).name]);
                if length(eegSave)>0
                    eegSave = pop_mergeset(eegSave, currentEEG);
                else
                    eegSave=currentEEG;
                end
            else
                fprintf([' not exist' param.inFolder filesep sublist(i).name filesep 'chunk_' int2str(sampleList(i,j)) '.set']);
            end
        end
        saveFolder=[param.outFolder filesep 'chunk_' int2str(j)];
        mkdir(saveFolder);
        %pop_saveset(eegSave,'filename',['chunk_' int2str(j) '.set'],'filepath',saveFolder);
        save([saveFolder filesep 'sample.mat'],'thisSample');
        [W,S,mods] = runamica15(eegSave.data, 'outdir' ,saveFolder,...
                'max_threads', 2,  'num_models',param.numModels,...
                'max_iter',param.max_iter); 
        eegSave.icaweights = W;
        eegSave.icasphere = S(1:size(W,1),:);
        eegSave.icawinv = mods.A(:,:,1);
        eegSave.mods = mods;
        % Load AMICA information to input files through postAMICAutility toolbox
        eegSave = pop_loadmodout(eegSave, saveFolder);
        eeg_checkset(eegSave); 
        eegSave = pop_saveset(eegSave, 'filename',['chunk_' int2str(seed) '_'  int2str(j) '.set'],...
                'filepath', saveFolder);
        
    end
end



function runICA(sublist,param)

    subN=length(sublist);

    sampleList=zeros(subN,param.splitN);
    for i=1:subN
        sampleList(i,:)=randperm(param.splitN);
    end

    eegSave=[];
    for j=1:param.splitN
        
        for i=1:subN
            if ~ismember(sublist(i).name,param.includeID)
                continue
            end
            if exist([param.inFolder filesep sublist(i).name filesep 'chunk_' int2str(sampleList(i,j)) '.set'])
                currentEEG=pop_loadset('filename', ['chunk_' int2str(sampleList(i,j)) '.set'],...
                    'filepath', [param.inFolder  filesep sublist(i).name]);
                if length(eegSave)>0
                    eegSave = pop_mergeset(eegSave, currentEEG);
                else
                    eegSave=currentEEG;
                end
            else
                fprintf([' not exist' param.inFolder filesep sublist(i).name filesep 'chunk_' int2str(sampleList(i,j)) '.set']);
            end
        end
    end
    
    saveFolder=[param.outFolder filesep];
    mkdir(saveFolder);
    sprintf(['save folder ', saveFolder, '\n\n']);
    eegSave = pop_saveset(eegSave, 'filename','group.set',...
            'filepath', saveFolder);
 
        
    [W,S,mods] = runamica15(eegSave.data, 'outdir' ,saveFolder,...
                'max_threads', 2,'num_models',param.numModels,...
                'max_iter',param.max_iter,...
                'pcakeep',param.pcakeep); 
    eegSave.icaweights = W;
    eegSave.icasphere = S(1:size(W,1),:);
    eegSave.icawinv = mods.A(:,:,1);
    eegSave.mods = mods;
    % Load AMICA information to input files through postAMICAutility toolbox
    eegSave = pop_loadmodout(eegSave, saveFolder);
    eeg_checkset(eegSave); 
    eegSave = pop_saveset(eegSave, 'filename','group.set',...
            'filepath', saveFolder);
end