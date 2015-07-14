function ml_matrix2latex(A, cellFormat, lineFormat, labels)
% function ml_dispMatrix(A, format)
% Print a matrix in Latex format
% Inputs:
%   A: the matrix to display.
%   cellFormat: the format of the fprintf which governs how much space given to each number in the matrix. 
%       default value of 'format' is '%5.2f';
%   lineFormat: the format of the line. This has priority over cellFormat.
%       If lineFormat is empty or not set, use cellFormat
%   
% Outputs:
%   No output, this print to the standard output.
% By Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 1 Mar 2011
% Last modified: 14 Jun 2014


if ~exist('cellFormat', 'var') 
    cellFormat = ('& %5.2f');
end;

if ~exist('lineFormat', 'var') || isempty(lineFormat)
    lineFormat = repmat(cellFormat, 1, size(A,2));
end;

lbLens = length(labels);
for i=1:length(labels);
    lbLens(i) = length(labels{i});
end;
maxLen = max(lbLens);
labelFormat = sprintf('%%-%ds', maxLen);

for i=1:size(A,1)
    fprintf(labelFormat, labels{i});
    fprintf(lineFormat, A(i,:));
    fprintf('\\\\  \n');
end;
