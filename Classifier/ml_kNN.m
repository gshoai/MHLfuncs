function predicted = ml_kNN(trainData, testData, trainLabel, k, distType, Dist)
% predicted = ml_kNN(trainData, testData, trainLabel, k)
% predicted = ml_kNN(trainData, testData, trainLabel, k, distType)
% predicted = ml_kNN(trainData, testData, trainLabel, k, distType, Dist)
% k-nearest neighbours classifier.
% Inputs:
%   trainData, testData: each column is a data point
%   trainLabel: row vector indicating class label of columns of trainData.
%       Assume there are only two classes, each entry of trainLabel can
%       only be 1 or 2.
%   k: how many nearest neigbors to look at. This algo only uses k-nns even
%       if there are some ties in distance ranking.
%   distType: there are three types: 'Euclidean', 'cosine', 'predefined'.
%       The default value is 'Euclidean';
%   Dist: if distType is 'predefined' then Dist is a n*m matrix that tells
%       us the distance between training data and testing data. Here n is
%       the number of training data and m is the number of testing data.
% Outputs:
%   predicted: row vector indicating predicted labels of testData.
% By: Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 24 June 2007.

m = size(testData,2);

if ~exist('distType', 'var')
    distType = 'Euclidean';
end;

if ~strcmp(distType, 'predefined')
    if strcmp(distType, 'cosine')
        Dist = m_cosineDist(trainData, testData);
    elseif strcmp(distType, 'Euclidean')
        Dist = ml_sqrDist(trainData, testData);
    else
        error('ml_kNN: error: unkown distance type');
    end;
end;

    
[sorted, IX] = sort(Dist,1);
nnIX = IX(1:k,:);
labels = repmat(trainLabel, 1, m);
ind = sub2ind(size(labels), nnIX, repmat(1:m, k, 1));
nnLabels = labels(ind);
c1Idx = sum(nnLabels==1,1) >= k/2;
predicted = zeros(m, 1);
predicted(c1Idx) = 1;
predicted(~c1Idx) = 2;

