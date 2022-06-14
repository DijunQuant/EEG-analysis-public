function [EEG, report, suffix] = atclv2_ANACRA_rmShrtEvents(EEG, param, ~)

try


% Now eleminate trials with response time less than param.TW 

evRmInd = [];
count = 0;

for i = 1:length(EEG.event)
    
    if i ~= 1
        
        if any(strcmp(param.eventList, EEG.event(i).type))
            % Stack of if statement was used instead of && because latter involves selection of 3 letters
            % Which is not applicable to events 'X'
            if contains(EEG.event(i-1).type, 'word', 'IgnoreCase', 1) || contains(EEG.event(i-1).type, 'CRA', 'IgnoreCase', 1)     
                RT = EEG.times(round(EEG.event(i).latency)) - EEG.times(round(EEG.event(i-1).latency));
                                
                if RT < param.TW
                    evRmInd = [evRmInd; i];
                    count = count+1;
                    fprintf(['Deleting event ' num2str(i) ' '' EEG.event(i).type '' that took ' num2str(RT) ' seconds\n'])
                end
            end
        end
    end
    
end

a=1; %just to set breakpoint

EEG.event(evRmInd) = [];


if count > 0
    fprintf([count ' events deleted\n'])
else
        fprintf('No event deleted\n')
end



catch whatDhec
keyboard

end



%% END FUNCTION AND RETURN TO MASTERSELECTOR
report = {};
suffix = ['rmShrt'];


end