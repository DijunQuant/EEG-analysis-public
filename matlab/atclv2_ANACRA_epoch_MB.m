function [EEG, report, suffix] = atclv2_ANACRA_epoch_MB(EEG, param, ~)

%% NOTES


%% INITIALIZE VARIABLES
report = {};

try

% Remove 'boundary' event marker
EEG.event = EEG.event(~strcmp({EEG.event.type}, 'boundary'));    
    
    
% How it works:
% Find number of solutions
% Loop through number of solution
%   Find index in EEG.event
%   Find CRA presentation by index-1
%   Set beginning latency as time_CRA-2000ms (time has to be seconds, and lat is in ms)
%   Set ending latency as SOL+500ms
%   Stack latencies - e.g. [5 10; 12 EEG.xmax]
% Use pop_select(EEG, 'time', timeRange) to select the data
% Save them!
      
insIdx = find(contains({EEG.event.type}, param.epEvents{1}));
anaIdx = find(contains({EEG.event.type}, param.epEvents{2}));
toIdx = find(contains({EEG.event.type}, param.epEvents{3}));

selIdx = [insIdx, anaIdx, toIdx];
selIdx = sort(selIdx);
        
% Initialize time windows
corTW = [];
evtList = {};
evtIdx = [];
respLat = -99999;
for i = 1:length(selIdx)

    
    % Check whether the first event is solution trigger
    % If yes, pass
    if (i == 1 && contains(EEG.event(i).type, 'SOL')) ||...
       (i == 1 && contains(EEG.event(i).type, 'timeout'))
        % We don't want this case, so pass
    else
    
    % Check whether event at index-1 is 'CRA' 
    % If yes, store the latencies
        if  (contains(EEG.event(selIdx(i)-1).type, 'CRA')||...
                contains(EEG.event(selIdx(i)-1).type, 'word','IgnoreCase',true))
            
            onsetLat = (EEG.event(selIdx(i)-1).latency*4/1000) - param.begLat;
            
            %YY: check if osetLat overlap with previous respLat
            onsetLat = max(onsetLat,respLat);
            respLat = (EEG.event(selIdx(i)).latency*4/1000) + param.endLat;
            
            corTW = [corTW; onsetLat, respLat];
            evtList = [evtList;{EEG.event(selIdx(i)-1).type,EEG.event(selIdx(i)).type}];
            evtIdx = [evtIdx; selIdx(i)-1 , selIdx(i)];
        else
            %error('Something wrong with the trial arrangement!!!!')
        end
    end
end

EEG.event(~ismember(1:length(EEG.event), evtIdx)) = [];

trimEvtSize = length(EEG.event);

EEG = pop_select(EEG, 'time', corTW);

% Remove events that are not 'boundary' or 'CRA' or 'SOL_..'
EEG.event(strcmp({EEG.event.type}, 'boundary')) = [];

EEG.event = EEG.event(contains({EEG.event.type}, 'CRA') | ...
            contains({EEG.event.type}, 'word','IgnoreCase',true) | ...
            contains({EEG.event.type}, param.epEvents{1}) | ...
            contains({EEG.event.type}, param.epEvents{2}) | ...
            contains({EEG.event.type}, param.epEvents{3}));

trimEvtSize2 = length(EEG.event);

if trimEvtSize ~= trimEvtSize2
    error('number of event doesn''t match!!')
end
              
%YY: turn off
catch what
    keyboard
end
    
%% CONSTRUCT SUFFIX

suffix = ['epoched'];


end