function [B, eigValues] = ml_oca(D1, D2)
% oriented component analysis
% We want a subspace B that reconstruct D1 well but not D2.
% Inputs:
%   D1, D2: two matrices of data in column format. size(D1,1) must be equal size(D2,1)
% Outputs:
%   B: the subspace in column format that reconstruct D1 well but not D2. Generally, B is not
%       an othornormal set of vectors.
%   eigValues: generalized eigenvalues corresponding to the basis vectors.
% By: Minh Hoai Nguyen
% Date: 06 Sep 2007

[d, n1] = size(D1);
n2 = size(D2,2);


% The are two ways of computing the subspace B. 
% Which method is computationally cheaper depends on the relationship between
% d and n1 + n2.  
if d <= (n1 + n2)
    D1D1t = D1*D1';
    D2D2t = D2*D2';
    [B,S] = eig(D2D2t, D1D1t);    
else 
    D = [D1, D2];
    A1 = D'*D1;
    A1A1t = A1*A1';
    A2 = D'*D2;
    A2A2t = A2*A2';
    [B,S] = eig(A2A2t, A1A1t);    
    B = D*B;
end;
diagS = diag(S);
idxs1 = double(isinf(diagS));
idxs2 = double(isnan(diagS));
idxs3 = idxs1 + idxs2 == 0;
diagS = diagS(idxs3);
B = B(:, idxs3);
[diagS, idxs4] = sort(diagS, 1);
B = B(:, idxs4);
eigValues = diagS;