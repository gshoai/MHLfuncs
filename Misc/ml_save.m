function ml_save(outFile, varargin)
% ml_save(outFile, varargin)
% ml_save(outFile, var1nameStr, var1, var2nameStr, var2, ...)
%   Assign var1 to var1nameStr, var2 to var2nameStr and save the variables into outFile.
%   This works within parfor and it handles multiple variables
%   E.g., 
%       data2Save = 'This is some string';
%       ml_save('tmp.mat', 'data2Save', data2Save);
%       data2Save2 = 'This is another line';
%       ml_save('tmp.mat', 'data2Save', data2Save, 'renameVar', data2Save2);
%
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Created: 13-Dec-2013
% Last modified: 13-Dec-2013

varNames = cell(1, floor((nargin-1)/2));
for i=1:2:(nargin-1)
    v = genvarname(varargin{i}, who);
    varNames{(i+1)/2} = v;
    eval([v '= varargin{i+1};']);
end;

save(outFile, varNames{:}, '-v7.3');
