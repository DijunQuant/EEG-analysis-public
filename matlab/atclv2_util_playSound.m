function atclv2_util_playSound(names,vol,varargin)
% Plays a sound. Optional "1" in second argument enables playblocking so function
% does not exit until the sound is complete (useful to prevent sounds
% overlapping, but best used on only short sounds or it's annoying to the user)


if vol

% hacky method of getting sound path based on the length of this
% mfilename...
pd = atclv2_util_pathType();
soundPath = mfilename('fullpath');
soundPath = [soundPath(1:end-length(mfilename)), 'atclv2_sounds', pd];

% if given a cell of filenames, randomly select one
if iscell(names)
    soundFileName = names{randi(numel(names))};
else
    soundFileName = names;
end

    try % sound sometimes fails on different systems, so put it in a try statement
        % read the sound
        [y,Fs] = audioread([soundPath, soundFileName]);
        y = y*(vol/100);
        if ~isempty(varargin) % given second argument, use playblocking
            player = audioplayer(y, Fs);
            playblocking(player)
        else % otherwise don't
            % "sound" function continues to execute even after function
            % ends...not sure why audioplayer doesn't do this but sound works
            % so using it
            sound(y,Fs);
        end

    catch
        fprintf(['\n     AUTOCLAVE2 Warning: failed to play sound ', soundFileName,'\n\n']);
    end
end

