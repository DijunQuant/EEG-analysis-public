import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import scipy.interpolate
import glob
import random
import matplotlib
#this must be the same channel list in exact order as data generation in Matlab
#channellist=['FP1','FP2','F7','F3','FZ','F4','F8','T7','C3','CZ','C4','T8','P7','P3','PZ','P4','P8','O1','O2']
#channellist correspond to icaweight
channellist=['T7','C3','F7','F3','FP1','FZ','FP2','F4','F8','CZ','C4','T8','P7','P3','O1','PZ','O2','P4','P8']
channellist=['T7','C3','FT9','FT7','F7','F3','F9','AF3','Fp1','Fpz',\
    'AFz','Fz','FCz','Fp2','AF4','F4','F10','F8','FT8','FT10',\
    'Cz','C4','T8','TP9','TP7','P9','P7','P3','O1','Iz',\
    'Oz','POz','Pz','CPz','O2','P4','P8','P10','TP8','TP10',\
             'O9','PO9','PO7','PO3','PO355','P1','P5','CP5','CP3','CP1',\
             'CP155','C1','C5','FC5','FC3','FC1','C155','F1','F5','AF7',
             'AF355','AF455','F155','F255','AF8','F2','C255','C2','CP255','CP2',\
             'P2','P6','PO455','PO4','PO8','O10','PO10','F6','FC6','FC4','FC2','C6','CP6','CP4']

includeSources=[1,2,3,4,5,6,7,8,9,10,12,13,14,15,16,18,19] #in matlab system starts from 1, #for 10/22 data
includeSources=[1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 13, 14, 15, 16, 17, 19, 20, 23, 24, 25, 26, 28, 29, 30, 31, 32]#84chan no pca version 3/22 data
includeSources=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19] #84chan 20 PCA
#in matlab system starts from 1, #for 3/21/2022 data
#allSources=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
allSources=list(range(1,85))
includeFreqs = [4.3,8.3,10.7,14.6,19.2,26.0,35.1,43.2]

def removeOutlier(data,mean,sd,mult = 5):
    return np.tanh((data-mean)/sd/mult)*sd*mult+mean
def preprocess(file,includeComps):
    df = pd.read_csv(file, index_col=None, header=None)
    allData = df.iloc[2:, :]
    allData=allData[allData[0].astype(int).isin(includeComps)]
    allData= allData[allData[1].isin(includeFreqs)]
    allData.insert(0, 'featLbl', allData[[0,1]].astype(str).agg(','.join, axis=1), True)
    allData = allData.set_index('featLbl').drop(columns=[0,1]).T
    featLbl=allData.columns
    allData.insert(0,'timeToResp',df.iloc[0][2:].values,True)
    allData.insert(0, 'timeToStim', df.iloc[1][2:].values, True)
    return allData,featLbl

#process all files
def calcAndSaveNormFeature(subid,prefix,sourceFolder,outputFolder,includeComps=includeSources):
    dataForSub=pd.DataFrame()
    for file in glob.glob(sourceFolder +subid + '/'+prefix+subid+'*'):
        filename=file.split('/')[-1]
        type = filename.split('_')[2]
        #if type=='TO':continue
        allData,featLbl=preprocess(file,includeComps)
        allData['filename']=filename
        dataForSub = pd.concat([dataForSub,allData],ignore_index=True)
    #solvedN=len(dataForSub['filename'].unique())
    #toTrials=glob.glob(sourceFolder +subid + '/'+prefix+subid+'_TO_*')
    #for file in random.sample(toTrials,min(solvedN,len(toTrials))):
    #    filename=file.split('/')[-1]
    #    allData,featLbl=preprocess(file)
    #    allData['filename']=filename
    #    dataForSub = pd.concat([dataForSub,allData],ignore_index=True)
    mean=dataForSub[featLbl].mean()
    sd=dataForSub[featLbl].std()
    nData=removeOutlier(dataForSub[featLbl],mean,sd)
    dataForSub[featLbl]=(nData-nData.mean())/nData.std()
    if not os.path.exists(outputFolder+subid+'/'):
        os.makedirs(outputFolder+subid+'/')
    for file,df in dataForSub.groupby('filename'):
        df.drop(columns='filename').to_csv(outputFolder+subid+'/'+file,index=False)
    return nData.mean(),nData.std()

def plotContour(x,y,z,ax,fig,makebar,maxval=2):
    # some parameters
    N = 300             # number of points for interpolation
    xy_center = [0,0]   # center of the plot
    radius = 1          # radius
    xi = np.linspace(min(x), max(x), N)
    yi = np.linspace(min(y), max(y), N)
    #xi = np.linspace(-1 * maxval, maxval, N)
    #yi = np.linspace(-1 * maxval, maxval, N)
    zi = scipy.interpolate.griddata((x, y), z, (xi[None,:], yi[:,None]), method='cubic')
    # set points > radius to not-a-number. They will not be plotted.
    # the dr/2 makes the edges a bit smoother
    dr = xi[1] - xi[0]
    #for i in range(N):
    #    for j in range(N):
    #        r = np.sqrt((xi[i] - xy_center[0])**2 + (yi[j] - xy_center[1])**2)
    #        if (r - dr/2) > radius:
    #            zi[j,i] = "nan"
    # make figure
    #fig = plt.figure()
    # set aspect = 1 to make it a circle
    #ax = fig.add_subplot(111, aspect = 1)
    # use different number of levels for the fill and the lines

    CS = ax.contourf(xi, yi, zi, levels=np.linspace(-1*maxval,maxval,100), cmap=plt.cm.jet, zorder=1,
                     vmin=-1*maxval, vmax=maxval,extend='both')
    ax.contour(xi, yi, zi, 15, colors = "grey", zorder = 2)
    # make a color bar
    if makebar:
        cbar = fig.colorbar(CS, ax=ax,ticks=np.linspace(-1*maxval,maxval,11))
    # add the data points
    # I guess there are no data points outside the head...
    ax.scatter(x, y, marker = 'o', c = 'b', s = 2, zorder = 3)

    # draw a circle
    # change the linewidth to hide the
    circle = matplotlib.patches.Circle(xy = xy_center, radius = radius, edgecolor = "k", facecolor = "none")
    ax.add_patch(circle)

    # make the axis invisible
    for loc, spine in ax.spines.items():
        # use ax.spines.items() in Python 3
        spine.set_linewidth(0)
    # remove the ticks
    ax.set_xticks([])
    ax.set_yticks([])

    # Add some body parts. Hide unwanted parts by setting the zorder low
    # add two ears
    circle = matplotlib.patches.Ellipse(xy = [-1,0], width = 0.25, height = .5, angle = 0, edgecolor = "k", facecolor = "w", zorder = 0)
    ax.add_patch(circle)
    circle = matplotlib.patches.Ellipse(xy = [1,0], width = 0.25, height = .5, angle = 0, edgecolor = "k", facecolor = "w", zorder = 0)
    ax.add_patch(circle)
    # add a nose
    xy = [[-.25,.75], [0,1.15],[.25,.75]]
    polygon = matplotlib.patches.Polygon(xy = xy, edgecolor = "k", facecolor = "w", zorder = 0)
    ax.add_patch(polygon)

    # set axes limits
    ax.set_xlim(-1.2, 1.2)
    ax.set_ylim(-1.25, 1.25)
    return CS
    #plt.tight_layout()
    #plt.show()

#stepsize 40ms
def computeStats(df,stepsize=50):
    zscore=pd.DataFrame()
    duration=pd.DataFrame()
    duration_se=pd.DataFrame()
    ndf={}
    std={}
    n=len(df['state'].unique())
    for style in ['INS','ANA','TO']:
        tmp=df[df['style']==style]
        statecnt=tmp.groupby('state').count()[1]
        duration.loc[:,style]=(statecnt/statecnt.sum())
        ndf[style]=len(tmp['id'].unique())
        cntbytrial=pd.Series(0,pd.MultiIndex.from_product([tmp['id'].unique(),range(n)], names=['id', 'state']))
        cntbytrial=pd.DataFrame({'null':cntbytrial,'cnt':tmp.groupby(['id','state']).count()[1]}).fillna(0)['cnt']
        cntbytrial=(cntbytrial/cntbytrial.groupby(level=0).sum())
        std[style]=cntbytrial.groupby(level=1).std()
        duration_se.loc[:,style]=std[style]/np.sqrt(ndf[style])
    se = np.sqrt(std['INS']*std['INS']/ndf['INS']+std['ANA']*std['ANA']/ndf['ANA'])
    zscore['proportion']=(duration['INS']-duration['ANA'])/se
    duration=duration.stack()
    duration_se=duration_se.stack()
    visitlen=pd.DataFrame()
    visitlen_se=pd.DataFrame()
    for style in ['INS','ANA','TO']:
        states=df[df['style']==style].groupby(['state','chgflag']).count()[1]
        visitlen.loc[:,style]=stepsize*states.unstack(level=1).mean(axis=1)
        ndf[style]=states.groupby('state').count()
        std[style]=stepsize*states.unstack(level=1).std(axis=1)
        visitlen_se.loc[:,style]=std[style]/np.sqrt(ndf[style])
    se = np.sqrt(std['INS']**2/ndf['INS']+std['ANA']**2/ndf['ANA'])
    zscore['visitlen']=(visitlen['INS']-visitlen['ANA'])/se
    visitlen=visitlen.stack()
    visitlen_se=visitlen_se.stack()
    visitfreq=pd.DataFrame()
    visitfreq_se=pd.DataFrame()
    for style in ['INS','ANA','TO']:
        states=df[df['style']==style].groupby(['state','chgflag']).count()[1]
        total=states.sum()

        visitfreq.loc[:,style]=[(len(states.loc[i])/total if i in states.keys() else 0) for i in range (n)]
        ndf[style]=total
        visitfreq_se.loc[:,style]=np.sqrt(visitfreq[style]*(1-visitfreq[style])/ndf[style])
    p=(visitfreq['INS']*ndf['INS']+visitfreq['ANA']*ndf['ANA'])/(ndf['INS']+ndf['ANA'])
    se = np.sqrt(p * ( 1 - p ) * [ (1/ndf['INS']) + (1/ndf['ANA']) ])
    zscore['visitfreq']=(visitfreq['INS']-visitfreq['ANA'])/se
    visitfreq=visitfreq.stack()
    visitfreq_se=visitfreq_se.stack()
    return pd.DataFrame({'proportion':duration,'visitlen':visitlen,'visitfreq':visitfreq}),\
            pd.DataFrame({'proportion':duration_se,'visitlen':visitlen_se,'visitfreq':visitfreq_se}),zscore
#subid='102'
#prefix='log_'
#sourceFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/export/'
#outputFolder = '/Users/yyu/Documents/Psychology/insight/EEG_data/processed/'

#dataMean,dataStd = calcAndSaveNormFeature(subid,prefix,sourceFolder,outputFolder)