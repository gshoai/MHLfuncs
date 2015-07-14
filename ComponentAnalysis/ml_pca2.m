function [PcaBasis, eigVals, LowDimD, RecD] = ml_pca2(D, k, mode)
% Perform linear PCA. D must be already centralized (mean substract).
% Usage:
%   [PcaBasis] = ml_pca2(D, k, mode)
%   [PcaBasis, eigVals] = ml_pca2(D, k, mode)
%   [PcaBasis, eigVals, LowDimD] = ml_pca2(D, k, mode)
%   [PcaBasis, eigVals, LowDimD, RecD] = ml_pca2(D, k, mode)
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
% See also: ml_pca. This function use svd(D*D') instead of svd(D);
%
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 15 June 07
% Last modified: 17 Oct 08

if nargin < 3
    mode = 0;
end;

n = size(D, 2);
DDt = D*D'/(n-1);
[PcaBasis, eigVals] = ml_pcaCov(DDt, k, mode);
if nargout >=3
    LowDimD = PcaBasis'*D;
end;
if nargout >=4
    RecD = PcaBasis*LowDimD; 
end;
