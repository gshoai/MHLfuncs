function m_testKpca()
% Contain an example of how to use kpca and kpcaProject functions.
% By Minh Hoai Nguyen (minhhoai@gmail.com)
% Date: 27 Jan 07


% Generate toy data
samples=18; noisex=0; noisey=0;
x= 2*cos(2*(0:pi/samples:pi)); 
x= x + noisex*randn(1, length(x));
x(end) = [];
y= sin(2*(0:pi/samples:pi)); 
y= y + noisey*randn(1, length(y));
y(end) = [];

data = [x; y];
save toyData_18.mat data;
%Data = [x.^2; y.^2];
%Data = [x.^2; y.^2; sqrt(2)*x.*y];
K = Data'*Data;
%K = K.*K.*K; %quadratic kernel.

K = m_centralizeKernel(K);
[Coeffs, eigValues] = m_kpca(K, 1, 0);
%Coeffs = m_iKpca(K, 2);
[LowerDimData, sqrErrs] = m_kpcaProj(K, Coeffs, diag(K)');

disp('Coeffs:'); disp(Coeffs);
disp('LowerDimData:'); disp(LowerDimData);
% disp('eigValues:'); disp(eigValues);
disp('errs:'); disp(sqrErrs);
% disp(sumsqr(K - K2));

keyboard;