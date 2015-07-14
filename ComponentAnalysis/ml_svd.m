function [U,S,V] = ml_svd(X, tol)
% Doing SVD, sigular values which are too small are zeroed out.
% Inputs:
%   X: input matrix
%   tol: this is threshold of "small" of singular values. If tol is -1, this function
%       will return U,S,V as the output of normal Matlab SVD routine.
% Outputs:
%   U,S,V: decomposition of X. This function first calls [U,S,V] = svd(X, 'econ').
%   This function resizes S by removing sigular values that are smaller than tol. 
%   This function also removes columns of U, rows of V that correspond to small singular values.
% By: Minh Hoai Nguyen
% Date: 05 Sep 07

[U,S,V] = svd(X, 'econ');
if tol > 0
    diagS = diag(S);
    bigIdxs = diagS > tol;
    S = diag(diagS(bigIdxs));
    U = U(:, bigIdxs);
    V = V(bigIdxs,:);    
end;