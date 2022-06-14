# EEG-analysis-public

This pipeline process the raw EEG data per subject in .set, .fdt, preprocess and spectral transform with Matlab script. Then conducted modeling fitting and analysis with Python scripts. 


## 1.	Matlab Preprocessing
 Main script: yy_auto_process.m
 ### 1.1.	run with steps to output feature data per trial by sources 
 includeSteps={'pre','asr','interp','rmEvt','epoch','ica','mara','stratify','gICA','wavelet'};
### 1.2.	run with steps run with steps to output feature data per trial by channels 
includeSteps={'wavelet_chan'};
## 2.	Python Processing
### 2.1.	Normalized power envelope by source per individual, output centered feature data (data_process.py)
### 2.2.	Fit HMM with full mean and covariance matrix (hmm.py) from 2.1
### 2.3.	Normalized power envelope by channel per individual, output centered channel data (data_process.py)
### 2.4.	Infer hidden states using decoded trials (from 2.2) and the processed power envelopes by channel (from 2.3). Generate all feature mean by state.(infer_state.py).
### 2.5.	Make topography plots for state and frequency from 2.4. (makeplots_bydata.py)
### 2.6.	Further analysis with hmm_analysis_13.ipynb

