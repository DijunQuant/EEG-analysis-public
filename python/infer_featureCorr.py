
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
sourceFolder = '/projects/p31274/Drexel/processed/cra/'

#local
#modelFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/results/model/'
#sourceFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/processed/cra/'
#chanFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/processed/cra_chan/'

model_name='7_full_51_iter_50'
#model_name='8_full_5_iter_50'

#with initialization
with open(modelFolder+model_name+ '.pkl', "rb") as file:
    model=pickle.load(file)
print(np.round(model.monitor_.history))

nstate = np.shape(model.means_)[0]
# without interpolation
states = range(nstate)
allstateByFreq = dict([(f,pd.DataFrame()) for f in includeFreqs])
print('state, ',nstate)
for subid in os.listdir(sourceFolder):
    if not os.path.isdir(sourceFolder + subid): continue
    print(subid)
    for f in os.listdir(sourceFolder + subid):
        if f.split('.')[1] != 'csv': continue
        currentDF=dict([(f,pd.DataFrame()) for f in includeFreqs])
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
        chanData['state']=stateDf.loc[:,list(states)].idxmax(axis=1)
        sumState=stateDf.loc[:,range(nstate)].sum()
        for f in includeFreqs:
            thisFeatureList = ["{:.1f},{:.1f}".format(c, f) for c in allSources]
            for i in range(nstate+1):
                #tmp=((chanData.loc[:,allFeatureList]).multiply(stateDf.loc[:,i],axis='index')).sum()
                if i==nstate:
                    tmp = (chanData.loc[:,thisFeatureList]).corr().reset_index()
                    tmp.loc[:,'state']='all'
                else:
                    tmp = (chanData.loc[chanData['state'] == i, thisFeatureList]).corr().reset_index()
                    tmp.loc[:,'state'] = int(i)
                currentDF[f] = currentDF[f].append(tmp,ignore_index=True)
                currentDF[f]['subid']=subid
                currentDF[f]['n'] = int(n)
                currentDF[f]['style'] = style
                currentDF[f]['len']=len(chanData[chanData['state']==i])
            allstateByFreq[f]=pd.concat([allstateByFreq[f],currentDF[f]])
    for f in includeFreqs:
        allstateByFreq[f].to_csv(chanFolder + model_name+'_'+str(f)+'_spatialCorr.csv', index=False)


