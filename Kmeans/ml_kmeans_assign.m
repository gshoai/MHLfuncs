function [idxs, dists] = ml_kmeans_assign(D, Cs, memLimit, verbose)
% Perform k-means assignment
% Fast processing using Matrix multiplication but constraint memory usage
% Inputs:
%   D: d*n data matrix for n data points
%   Cs: d*k centroid matrix for k centroids
%   memLimit: a number, 1 means 1GB, 2 means 2GB
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Created: 15-Jul-2013
% Last modified: 15-Jul-2013

startT = tic;
if ~exist('memLimit', 'var') || isempty(memLimit)
    memLimit = 1;
end;

[d, n] = size(D);
k = size(Cs,2);

% maximum number of elmements for a matrix, assuming double precision (16Bytes)
maxMatrixSize = memLimit*10^9/16; 

batchSize = floor(maxMatrixSize/k);

if batchSize < 1
    batchSize = 1;
end;

nBatch = ceil(n/batchSize);

[idxs, dists] = deal(zeros(n, 1));

c2 = sum(Cs.^2, 1)';

for i=1:nBatch    
    idxs_i = (1+(i-1)*batchSize):min(i*batchSize, n);    
    dist_i = 2*Cs'*D(:, idxs_i);    
    dist_i = repmat(c2, 1, size(dist_i,2)) - dist_i; % ignore D.^2, because we don't need
    [dists(idxs_i), idxs(idxs_i)] = min(dist_i, [], 1);
end;

dists = dists + sum(D.^2, 1)'; % add the offset

if exist('verbose', 'var') && verbose
    fprintf('n: %d, d: %d, k: %d, batchSz: %d, nBatch: %d, etime: %.1fs\n', ...
        n, d, k, batchSize, nBatch, toc(startT));
end;
