function pass = dcd_stratefiedSplit(EEG, param)
%z-scored
    insIdx = find(contains({EEG.event.type}, 'SOL-COR-INS'));
    anaIdx = find(contains({EEG.event.type}, 'SOL-COR-ANA'));
    toIdx = find(contains({EEG.event.type}, 'timeout'));
    
    insIdx=insIdx(randperm(length(insIdx)));
    anaIdx=anaIdx(randperm(length(anaIdx)));
    toIdx=toIdx(randperm(length(toIdx)));

    %evenly divide ins and ana into N equal part, include same amount of to
    %trials
    totalChunk=param.splitN;

    insPerChunk=max(1,round(length(insIdx)/totalChunk));
    anaPerChunk=max(1,round(length(anaIdx)/totalChunk));
    toPerChunk=max(1,(insPerChunk+anaPerChunk));
    sprintf(['ins trials:', int2str(length(insIdx)),',ana trials:', int2str(length(anaIdx)),',TO trials:', int2str(length(toIdx)), '\n\n']);

    if ~exist(param.savePath,'dir')
        mkdir(param.savePath);
    end

    for i = 1:totalChunk
        corTW = [];
        for j=1:min(length(insIdx),insPerChunk)
            onsetLat = max(0,(EEG.event(insIdx(j)-1).latency*4/1000) - param.begLat);
            respLat = (EEG.event(insIdx(j)).latency*4/1000) + param.endLat;   
            corTW = [corTW; onsetLat, respLat];
        end
        insIdx(1:min(length(insIdx),insPerChunk))=[];
        for j=1:min(length(anaIdx),anaPerChunk)
            onsetLat = max(0,(EEG.event(anaIdx(j)-1).latency*4/1000) - param.begLat);
            respLat = (EEG.event(anaIdx(j)).latency*4/1000) + param.endLat;   
            corTW = [corTW; onsetLat, respLat];
        end
        anaIdx(1:min(length(anaIdx),anaPerChunk))=[];
        %stop if all ana, ins trials are used
        if length(corTW)==0
            break
        end
        for j=1:min(length(toIdx),toPerChunk)
            onsetLat = max(0,(EEG.event(toIdx(j)-1).latency*4/1000) - param.begLat);
            respLat = (EEG.event(toIdx(j)).latency*4/1000) + param.endLat;   
            corTW = [corTW; onsetLat, respLat];
        end
        toIdx(1:min(length(toIdx),toPerChunk))=[];
        if length(corTW)>0
            thisEEG = pop_select(EEG, 'time', sort(corTW),'channel',param.channelsToUse);
            normdata = zscore(thisEEG.data,0,2);
            thisEEG.data = normdata;
            pop_saveset(thisEEG,'filename',['chunk_' int2str(i) '.set'],'filepath',param.savePath);
        end
    end
end


