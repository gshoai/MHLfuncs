function varargout = ml_load(dataFile, varargin)
% varargout = ml_load(dataFile, varargin)
% [newName1, newName2, ...] = ml_load(dataFile, 'saveName1', 'saveName2', ...);
% Load variables 'saveName1', ... in dataFile and assign new names. 
%   E.g., 
%       myStr = 'SaveAndWillLoad'; myStr2 = 'SaveButNotLoad'; myNum = '42';
%       save('tmp.mat', 'myStr', 'myStr2', 'myNum);
%       [saveMessage, saveNum] = ml_load('tmp.mat', 'myStr', 'myNum');
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Created: 28-Apr-2013
% Last modified: 28-Apr-2013

A = load(dataFile, varargin{:});

if nargout ~= nargin - 1
    error('Expected number of outputs is different from number of loaded variables');
end;

varargout = cell(1, nargout);
for i=1:nargout
    varargout{i} = A.(varargin{i});
end;
