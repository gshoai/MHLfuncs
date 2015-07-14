function [PcaBasis, eigVals, LowDimD, RecD] = ml_pca(D, k, mode, shldDisp)
% Perform linear PCA. D must be already centralized (mean substract).
% Usage:
%   [PcaBasis] = ml_pca(D, k, mode)
%   [PcaBasis, eigVals] = ml_pca(D, k, mode)
%   [PcaBasis, eigVals, LowDimD] = ml_pca(D, k, mode)
%   [PcaBasis, eigVals, LowDimD, RecD] = ml_pca(D, k, mode)
% Inputs:
%   D: the d*n data matrix.
%   mode, k: if mode is 0 (default), then k is the no of principle components
%            if mode is 1, then k is the energy (value from 0 to 1) that 
%            PCA should preserve.   
% Outputs:
%   PcaBasis: d*k matrix, basis (eigenfaces) of Pca.
%   eigVals: eigenvalues of (positive, energy) of the covariance matrix.
%       The covaraiance matrix is D*D'/(n-1).
%   LowDimD: k*n, each column is a low-dim representation of original data.
%   RecD: Reconstructed data.
%
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 23 May 07
% Last modified: 17 Oct 08

% persistent PcaBasis2
% if ~isempty(PcaBasis2)
%     PcaBasis = PcaBasis2;
% else   
       
tol = 1e-10;
if nargin < 3
    mode = 0;  
end;

n = size(D, 2);
[U,S,V] = svd(D, 'econ'); 
dS = diag(S); 
dS2 = dS.^2;

if mode == 1    
    cumEnergy = cumsum(dS2)/sum(dS2);
    k = sum(cumEnergy < k) +1;    
    k = min(k, sum(dS2 > tol));
end;

PcaBasis = U(:,1:k);
if nargout >= 2
    eigVals = dS2(1:k)/(n-1);
end;
if nargout >=3
    LowDimD = PcaBasis'*D;
end;
if nargout >=4
    RecD = PcaBasis*LowDimD; 
end;

if ~exist('shldDisp', 'var') || isempty(shldDisp)
    shldDisp = 1;
end;
if shldDisp
    fprintf('# principle components: %d\n', k);
end;
    
%     PcaBasis2 = PcaBasis;
% end;


