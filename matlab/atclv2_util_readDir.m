function [filePaths, fileDirs, fileNames, fileExtns, dirRead] = atclv2_util_readDir(inPath,fileType)
%readDir Summary of this function goes here
%   Detailed explanation goes here

dirRead = rdir([inPath,fileType]);

%dirFiles (list of directories in dir2Read)
%remove directories
dirRead([dirRead.isdir]) = [];

%dirFileNames (human readable list of directory names)
filePaths = {dirRead.name}';

[fileDirs,fileNames,fileExtns] = cellfun(@fileparts,filePaths,'UniformOutput', false);

fileDirs=cellfun(@(x) x(length(inPath)+1:end),fileDirs,'UniformOutput',false);

end

