function [z, finalW] = ml_robustPCAFit(D, x, energy, initW, nMaxIters, nMinIters, C, tol)
% [z, finalW] = ml_robustPCAFit(D, x, energy, initW, nMaxIters, nMinIters, C, tol)
% robust fitting a data point to a subspace.
% Inputs:
%   D: the data in column vectors that forms the subspace.
%   x: a column vector for the data point that we want to fit robustly into the subspace.
%   energy: how much energy preserved for PCA subspace.
%   initW: a vector of the same size with x, the initial weight for importance of elements
%       of x. If initW(i) is low, it means that x(i) is a outlier element of x. This could
%       be []. The default value of initW is a vector of all 1.
%   nMaxIters, nMinIters: the maximum and minimum numbers of iterations to run.
%   C: the constant that constrol the update of the sigma of the robust function.
%       The robust function d^2/(d^2 + sigma^2). The update rule for sigma is: 
%       sigma = C*median(errorVector); The default value is 1.4826.
%   tol: the tolarance for stoping condition.
% Outpus:
%   z: the robust reconstruction of x in the subspace.
%   finalW: the final weight vector.
% By: Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 4 July 2007.

if ~exist('initW', 'var') || isempty(initW)
    W = ones(size(x)); %weight vector.
else
    W = initW;
end;

if ~exist('nMaxIters', 'var') || isempty(nMaxIters)
    nMaxIters = 40;
end;

if ~exist('nMinIters', 'var') || isempty(nMinIters)
    nMinIters = 5;
end;

if ~exist('C', 'var') || isempty(C)
    C = 1.4826;
end;


n = size(D,2);
mD = mean(D, 2);
D = D - repmat(mD, 1, n);
B = ml_pca(D, energy, 1); %PCA basis
clear D;
x = x - mD;
z = x; 

if ~exist('tol', 'var') || isempty(tol)
	tol = numel(x)*max(abs(max(mD)), abs(min(mD)))*0.0001;    
end;

for i=1:nMaxIters
    clear WB;
    WB = B.*repmat(W, 1, size(B,2));
    new_z = B*(inv(WB'*WB)*(WB'*(W.*x)));
    
    if (i > nMinIters) && (sum(abs(new_z - z)) < tol), break; end;
    z = new_z;
    dzx2 = (z - x).*(z -x);
    sqrSigma = max(C*C*median(dzx2), eps); % prevent sigma to be zero.
%     sigma = max(ml_nth(abs(dzx), 0.95, 1), eps);
    
    W = sqrSigma./((dzx2 + sqrSigma).^2);   
%     fprintf('  Iter %d, sqrSigma = %g\n', i, sqrSigma);
end;
fprintf('ml_robustLinearFit: number of iter is %d\n', i);
z = z + mD;
finalW = W;
