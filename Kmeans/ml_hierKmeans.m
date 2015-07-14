function [IDXs, clustModel] = ml_hierKmeans(X, nBranches, depth, minClustSz)    
% function [IDXs, clustModel] = ml_hierKmeans(X, nBranches, depth,
% minClustSz)    
% Perform hierarchical k-means, output the cluster assignments at all levels.
% Inputs:
%   X: data in ROW format
%   nBranches: branching factor for hierarchical k-means
%   depth: depth of hierarchical k-means
%   minClustSz: minimum size of cluster for any further subspliting.
%       This does not mean there will be no cluster with smaller size than
%       minClusSz. This only means that the cluster with sz < minClustSz will
%       not be divided.
% Outputs:
%   IDXs: cluster indexes of the data points
%       IDXs(:,i) is the indexes for clustering at depth (depth-i+1)^th.
%   clustModel: a tree structure for cluster model.
%       The structure clustModel has the fields: 
%       'nClusts', 'isLeaf', 'C', 'branches'
%       nClusts: depth*1 vector for the numbers of clusters at level 1 to
%       depth.
% See also: ml_hierKmeans_assign
% By: Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 30 June 08 
% Last modified: 19 Aug 2009

options = statset('MaxIter', 200, 'Display', 'off');
n = size(X, 1); % number of data point

if n == 0
    IDXs = [];
    clustModel.isLeaf = 1;
    clustModel.C = [];
    clustModel.nClusts = 0;
    return;
elseif n <= minClustSz || n < nBranches
    IDXs = ones(n, depth);
    clustModel.isLeaf = 1;
    clustModel.C = mean(X, 1);
    clustModel.nClusts = ones(depth, 1);
    return;
else
    warning off;
    [IDX_top, C_top] = kmeans(X, nBranches, 'emptyaction', 'drop', 'options', options);
    warning on;
    
    % some cluters might be dropped
    notDropIdxs = sum(isnan(C_top), 2) == 0; 
    C_top = C_top(notDropIdxs, :);
    nBranches_actual = sum(notDropIdxs);

    clustModel.C = C_top;
    if depth == 1
        IDXs = IDX_top; 
        clustModel.isLeaf = 1;
        clustModel.nClusts = nBranches_actual;
    else        
        IDXs = zeros(n, depth);
        nClusts = zeros(depth-1,1);
        for i=1:nBranches_actual
            IDX_top_i = IDX_top == i;
            [IDX_i, clustModel_i] = ml_hierKmeans(X(IDX_top_i,:), ...
                nBranches, depth - 1, minClustSz);
            nClusts_i = clustModel_i.nClusts;

            if ~isempty(IDX_i)
                IDXs(IDX_top_i,1:end-1) = repmat(nClusts',size(IDX_i,1),1)  + IDX_i;
                nClusts = nClusts + nClusts_i;
            end;

            IDXs(IDX_top_i, end) = i;
            clustModel.isLeaf = 0;
            clustModel.branches{i} = clustModel_i;            
        end;
        clustModel.nClusts = [nClusts; nBranches_actual];
    end
end;    
