import sys


print(sys.argv)

import pandas as pd
import numpy as np
import os
from utility import *
from hmmlearn import hmm
import pickle

import glob

env='remote'
#env='local'


idlimit=999
includeTypes=['TO','ANA','INS']

if env == 'remote':
    hmm_n=int(sys.argv[1])
    hmm_niter=int(sys.argv[2])
    randomseed=int(sys.argv[3])
    foldIndex = int(sys.argv[4])
    folder = '/projects/p31274/Drexel/processed/cra/'
    modeloutput = '/home/yyr4332/EEG/EEG-analysis/result/model_cv/'
else:
    hmm_n=4
    hmm_niter=20
    randomseed = 1
    folder = '/Users/yyu/Documents/Psychology/insight/EEG_data/processed/'
    modeloutput = '/Users/yyu/Documents/Psychology/insight/EEG_data/results/model/'

cov_type='full'
#cov_type='diag'

featureList=["{:.1f},{:.1f}".format(c,f) for c in includeSources for f in includeFreqs]
splitdf=pd.read_csv(folder+'split.csv')
nfold=len(splitdf['fold'].unique())

#for foldIndex in range(nfold):
featureDf=pd.DataFrame()
nlist=[]
idCount=0
for idFolder in os.listdir(folder):
    if not os.path.isdir(folder+idFolder):continue
    idCount=idCount+1
    if idCount> idlimit:break
    for type in ['ANA','INS','TO']:
        excludeList=splitdf[(splitdf['id']==int(idFolder))&(splitdf['type']==type)&(splitdf['fold']==foldIndex)]['trialID'].values
        print(idFolder,type,len(excludeList))
        for f in glob.glob(folder+idFolder+'*/*_'+type+'_*'):
            if f.split('.')[1]!='csv':continue
            filename = (f.split('/')[-1])
            if int(filename.split('.')[0].split('_')[-1]) in excludeList: continue
            tmp = pd.read_csv(f, index_col=None)
            nlist.append(len(tmp))
            featureDf=pd.concat([featureDf,tmp[featureList]])
print(foldIndex,len(featureDf))
cov_type='full'
model = hmm.GaussianHMM(n_components=hmm_n, n_iter=hmm_niter, covariance_type='full', params="stmc",
                            random_state=randomseed)

model.fit(featureDf[featureList].values, nlist)
with open(modeloutput + str(hmm_n)+'_'+cov_type+'_'+str(randomseed)+'_iter_'+str(hmm_niter)+'_'+str(foldIndex)+'.pkl', "wb") as file:
    pickle.dump(model, file)

