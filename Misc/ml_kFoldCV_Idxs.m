function idxss = ml_kFoldCV_Idxs(n, k, shldRandom)
% idxss = ml_kFoldCV_Idxs(n, k, shldRandom)
% Get the indexes of k-fold Cross Validation.
% Suppose your training data has n examples and you want to perform k-fold CV
% You need to divide the training data into k equal partitions (as equal as possible).
% This function provides indexes for the partitions.
% Inputs:
%   n: the number of training examples.
%   k: the number of folds of k-fold CVs.
%   shldRandom: should we shuffle the indexes from 1:n randomly before dividing into partions?
%       The default value is 1.
% Outputs:
%   idxss: a cell(1,k) strucutre, idxss{i} is a list of indexes for test data of the i^th fold.
% By: Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 11 July 07.

if ~exist('shldRandom', 'var') || isempty(shldRandom)
    shldRandom = 1;
end;

if shldRandom
    suffledIdxs = randperm(n);
else
    suffledIdxs = 1:n;
end;

q = floor(n/k);
r = n - k*q;
idxss = cell(1,k);
for i=1:k
    if i<=r
        idxss{i} = suffledIdxs(1+(i-1)*(q+1):i*(q+1));
    else
        idxss{i} = suffledIdxs((1+r+(i-1)*q):(r+i*q));
    end;
end;

