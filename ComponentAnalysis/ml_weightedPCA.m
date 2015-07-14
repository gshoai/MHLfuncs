function [B, C, sVals] = ml_weightedPCA(D, w, k, nMaxIters, initB, initC, display)
% function [B, C] = ml_weightedPCA(D, w, k, nMaxIters, initB, initC, display)
% Perform weighted PCA. This factor a matrix using weighted least square cost.
% Minimize ||W.*(D - B*C)||^2 w.r.t B,C of low rank k.
% We do not subtract the mean of D.
% Inputs:
%   D: data matrix of size d*n in column format.
%   w: weight vector of d*1 or weight matrix d*n. 
%       if w is a vector, the weight matrix W = repmat(w, 1, n).
%       if w is d*n matrix, the weight matrix W = w;
%       Note that the program runs faster if w is a vector.
%   k: the low rank enforced for B and C.
%   nMaxIters: maximum number of iteration run, default 50.
%   initB, initC: initial estimate of B, C.
%   display: default 0. If display = 0, print nothing. If display is m, this print
%       out debug message every m iterations.
% Outputs:
%   B: low rank matrix of size d*k.
%   C: low rank matrix of size k*n.
%   sVals: sVals is the values of singular values. This output is only meaningful if w is d*1 vector.
% Other notes: This Fernando has another version of this function. In his implementation,
%   he subtracts the mean from the data.
%
% By: Minh Hoai Nguyen (minhhoai@cmu.edu).
% Date: 13 Sep 2007.


[d, n] = size(D);

if size(w,1) ~= d || ((size(w,2) ~= 1) && (size(w,2) ~= n))
    error('ml_weightedPCA: w must have size d*1 or d*n');    
end;
    
if size(w,2) == 1
    WD = repmat(w, 1, n).*D;
    if (d > n)
        [WB, sVals, C] = ml_pca(WD, k, 0);
    else
        [WB, sVals, C] = ml_pca2(WD, k, 0);
    end;
    B = WB./repmat(w, 1, k);
else
    if ~exist('initB', 'var') || ~exist('initC', 'var') || isempty(initB) || isempty(initC)
        if (d > n)
            [B, sVals, C] = ml_pca(D, k, 0);
        else
            [B, sVals, C] = ml_pca2(D, k, 0);
        end;
    else
        B = initB; C = initC;
    end;

    if ~exist('nMaxIters', 'var') || isempty(nMaxIters)
        nMaxIters = 50;
    end;

    if ~exist('display', 'var') || isempty(display)
        display = 0;
    end;

    W = w;
    WD = W.*D;

    iter = 0;
    while iter < nMaxIters
        iter = iter + 1;
        err = sumsqr(W.*(D - B*C));

        %fix B, optimize C.
        for i=1:n
            WB = repmat(W(:,i),1, k).*B;
            C(:,i) = inv(WB'*WB)*(WB'*WD(:,i));
        end;

        %fix C, optimize B
        oldB = B;
        for i=1:d
            WC = C.*repmat(W(i,:), k, 1);
            B(i,:) = (WD(i,:)*WC')*inv(WC*WC');       
        end

        angularError=subspace(B,oldB);
        if display ~= 0 && rem(iter, display) == 0
           fprintf('ml_weightedPCA: Iter %d , Err:%.3f ,  angularError: %.3f \n',iter, err, angularError);   
        end;

        if angularError < 1e-3 && iter > 30
            break;
        end
    end;
end;



