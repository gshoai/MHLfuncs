function SqrDist = ml_sqrDist2(Data1, Data2, x2)
% Compute square Euclidean distances. Compare this function with its sister
% function: m_sqrDist(Data1, Data2). In many case we have to call this
% function many time so this function is to speed things up. In many cases,
% the Data1 does not change so it is good to precompute the square of
% lengths of vectors in Data1.
% Usages:
% Inputs:
%   Data1: a d*n matrix representing a set of d-dim data points.
%   Data2: a d*m matrix representing a second set of d-dim data points.
%   x2: the square of lengths of vectors in Data1.
% Outputs:
%   SqrDist: a n*m matrix, the entry in i_th row and j_th column represents
%       the square Euclidean distance between the i_th data point of Data1
%       and the j_th data point of Data2.
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 26 May 07

n = size(Data1,2);
m = size(Data2,2);
y2 = sum(Data2.^2);    
SqrDist = x2(:,ones(1, m)) + y2(ones(n,1),:) - 2*(Data1'*Data2);
