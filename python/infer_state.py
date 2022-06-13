
import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import scipy.interpolate
import glob
import random
import pickle
from utility import *

featureList=["{:.1f},{:.1f}".format(c,f) for c in includeSources for f in includeFreqs]

allFeatureList=["{:.1f},{:.1f}".format(c,f) for c in allSources for f in includeFreqs]

includeID=['102','103','104','106','107','110','111','112','114','115','117','118','120',
    '123','124','126','203','206','208','209','210','211','212','215','216','217','218','219','220','221','222','223','224','225']
prefix='log_'

modelFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/results/model/'

#for remote by channel
modelFolder= '/home/yyr4332/EEG/EEG-analysis/result/model/'
chanFolder = '/projects/p31274/Drexel/processed/cra_chan/'


#local
#modelFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/results/model/'

sourceFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/processed/cra/'
#chanFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/processed/cra_chan/'

model_name='7_full_51_iter_50'
model_name='8_full_5_iter_50'
model_name='7_full_1_iter_50'

for model_name in ['7_tied_2_iter_30_byPC']:
    #with initialization
    with open(modelFolder+model_name+ '.pkl', "rb") as file:
        model=pickle.load(file)
    print(np.round(model.monitor_.history))
    nstate = np.shape(model.means_)[0]
    # without interpolation
    states = range(nstate)
    allstate = pd.DataFrame()
    print('state, ',nstate)
    for subid in os.listdir(sourceFolder):
        if not os.path.isdir(sourceFolder + subid): continue
        for f in os.listdir(sourceFolder + subid):
            if f.split('.')[1] != 'csv': continue
            #print(f)
            currentDF=pd.DataFrame()
            style = f.split('.')[0].split('_')[2]
            n = f.split('.')[0].split('_')[3]
            tmp = pd.read_csv(sourceFolder + subid + '/' + f, index_col=None)
            state_prob = model.predict_proba(tmp[featureList])
            # stateDf=pd.concat([pd.DataFrame(state_prob,columns=states),tmp[featureList]],axis=1)
            stateDf = pd.DataFrame(state_prob, columns=states)
            stateDf['to_Onset'] = tmp['timeToStim']
            duration = tmp['timeToStim'].loc[0] - tmp['timeToResp'].loc[0]
            minT = stateDf['to_Onset'].min()
            maxT = stateDf['to_Onset'].max()
            stateDf['to_Last'] = stateDf['to_Onset'] - np.round(np.round(duration * 20) / 20, 2)
            chanData=pd.read_csv(chanFolder + subid + '/' + f, index_col=None)
            sumState=stateDf.loc[:,range(nstate)].sum()
            for i in range(nstate):
                tmp=((chanData.loc[:,allFeatureList]).multiply(stateDf.loc[:,i],axis='index')).sum()
                tmp=tmp/sumState[i]
                tmp.loc['state']=int(i)
                currentDF = currentDF.append(tmp,ignore_index=True)
            currentDF['subid']=subid
            currentDF['n'] = int(n)
            currentDF['style'] = style
            currentDF['len']=len(stateDf)
            allstate=pd.concat([allstate,currentDF])
        allstate.to_csv(chanFolder + model_name+'_allFeaturesMean.csv', index=False)


