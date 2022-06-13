
import pandas as pd

import utility

includeID=['102','103','104','106','107','110','111','112','114','115','117','118','120',
    '123','124','126','203','206','208','209','210','211','212','215','216','217','218','219','220','221','222','223','224','225']
prefix='log_'
sourceFolder='/Users/yyu/Documents/Psychology/insight/EEG_data/export/'
outputFolder = '/Users/yyu/Documents/Psychology/insight/EEG_data/processed/'

#for remote

includComps=utility.includeSources


#for remote by channel
#includComps=utility.allSources
#outputFolder = '/projects/p31274/Drexel/processed/cra_chan/'
#sourceFolder = '/projects/p31274/Drexel/export/cra_chan/'


allmeans=pd.DataFrame()
allsds=pd.DataFrame()
for subid in includeID:
    dataMean,dataStd = utility.calcAndSaveNormFeature(subid,prefix,sourceFolder,outputFolder,includeComps=includComps)
    allmeans=pd.concat([allmeans,pd.DataFrame({subid:dataMean}).T])
    allsds = pd.concat([allsds, pd.DataFrame({subid:dataStd}).T])

allmeans.to_csv(outputFolder+'allmeans.csv')
allsds.to_csv(outputFolder+'allsds.csv')