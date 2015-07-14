function proj_d = ml_weightedProj(d, B, w)
% Weighted linear projection
% This function find proj_d = B*c with c minimizes: ||w.*(d - B*c)||^2. 
% Inputs:
%   d: a column vector of size k*1.
%   B: a k*n matrix for the subspace.
%   w: the weight vector for linear least square.
% Outputs:
%   proj_d: the weighted reconstruction of d in subspace B.
% By: Minh Hoai Nguyen
% Date: 21 Sep 07.

WB = repmat(w,1,size(B,2)).*B;
wd = w.*d;
proj_d = B*(inv(WB'*WB)*(WB'*wd));