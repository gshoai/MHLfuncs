function IDXs = ml_hierKmeans_assign(X, clustModel)    
% function IDXs = ml_hierKmeans_assign(X, clustModel)
% Compute the cluster indexes for hierarchical kmeans.
% Inputs:
%   X: data in ROW format
%   clustModel: a tree structure for cluster model.
%       The structure clustModel has the fields: 
%       'nClusts', 'isLeaf', 'C', 'branches'
%       nClusts: depth*1 vector for the numbers of clusters at level 1 to
%       depth.
%       This is typically constructed using ml_hierKmeans.
% Outputs:
%   IDXs: cluster indexes of the data points
%       IDXs(:,i) is the indexes for clustering at depth (depth-i+1)^th.
%
% See also: ml_hierKmeans.m
% By: Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 30 June 08 
% Last modified: 11 Nov 2008
% Modified: 14 Nov 09: fix a big bug

depth = length(clustModel.nClusts);
if isempty(X)
    IDXs = zeros(0,1);
    return;
elseif isempty(clustModel.C)
    IDXs = ones(size(X, 1), depth);
    return;
end;

Dist = ml_sqrDist(X', clustModel.C');
[dc, IDX_top] = min(Dist, [], 2);    

if clustModel.isLeaf
    IDXs = repmat(IDX_top, 1, depth);
else
    IDXs = zeros(size(X,1), length(clustModel.nClusts));
    nClusts = zeros(length(clustModel.nClusts) - 1,1);

    for i=1:length(clustModel.branches)
        IDX_top_i = IDX_top == i;
        IDX_i = ml_hierKmeans_assign(X(IDX_top_i, :), clustModel.branches{i});
        nClusts_i = clustModel.branches{i}.nClusts;
        
        if ~isempty(IDX_i)
            IDXs(IDX_top_i,1:end-1) = repmat(nClusts',size(IDX_i,1),1)  + IDX_i;
        end;
        nClusts = nClusts + nClusts_i;
        IDXs(IDX_top_i, end) = i;
    end;
end
    
