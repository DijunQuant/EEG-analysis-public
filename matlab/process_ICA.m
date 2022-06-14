
steps = {'plot','mara','dipole'};
steps = {'mara'};
totalchan=84;
EEG = pop_loadset('filename','group.set','filepath','cra_y_all_pca/');

%[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

EEG = pop_loadmodout(EEG,'cra_y_all_pca/');
%[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = eeg_checkset( EEG );
    

if any(strcmp(steps,'plot'))
    %pop_prop( EEG, 0, 1, NaN, {'freqrange',[2 50] });
    for i = 1:20
        pop_prop_save(EEG, 0, i, NaN,['junk/comp_' int2str(i) '.png'],{'freqrange',[2 50] });
    end
end

if any(strcmp(steps,'mara'))
    ALLEEG = EEG;
    CURRENTSET = 1;
    MARAinput = [0,0,0,0,0];
    [~,EEG,~] = processMARA(ALLEEG, EEG, CURRENTSET, MARAinput);
    tmpRejectData=EEG.reject;
    save(['junk/','/reject.mat'],'tmpRejectData');
end

if any(strcmp(steps,'dipole'))
    ALLEEG = EEG;
    CURRENTSET = 1;
    EEG = pop_dipfit_settings( EEG, 'hdmfile','/home/yyr4332/Documents/MATLAB/eeglab2021.0/plugins/dipfit/standard_BESA/standard_BESA.mat','coordformat','Spherical','mrifile','/Users/yyu/Documents/MATLAB/eeglab2021.0/plugins/dipfit/standard_BESA/avg152t1.mat','chanfile','/Users/yyu/Documents/MATLAB/eeglab2021.0/plugins/dipfit/standard_BESA/standard-10-5-cap385.elp','coord_transform',[0 0 0 0 0 0 1 1 1] ,'chansel',[1:19] );
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = pop_multifit(EEG, [1:totalchan] ,'threshold',100,'rmout','on','plotopt',{'normlen','on'});
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    dipfitmodel=EEG.dipfit.model;
    save(['junk/','/dipfit_single.mat'],'dipfitmodel');
    EEG = pop_multifit(EEG, [1:totalchan] ,'threshold',100,'rmout','on','dipoles',2,'plotopt',{'normlen','on'});
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    dipfitmodel=EEG.dipfit.model;
    save(['junk/','/dipfit_bipole.mat'],'dipfitmodel');
end





        