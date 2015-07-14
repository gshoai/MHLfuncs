function m_testKpcaProjCoeffs()
    D = ml_getUSPSData(10, 0, 0);
    gamma = 0.01;
    K = exp(-gamma*m_sqrDist(D,D));
    [Alphas, betas, const] = ml_kpcaProjCoeffs(K, 100, 1);
    
    randIdxes = randperm(size(D,2));
    errs = zeros(1,10);
    for i=1:10
        d = D(:,randIdxes(i));
        dK = exp(-gamma*m_sqrDist(D, d));
        errs(i) = 1  - dK'*Alphas*dK - betas'*dK + const;
    end;
    
    disp(errs);