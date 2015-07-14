function robustMean = ml_robustMean(D, nMaxIters, tol) 
% robustMean = ml_robustMean(D)
% robustMean = ml_robustMean(D, nMaxIters)
% robustMean = ml_robustMean(D, nMaxIters, tol) 
% Compute the robust mean of a data set.
% Inputs:
%   D: The data given in column format.
%   nMaxIters: number of maximum iterations run. 
%   tol: the tolerance for stopping condition. The algorithm stops if the
%       difference between means computed at two consecutive iterations 
%       is less than tol.
% Output:
%   robustMean: the robust mean of the data.
% By: Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 26 June 07

if ~exist('nMaxIters', 'var') || isempty(nMaxIters)
    nMaxIters = 20;
end
if ~exist('tol', 'var') || isempty(tol)
    tol = 1e-3;
end;

im = mean(D,2);
for i = 1:nMaxIters
    d2 = m_sqrDist(D, im);
    medianErr = ml_nth(sqrt(d2), round(size(D,2)/2));
    sigma = 1.4826*medianErr;
    wghts = sigma^2./((d2 + sigma^2).^2);   

    wghts = wghts./sum(wghts(:));
    new_im = D*wghts;
    if sumsqr(im - new_im) < tol;
        break;
    end;
    im = new_im;        
end;
robustMean = im;