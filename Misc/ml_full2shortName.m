function [nameOnly, filePath] = ml_full2shortName(fullName)
% From the full path + file name, extract the file name only. This works
% for both Windows and Linux platform.
% Inputs:
%   fullName: full file name.
% Outputs:
%   nameOnly: the name of the file only, everything before the last '\' or
%   '/' is truncated.
% By: Minh Hoai Nguyen
% Created: 19 Feb 07
% Last modified: 2 June 07

bsl = strfind(fullName, '\');
fsl = strfind(fullName, '/');
if isempty(bsl) && isempty(fsl)
    idx = 0;
elseif isempty(bsl)
    idx = fsl(end);
elseif isempty(fsl)
    idx = bsl(end);
else
    idx = max(bsl(end), fsl(end));
end;
nameOnly = fullName((1+ idx):end);
filePath = fullName(1:idx);