function [CM, uniqueLb] = ml_cmpConfusionMatrix(predLb, gtLb, method)
% function CM = ml_cmpConfusionMatrix(predLb, gtLb)
% Compute a confusion matrix
% Inputs:
%   predLb, gtLb: column vectors for predicted and gt labels
%   method: either 'count' or 'proportion'
% Outputs:
%   CM: the confusion matrix (row: acual class, column: predicted class)
%   uniqueLb: the order of the labels in the confusion matrix
% By Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Date: 9/2/12

predLb = predLb(:);
gtLb = gtLb(:);
uniqueLb = unique([predLb; gtLb]);
k = length(uniqueLb);
CM = zeros(k,k);
for i=1:k    
    gtLb_i = gtLb == uniqueLb(i);
    for j=1:k
        CM(i,j) = sum(and(gtLb_i, predLb == uniqueLb(j)));
    end;
end;

if strcmpi(method, 'proportion')
    CM = CM./repmat(sum(CM,2),1, k);
end;
