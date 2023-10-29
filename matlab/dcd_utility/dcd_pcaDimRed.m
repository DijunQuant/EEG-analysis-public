function compressed = dcd_pcaDimRed(EEG,num2retain)
    data = reshape( EEG.data(1:EEG.nbchan,:,:), EEG.nbchan, EEG.pnts*EEG.trials);
    tmprank = getrank(double(data(:,1:min(3000, size(data,2)))));
    data = data - repmat(mean(data,2), [1 size(data,2)]); % zero mean 
    PCdat2 = data';                    % transpose data
    [PCn,PCp]=size(PCdat2);                  % now p chans,n time points
    PCdat2=PCdat2/PCn;
    PCout=data*PCdat2;
    clear PCdat2;
    
    [PCV,PCD] = eig(PCout);                  % get eigenvectors/eigenvalues
    [PCeigenval,PCindex] = sort(diag(PCD));
    PCindex=rot90(rot90(PCindex));
    PCEigenValues=rot90(rot90(PCeigenval))';
    PCEigenVectors=PCV(:,PCindex);
    %PCCompressed = PCEigenVectors(:,1:ncomps)'*data;
    compressed = PCEigenVectors(:,1:num2retain)'*data;
    
end

