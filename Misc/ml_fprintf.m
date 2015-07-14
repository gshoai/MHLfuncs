function printLen = ml_fprintf(numChar2delete, format, varargin)
% Delete a number of character (numChar2delete) before printing
% Return the length of the print message
% 
% This is to replace ml_progressBar, it is more flexible, e.g.,
%   a = 0; n = 5; for i=1:n; a = ml_fprintf(a, 'progress %02d/%02d, %d^2= %d\n', i,n, i, i^2); pause(1); end;
% The use of '\n' does not work on Titan. Use the following instead
%   a = 0; n = 5; for i=1:n; a = ml_fprintf(a, 'progress %02d/%02d, %d^2= %d', i,n, i, i^2); pause(1); end; fprintf('\n');
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Created: 02-Jun-2014
% Last modified: 02-Jun-2014

s = sprintf(format, varargin{:});
printLen = length(s);
delFormat = repmat('\b', 1, numChar2delete);
fprintf([delFormat,s]);