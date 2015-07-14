function [Coeffs, eigValues] = ml_kpca(Kernel, k, mode, isSparse)
% Compute the coeffs and corresponding eigen values in KPCA. The principle
% components form a set of orthornormal vectors in feature space.
% Make sure that the kernel is CENTRALIZE before passing to this function.
% Usage:
%   [Coeffs, eigValues] = ml_kpca(Kernel, k)
%   [Coeffs, eigValues] = ml_kpca(Kernel, k, mode, )
%   [Coeffs, eigValues] = ml_kpca(Kernel, k, mode, isSparse)
% Inputs:   
%   Kernel: the square symmetric kernel metric of size m*m.
%       This is the kernel of the CENTRALIZED data
%   mode, k: if mode is 0 (default), then k is the no of principle components
%            if mode is 1, then k is the energy (value from 0 to 1) that 
%               KPCA should preserve.
%   isSparse: 1 if Kernel is a sparse matrix, 0 if not. Default value is 0.
% Outputs:
%   Coeffs: suppose the subspace has k dimensions, then Coeffs is a k*m
%       matrix, each row is coeffs of a principle component.
%       Suppose the data are: x_1, ..., x_m, and data in feature space are
%       phi(x_1), ..., phi(x_m) then a principle component has the form:
%       a_1*phi(x_1) + ... a_m*phi(x_m) and a_1,...,a_m are called the 
%       scalar coefficients of the principle component.
%   eigValues: a column vector of corresponding eigen values of principle
%       components given in Coeffs.
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 27 Jan 07
 
%persistent Coeffs2 eigValues2
  
if exist('Coeffs2', 'var') && ~isempty(Coeffs2)
    Coeffs = Coeffs2;
    eigValues = eigValues2;
else 
    if nargin < 3
        mode = 0; isSparse = 0;
    elseif nargin < 4
        isSparse = 0;
    end;

    m = size(Kernel,1);

    if mode ~= 1
        if isSparse
            [Coeffs,D] = eigs(Kernel, [], k);        
        else
            [Coeffs,D] = eig(Kernel);       
        end    
        [eigValues, indx] = sort(diag(D), 'descend');
    else
        if isSparse
            [Coeffs, D] = eigs(Kernel);
        else 
            [Coeffs, D] = eig(Kernel);
        end
        [eigValues, indx] = sort(diag(D), 'descend');
        cumEnergy = cumsum(eigValues)/sum(eigValues);
        k = sum(cumEnergy < k) +1;     
    end;

    eigValues = eigValues(1:k);
    Coeffs = Coeffs(:,indx(1:k));
    Coeffs = Coeffs';  

    %Make the principle components to be orthornormal
    sqrLengths = sum(Coeffs.*Coeffs,2);
    Coeffs = Coeffs./repmat(sqrt(eigValues.*sqrLengths), 1, m);
    eigValues = eigValues/m;

    fprintf('# principle components: %d\n', size(Coeffs,1));
    
    Coeffs2 = Coeffs;
    eigValues2 = eigValues;
end;



