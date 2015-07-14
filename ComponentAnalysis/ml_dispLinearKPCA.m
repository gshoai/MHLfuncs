function ml_dispLinearKPCA(trainData, testData, imH, imW, energy)
% m_linearKPCA: Perform linear KPCA, compute recontruction errors and 
% display original and reconstruction images for visual inspection.
% Inputs:
%   trainData: trainData in column vectors.
%   testData: testData in column vectors.
%   imH, imW: heigh and weight of images.
%   energy: the energy that we want to preserve when doing KPCA.
% By: Minh Hoai Nguyen
% Date: 25 Feb 07

    meanTrain = mean(trainData, 2);    
    Ktrain = trainData'*trainData;    
    Ktest = trainData'*testData;
    Ktest2 = testData'*testData;
    
    [Ktrain, Ktest, Ktest2] = m_centralizeKernel(Ktrain, Ktest, Ktest2);
    Coeffs = m_kpca(Ktrain, energy, 1);
    [L1, trainSSE] = m_kpcaProj(Ktrain, Coeffs, diag(Ktrain)');   
    [L2, testSSE] = m_kpcaProj(Ktest, Coeffs, diag(Ktest2)');
    
    reTrainData = trainData*Coeffs'*L1;
    reTestData = trainData*Coeffs'*L2;
    reTrainData = reTrainData + repmat(meanTrain, 1, size(trainData,2));
    reTestData = reTestData + repmat(meanTrain, 1, size(testData,2));
    fprintf('Number of PCs: %d\n', size(L1,1));
    fprintf('Mean pixel reconstruction error of train data: %f\n', ...
        sqrt(mean(trainSSE)/size(trainData,1)));
    fprintf('Mean pixel reconstruction error of test data: %f\n', ...
        sqrt(mean(testSSE)/size(testData,1)));
    
    dispDatas(trainData, reTrainData, testData, reTestData, imH, imW);

    
function dispDatas(trainData, reTrainData, testData, reTestData, h, w)
    figure(1); dispData(trainData, h, w); 
    figure(2); dispData(reTrainData, h, w); 
    figure(3); dispData(testData, h, w); 
    figure(4); dispData(reTestData, h, w);
    
function dispData(data, h, w, nR, nC)
    if ~exist('nC', 'var') || ~exist('nR', 'var')
        dataIm = m_data2Img(data, h,w);
    else
        dataIm = m_data2Img(data, h,w, nR, nC); 
    end;
    imshow(dataIm);
    
   
