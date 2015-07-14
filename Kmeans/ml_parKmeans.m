function [Cs, idxs] = ml_parKmeans(D, k)
% Parallel k-means, faster than ml_parKmeans_old and vl_kmeans
% Inputs:
%   D: d*n matrix, column major
%   k: number of cluster
% Outputs:
%   Cs: d*k matrix for k centroids
%   idxs: cluster assignment
% Some timing info for [d,n] = size(D), D is single precision, for this code
%   For d=30,  n=1.6M, k=4K, #nodes=38, it takes 18mins
%   For d=192, n=1.6M, k=4K, #nodes=38, it takes 22mins
%   For d=216, n=1.6M, k=4K, #nodes=38, it takes 30mins

% Some timing info for [d,n] = size(D), D is single precision, for ml_parKmeans_old
%   For d=30,  n=1.6M, k=4K, #nodes=60, it takes 45mins
%   For d=192, n=1.6M, k=4K, #nodes=60, it takes 90mins
%   For d=216, n=1.6M, k=4K, #nodes=60, it takes 135mins
% Comparison with vl_kmeans on a single machine
%   For d=30,  n=1.6M, k=4K, it takes 3.5h
%   For d=192, n=1.6M, k=4K, it takes 12.5h
%   For d=216, n=1.6M, k=4K, it takes 13.5h
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Created: 14-Jul-2013
% Last modified: 23-Jul-2013

nMaxIter = 100;
tol = 1e-4;
n = size(D, 2);


startT = tic;
Cs = kmeanPPinit(D, k);
fprintf('k-means++ init takes %.1fs\n', toc(startT));

energies = zeros(1, nMaxIter);
nWorker = matlabpool('size');
nWorker = max(nWorker, 1);
batchIdxs = ml_kFoldCV_Idxs(n, nWorker, 0);
[batchDs, bMinVals, bAssigns] = deal(cell(1, nWorker));
for j=1:nWorker
    batchDs{j} = D(:, batchIdxs{j});
end;
save('~/Study/Libs/MyGradFuncs/Kmeans/nWorker.mat', 'nWorker');

for iter=1:nMaxIter
    fprintf('iter %d/%d, ', iter, nMaxIter);
    
    startT_i1 = tic;
    parfor j=1:nWorker
        [bAssigns{j}, bMinVals{j}] = ml_kmeans_assign(batchDs{j}, Cs, 0.5);
    end;
    minVals = cat(1, bMinVals{:});
    idxs = cat(1, bAssigns{:});    
    energies(iter) = sum(minVals);
    endT_i1 = toc(startT_i1);
    
    startT_i2 = tic;    
    % Update the centroids, not using parfor is fast enough
    % Using parfor might take lot of time to transmit the matrix D
    for u=1:k
        idxs_u = idxs == u;
        Cs(:,u) = mean(D(:, idxs_u), 2);        
    end;
    endT_i2 = toc(startT_i2);
    
    fprintf('energy: %g, up_assgn_time: %.1f, up_cen_time: %.1f, elapse-time: %.1f\n', ...
        energies(iter), endT_i1, endT_i2, toc(startT));
    
    if iter > 1
        if (energies(iter-1) - energies(iter)) < tol*energies(iter-1);
            break;
        end
    end
end;
fprintf('Total iter %d, energy: %g, etime: %.1f\n', iter, energies(iter), toc(startT));


% Kmeans++ inialization:
function Cs = kmeanPPinit(D, k)
    [d, n] = size(D);
    Cs = zeros(d, k); 
    
    % pick the first one randomly
    idx = randi(n, 1);
    Cs(:,1) = D(:,idx);    
    probVec = inf(1, n);
    
    d2 = sum(D.^2, 1);
    for i=2:k
        ml_progressBar(i, k, 'Initialization with kmeans++');
        
        dist = sum(Cs(:,i-1).^2) - 2*Cs(:,i-1)'*D + d2; 
        probVec = min(probVec, dist);
        
        idx = importanceSample(probVec); % sample a point
        Cs(:,i) = D(:,idx);
    end


% Given a vector of non-negative weights
% sample an index base on the value of the weight (higher means more probable)
function idx = importanceSample(vec)
    cs = cumsum(vec);
    val = rand*cs(end);
    idx = find(cs > val, 1, 'first');
    if isempty(idx)
        idx = length(vec);
    end
    

