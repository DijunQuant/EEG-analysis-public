function pcaTransform = dcd_runPCA(setpath,param)
    
    sublist=rdir(setpath,'isdir',1);
    for i = 1:length(sublist)
        tmp=split(sublist(i).name,filesep);
        sublist(i).name=tmp{2};
    end

    fprintf(['run all PCA', '\n\n']);
    subN=length(sublist);

    eegSave=[];

    sampleList=zeros(subN,1);
    for i=1:subN
            sampleList(i,:)=randperm(1);
    end
    j=1;
    for i=1:subN
        if ~ismember(sublist(i).name,param.includeID)
            continue
        end
        if exist([setpath filesep sublist(i).name filesep 'chunk_' int2str(sampleList(i,j)) '.set'])
            currentEEG=pop_loadset('filename', ['chunk_' int2str(sampleList(i,j)) '.set'],...
                'filepath', [setpath  filesep sublist(i).name]);
            if length(eegSave)>0
                eegSave = pop_mergeset(eegSave, currentEEG);
            else
                eegSave=currentEEG;
            end
        else
            fprintf([' not exist' setpath filesep sublist(i).name filesep 'chunk_' int2str(sampleList(i,j)) '.set']);
        end
    end

    [pc,eigvec,sv] = runpca(eegSave.data(:,:));
    pcaTransform = inv(eigvec);
    %data = eigvec * pc
    writematrix(pcaTransform, [param.exportPath filesep 'eig.csv']);
   
end

