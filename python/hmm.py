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
    folder = '/projects/p31274/Drexel/processed/cra_byPC/'
    modeloutput = '/home/yyr4332/EEG/EEG-analysis/result/model/'
else:
    hmm_n=4
    hmm_niter=20
    randomseed = 1
    folder = '/Users/yyu/Documents/Psychology/insight/EEG_data/processed/'
    modeloutput = '/Users/yyu/Documents/Psychology/insight/EEG_data/results/model/'

featureList=["{:.1f},{:.1f}".format(c,f) for c in includeSources for f in includeFreqs]

featureDf=pd.DataFrame()
nlist=[]

idCount=0
for idFolder in os.listdir(folder):
    if not os.path.isdir(folder+idFolder):continue
    idCount=idCount+1
    print(idFolder)
    if idCount> idlimit:break
    for type in ['ANA','INS','TO']:
        for f in glob.glob(folder+idFolder+'*/*_'+type+'_*'):
            if f.split('.')[1]!='csv':continue
            tmp = pd.read_csv(f, index_col=None)
            nlist.append(len(tmp))
            featureDf=pd.concat([featureDf,tmp[featureList]])

print(featureDf.info())



cov_type='full'
model = hmm.GaussianHMM(n_components=hmm_n, n_iter=hmm_niter, covariance_type='full', params="stmc",
                            random_state=randomseed)

model.fit(featureDf[featureList].values, nlist)
with open(modeloutput + str(hmm_n)+'_'+cov_type+'_'+str(randomseed)+'_iter_'+str(hmm_niter)+'.pkl', "wb") as file:
        pickle.dump(model, file)


