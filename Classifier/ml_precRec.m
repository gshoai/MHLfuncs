function [prec, rec, ap, thresh4maxF1, uniquePosScore] = ml_precRec(score, lb, shldPlot, shldEnforceMonotonicity)
% function [prec, rec, ap] = ml_precRec(score, lb, shldPlot)
% Compute precision-recall curve and the average precision (area under the curve)
% Inputs:
%   score: n*1 vector for the score (higher score is more likely to be positive class)
%   lb: n*1 binary vector, positive class: 1, negative class: 0, -1 or anything different from 1.
%   shldEnforceMonotonicity: as the threshold increases, recall decreases, 
%       the precision must increase. If this is set to true, 
%       the curve is guaranteed to decrease as the recall increases
% Outputs:
%   rec: 1*m recall vector
%   prec: 1*m precision vector
%       Compute precision recall curve based on recall values.
%       Suppose m is the number of positive point, rec is (1, (m-1)/m, ... 1/m)
%   ap: average precsion
%   thresh4maxF1: threshold for max F1 score
% By Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Date: 29/2/12

if ~exist('shldEnforceMonotonicity', 'var') || isempty(shldEnforceMonotonicity)
    shldEnforceMonotonicity = false;
end;

if sum(isnan(score)) > 0
    error('score vector contains nan');
end;

posScore = sort(score(lb == 1), 'descend');
negScore = sort(score(lb ~= 1), 'descend');



uniquePosScore = unique(posScore);
n = length(uniquePosScore);
nPos = length(posScore);

tp  = zeros(1, n); % number of true positives
nPosOT = length(posScore);
for i=1:n
    thresh = uniquePosScore(i);
    if thresh == -inf
        nPosOT = find(posScore(1:nPosOT) > thresh, 1, 'last');
    else
        nPosOT = find(posScore(1:nPosOT) >= thresh, 1, 'last');
    end
    if ~isempty(nPosOT)
        tp(i) = nPosOT;
    else
        break;
    end;    
end;

fp = zeros(1, n); % false positive
nNegOT = length(negScore); % current number of negative over threshold;
for i=1:n
    thresh = uniquePosScore(i);    
    nNegOT = find(negScore(1:nNegOT) > thresh - eps, 1, 'last'); % number of negative over threshold
    if ~isempty(nNegOT)        
        fp(i) = nNegOT;
    else
        break;
    end
end;

rec = tp/nPos;
prec = tp./(tp + fp); 


% as the threshold increases, recall decreases, the precision must increase
% otherwise we can achive higher recall and higher precision at the same time
if shldEnforceMonotonicity
    for i=2:n
        prec(i) = max(prec(i), prec(i-1));
    end;
end

if exist('shldPlot', 'var') && shldPlot
    plot(rec, prec);
end;

diffrec = diff(rec);
meanprec = (prec(1:end-1) + prec(2:end))/2;
%ap = sum(meanprec.*diffrec)/(rec(end) - rec(1));
ap = -sum(meanprec.*diffrec); % equivalent to assign prec = 0 for rec that cannot be attained

F1score = 2*prec.*rec./(prec + rec);
[~, maxIdx] = max(F1score);
thresh4maxF1 = uniquePosScore(maxIdx);
