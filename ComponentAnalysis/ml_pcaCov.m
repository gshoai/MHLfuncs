function [PcaBasis, eigVals] = ml_pcaCov(Cov, k, mode)
% Perform linear PCA. Cov is covariance of data. 
% Usage:
%   [PcaBasis] = ml_pcaCov(Cov, k, mode)
%   [PcaBasis, eigVals] = ml_pcaCov(Cov, k, mode)
% Inputs:
%   Cov: the n*n covariance matrix or D*D'/(n-1). 
%       The function does not require D is 
%       is centralized but D should be centralized. 
%   mode, k: if mode is 0 (default), then k is the no of principle components
%            if mode is 1, then k is the energy (value from 0 to 1) that 
%            PCA should preserve.   
% Outputs:
%   PcaBasis: d*k matrix, basis (eigenfaces) of Pca.
%   eigVals: eigenvalues of (positive, energy) of the covariance matrix.
% See also: ml_pca, ml_pca2. 
%
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 10 Sep 07
% Last modified: 17 Oct 08

tol = 1e-10;
if nargin < 3
    mode = 0;
end;

[U,S,V] = svd(Cov, 'econ');
dS = diag(S);

if mode == 1    
    cumEnergy = cumsum(dS)/sum(dS);
    k = sum(cumEnergy < k) +1;    
    k = min(k, sum(dS > tol));
end;

PcaBasis = U(:,1:k);
if nargout >= 2
    eigVals = dS(1:k);
end;

fprintf('# principle components: %d\n', k);
