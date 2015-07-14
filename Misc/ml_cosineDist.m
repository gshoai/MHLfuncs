function cosineDist = ml_cosineDist(Data1, Data2)
% Compute cosine distance between data elems in Data1 and Data2
% Inputs:
%   Data1: a d*n matrix representing a set of d-dim data points.
%   Data2: a d*m matrix representing a second set of d-dim data points.
% Outputs:
%   cosineDist: a n*m matrix, the entry in i_th row and j_th column represents
%       the 1 - cosine b/w the i_th data point of Data1 and the j_th data point of Data2.
% See also: function pdist from Statistics ToolBox. 
% However, pdist is much slower than this function.
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 2 March 07

n = size(Data1,2);
m = size(Data2,2);
d1 = sqrt(sum(Data1.^2,1)');
d2 = sqrt(sum(Data2.^2,1));    
cosineDist = 1 - Data1'*Data2./(d1(:,ones(1, m)).*d2(ones(n,1),:) +eps);
