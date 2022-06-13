import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from utility import *
from hmmlearn import hmm
import seaborn as sns
import pickle
import matplotlib.cm as cm
from matplotlib.backends.backend_pdf import PdfPages
from itertools import permutations



coord=pd.read_csv('/Users/yyu/Documents/Psychology/insight/Drexel/loc2D.csv',index_col='label')
coord=pd.read_csv('/Users/yyu/Documents/Psychology/insight/Drexel/loc2D_84.csv',index_col='labels')


coord.loc[:,'x']=coord.loc[:,'radius']*np.cos(np.pi/180*(90-coord.loc[:,'theta']))
coord.loc[:,'y']=coord.loc[:,'radius']*np.sin(np.pi/180*(90-coord.loc[:,'theta']))
coord.loc[:,'x']=coord.loc[:,'x']/(coord.loc[:,'x'].max())
coord.loc[:,'y']=coord.loc[:,'y']/(coord.loc[:,'y'].max())

flist=np.round(includeFreqs,1)
freqLabel = dict([(c[0], c[1]) for c in zip(flist,['4-7','8-9','10-13','14-17','18-24','25-29','30-39','40-50'])])

featureList=["{:.1f},{:.1f}".format(c,f) for c in allSources for f in includeFreqs]

#icaTransform=np.linalg.inv(pd.read_csv('icaTransform.csv',index_col=None,header=None).values)
#try?
#icaTransform=pd.read_csv('icaTransform.csv',index_col=None,header=None).values
#icaTransform=icaTransform[:,clist-1]
allchannels=channellist


def getMeanArrayByData(allstate,nstate):
    allmeans=[]
    for state in range(nstate):
        tmp = allstate.loc[allstate['state'] == state]
        meanSer = tmp.loc[:, featureList].multiply(tmp.loc[:, 'len'], axis='index').sum() / (tmp['len'].sum())
        meanPD=pd.DataFrame([[meanSer.loc["{:.1f},{:.1f}".format(c,f)] for f in includeFreqs] for c in allSources],
                   index=allSources,columns=includeFreqs)
        allmeans.append(meanPD.values)
    return np.array(allmeans)
def makePdf(allmeans,savefolder,label,makepdf=True,maxval=1):
    nstate=len(allmeans)
    with PdfPages(savefolder+label+'.pdf') as export_pdf:
        for state in range(nstate):
            fig, ax = plt.subplots(3, 3, figsize=(15, 15))
            #plt.suptitle(label+'_'+str(state))
            means=allmeans[state]
            meanPD = pd.DataFrame(means,index=allchannels, columns=flist)
            meanPD.loc[:, 'x'] = coord.loc[meanPD.index, 'x'].values
            meanPD.loc[:, 'y'] = coord.loc[meanPD.index, 'y'].values
            x_index = 0
            y_index = 0
            print(state)
            if type(maxval)!=float:
                maxval=np.max(np.abs(means))
            for freq in flist:
                CS = plotContour(meanPD['x'].values, meanPD['y'].values, meanPD[freq].values, ax[x_index, y_index], fig,
                                 makebar=False,maxval=maxval)
                ax[x_index, y_index].set_title(freqLabel[freq],fontdict={'fontsize':24, 'fontweight': 'bold'})
                if (x_index==1) & (y_index==1):
                    x_index = 2
                    y_index = 0
                else:
                    y_index += 1
                    if (y_index == 3):
                        x_index += 1
                        y_index = 0
            #ax[1, 2].figure.colorbar(CS, pad=.05, extend='both', fraction=0.5, ticks=np.linspace(-1, 1, 11))
            ax[1, 2].axis('off')
            fig.colorbar(CS, ax=ax[1, 2], pad=.05, extend='both', fraction=0.5, ticks=np.round(np.linspace(-1*maxval, maxval, 9),2))
            plt.tight_layout()
            #plt.savefig(folder + 'png/' + str(state + 1) + '_6' + '.png')
            if makepdf:
                export_pdf.savefig()
            else:
                plt.savefig(savefolder + label +'_'+ str(state) +'.png')
            plt.close()
def allstateplot(allmeans,savefolder,label,maxval=0.55,order=None):
    nstate=len(allmeans)
    if order==None:
        stateorder=range(nstate)
    else:
        stateorder=order
    fig, ax = plt.subplots(nstate, 8, figsize=(15,1.75*nstate))
    if type(maxval)!=float:
        maxval = np.quantile(np.abs(allmeans).flatten(),.95)
    x_index = 0
    for state in stateorder:
        means = allmeans[state]
        meanPD = pd.DataFrame(means, index=allchannels, columns=flist)
        meanPD.loc[:, 'x'] = coord.loc[meanPD.index, 'x'].values
        meanPD.loc[:, 'y'] = coord.loc[meanPD.index, 'y'].values
        y_index = 0
        for freq in flist:
            CS = plotContour(meanPD['x'].values, meanPD['y'].values, meanPD[freq].values, ax[x_index, y_index], fig,
                                 makebar=False,maxval=maxval)
            #ax[x_index, y_index].set_title(freqLabel[freq],fontdict={'fontsize':24, 'fontweight': 'bold'})
            y_index+=1
        x_index += 1
    fig.tight_layout(h_pad=2, w_pad=0)
    plt.savefig(savefolder + label +'.png')
    plt.close()
    fig, ax = plt.subplots(1,figsize=(5,8))
    fig.colorbar(CS, ax=ax, pad=.05, extend='both', fraction=0.5,
                 ticks=np.round(np.linspace(-1 * maxval, maxval, 9), 2))
    plt.savefig(savefolder + label + '_bar.png')
    plt.close()

modelFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/results/model/'
outputFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/results/stateplots/'


model_name='13_full_2_iter_30'


#with initialization
with open(modelFolder+model_name+ '.pkl', "rb") as file:
    model=pickle.load(file)

chanFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/processed/cra_chan/'
allstate = pd.read_csv(chanFolder + model_name+'_allFeaturesMean.csv', index_col=None)

#allstate.loc[:,featureList]=allstate.loc[:,featureList]/allstate.loc[:,featureList].std()
allmeans=getMeanArrayByData(allstate, 13)

makePdf(allmeans,outputFolder,model_name+'_chan',makepdf=False,maxval='Auto')


allstateplot(allmeans,outputFolder,model_name,order=[3,2,12,9,5,1,10,7,6,0,4,11,8])

allstateplot(allmeans,outputFolder,model_name,order=[2,0,6,3,1,5,4])