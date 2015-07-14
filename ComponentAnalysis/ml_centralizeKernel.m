function [Ktrain, Ktest, Ktest2] = ml_centralizeKernel(Ktrain, Ktest, Ktest2)
% Centralize the test kernel, the center is taken to be the center of 
% the train data.
% Usages:
%   [Ktrain] = m_centralizeKernel(Ktrain)
%   [Ktrain, Ktest] = m_centralizeKernel(Ktrain, Ktest)
%   [Ktrain, Ktest, Ktest2] = m_centralizeKernel(Ktrain, Ktest, Ktest2)
% Inputs:
%   Ktrain: a square m*m matrix representing the training kernel matrix.
%       Ktrain(i,j) = k(x_i, x_j), x_i is the i_th training instance.
%   Ktest: the m*n kernel matrix, Ktest(i,j) = k(x_i,y_j) where k is kernel
%       function, x_i is the i_th training instance and y_j is the j_th 
%       testing instance. There are m and n training and testing instances
%       respectively.
%   Ktest2: the n*n kernel matrix, Ktest2(i,j) = k(y_i,y_j) where k is the
%       kernel function.
% Outputs:
%   Ktrain, Ktest, Ktest2: kernels after centralization.
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 30 Jan 07

m = size(Ktrain,1);
a = mean(Ktrain,1);
A = repmat(a, m, 1);

if nargin >= 2
    n = size(Ktest,2);
    b = mean(Ktest,1);
    Ktest = Ktest - repmat(b,m,1) - repmat(a',1,n) + mean(a);
end;
if nargin == 3
    Ktest2 = Ktest2 - repmat(b, n, 1) - repmat(b', 1, n) + mean(a);
end
Ktrain = Ktrain - A - A' + mean(a);
Ktrain = (Ktrain + Ktrain')/2; %This is to make sure the matrix is symmetrix, because of numerical problem.

% Clean and easy to understand code, but slower than the above code
% if nargin == 2
%     n = size(Ktrain,2);
%     Ktest = Ktest - repmat(mean(Ktest,1),m,1) - repmat(mean(Ktrain,2),1,n) + mean(mean(Ktrain));
% end;    
% OneM = ones(m,m)/m;
% Ktrain = Ktrain - OneM*Ktrain - Ktrain*OneM + OneM*Ktrain*OneM;

