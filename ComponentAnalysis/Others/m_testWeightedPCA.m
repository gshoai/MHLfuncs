function m_testWeightedPCA()
    D = ml_getUSPSData(10, 1, 0);
    k = 20;
    
    % weighted PCA
    w = ones(16, 16);
    w(:,1:8) = 200;
%     w = repmat(w(:),1, 100);
    w = w(:);
    [B,C] =  ml_weightedPCA(D, w, k, 50, [], [], 1);    
    RecD = B*C;
    W = repmat(w, 1, 100);
    [B2,C2] =  ml_weightedPCA(D, W, k, 50, [], [], 1);    
    RecD2 = B2*C2;
    
    bigIm = ml_data2Img(D, 16, 16);
    figure(1); subplot(2,2,1); imshow(bigIm');
    recBigIm = ml_data2Img(RecD, 16, 16);
    figure(1); subplot(2,2,2); imshow(recBigIm');
    recBigIm = ml_data2Img(RecD2, 16, 16);
    figure(1); subplot(2,2,3); imshow(recBigIm');
    
    
    
    % normal PCA
    mD = mean(D,2);
    cD = D - repmat(mD, 1, size(D,2));
    [PcaBasis, sVals, LowDimD, RecD] = ml_pca(cD, k, 0);
    RecD = RecD + repmat(mD, 1, size(D,2));
    recBigIm = ml_data2Img(RecD, 16, 16);
    figure(1); subplot(2,2,4); imshow(recBigIm');