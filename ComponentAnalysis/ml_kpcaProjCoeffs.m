function [Alphas, betas, const] = ml_kpcaProjCoeffs(Kernel, k, mode) 
% function [Alphas, betas, const] = ml_kpcaProjCoeffs(Kernel, k, mode)
% Suppose E is the reconstruction error of a data point phi(d) in the PCs
% of principle subspace in the feature space obtained by KPCA. Then
% E = k(d,d) -sum(Alphas_ij*k(x_i,d)*k(x_j,d)) -sum(betas_i*k(x_i,d)) +const
% This function compute Alphas and betas and const.
%
% Inputs:
%   Kernel: The n*n kernel matrix which is note yet centralized.
%   mode, k: if mode is 0 (default), then k is the no of principle components
%            if mode is 1, then k is the energy (value from 0 to 1) that 
%            KPCA should preserve.
% Outputs:
%   Alphas: n*n matrix
%   betas: n*1 matrix, described above.
%   const: a constant.
% Other notes: The derivation of this function is given in page 55-59 of 
% Research Note, notebook 2, date 8 May 07.
% By Minh Hoai Nguyen
% Last modified: 8 May 07.

n = size(Kernel,1);

% Center the kernel
CenK = ml_centralizeKernel(Kernel);
[Coeffs, eigValues] = ml_kpca(CenK, k, mode);


% C is matrix such that C*C' = I, Kernel*C' = C'*S, S is diagonal matrix.
C = Coeffs./repmat(sqrt(sum(Coeffs.*Coeffs,2)), 1, size(Coeffs,2));

%diagonal of the S matrix, Kernel*C' = C'*S
diagS = eigValues*n;

% A fast way of computing M = C'*inv(S)*C
M = (C'./repmat(diagS', n,1))*C;

mM = mean(M,2); % Mi in the notebook notation.
mmM = mean(mM,1); % Moo in notebook notation.
mK = mean(Kernel,2);
mmK = mean(mK); % u'*u in notebook notation.

Alphas = M - repmat(mM, 1, n) - repmat(mM',n,1) + mmM;
betas = 2*(-M*mK + n*mmK*mM + mM'*mK - n*mmM*mmK + 1/n);

% Compute const, here we use a trick that the reconstruction error of
% the mean u = mean(K,2) is 0.
const = mK'*Alphas*mK + betas'*mK - mmK;





