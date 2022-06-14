function pd = atclv2_util_pathType()
%atclv2_util_pathType returns the proper path delimiter
%   returns the proper path delimiter for the system (unix / windows)

if isunix
    pd = '/';
else
    pd = '\';
end

end

