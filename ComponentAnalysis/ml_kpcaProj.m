function [LowerDimData, sqrErrs] = ml_kpcaProj(K, PrinCompCoeffs, sqrLengths)
% Project data in feature space into lower dimensional space.
% Make sure the kernel K is centralized w.r.t the mean of training data.
% Usages:
%   [LowerDimData, sqrErrs] = m_kpcaProj(K, PrinCompCoeffs)
%   [LowerDimData, sqrErrs] = m_kpcaProj(K, PrinCompCoeffs, sqrLengths)
% Inputs:
%   K: the m*n kernel matrix, K(i,j) = k(x_i,y_j) where k is kernel
%       function, x_i is the i_th training instance and y_j is the j_th 
%       testing instance. There are m and n training and testing instances
%       respectively.
%   PrinCompCoeffs: suppose the subspace has k dimensions, then PrinCompCoeffs 
%       is a k*m matrix, each row is coeffs of a principle component.
%   sqrLengths: the 1*n vector of lengths of y_i in feature space, k(y_i, y_i).
% Outputs:
%   LowerDimData: Each column corresponding to the testing data in lower
%       dimensional space.
%   sqrErrs: 1*n vector of square errors because of projection of data into
%       in lower dimensional space.
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 27 Jan 07

LowerDimData = PrinCompCoeffs*K;
if nargout == 2
    sqrErrs = sqrLengths - sum(LowerDimData.*LowerDimData,1);
end;
