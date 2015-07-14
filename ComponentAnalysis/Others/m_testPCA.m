function m_testPCA()
    [D, TestD] = ml_getUSPSData(100, 1, 0);
    mD = mean(D,2);
    cD = D - repmat(mD, 1, size(D,2));
    k = 0.9; mode = 1;
    [PcaBasis, sVals, LowDimD, RecD] = ml_pca(cD, k, mode);
    RecD = RecD + repmat(mD, 1, size(D,2));
    bigIm = m_data2Img(D, 16, 16);
    figure(1); imshow(bigIm');
    recBigIm = m_data2Img(RecD, 16, 16);
    figure(2); imshow(recBigIm');
    
    
    K = D'*D;
    cenK = m_centralizeKernel(K);    
    [Coeffs, eigValues] = m_kpca(cenK, k, mode);
    LowDimD2 = Coeffs*cenK;
    
    disp(sumsqr(abs(LowDimD2./LowDimD) - 1));
      
    keyboard;
    