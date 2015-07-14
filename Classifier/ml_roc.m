function [rocArea, thres, acc, tprtnr, F1, xroc, yroc] = ml_roc(x, y, shldDisp, option)
% [rocArea, thres, acc] = ml_roc(x, y, shldDisp)
% Inputs:
%   x: column vector for scores of negative examples.
%   y: column vector for scores of positive examples.
%       pricition rule: >= threshold -> positive
%   shldDisp: should display the ROC and the tabel.
%   option: option to determine the cutoff point.
%       either 'TPR+TNR', 'ACC', 'F1' or something else. 
%       If it is 'TPR+TNR', it is the cutoff point that maximize the TPR+TNR. 
%       If it is ACC, it is the cutoff point that maximize the accuracy
%       If it is F1, it is the cutoff point that maximizes the F1 score.
% Outputs:
%   rocArea: area under the ROC
%   thres: threshold point for deciding b/t positive and negative
%   acc: accuracy at the threshold value (TP + TN)/(P + N)
%   tprtnr = 0.5*(TPR + TNR)
%   F1: F1 score
%
% By: Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 26 Dec 08
% Last modified: 30 Apr 09

%Input Error handling
% if ~all(isfinite(x(:))) || ~all(isnumeric(x(:))) || ~all(isfinite(y(:))) || ~all(isnumeric(y(:)))
%     error('Warning: all X and Y values must be numeric and finite')
% end
if ~all(isnumeric(x(:))) || ~all(isnumeric(y(:)))
    error('Warning: all X and Y values must be numeric and finite')
end


if ~isvector(x) || ~isvector(y)
    error('Warning: X and Y must be vectors not matrix')
end

lx=length(x); ly=length(y); %number of subjects
%join both arrays and add a label (1-unhealthy; 2-healthy)
z=sortrows([x(:) repmat(1,lx,1); y(:) repmat(2,ly,1)],1);
%find unique values in z
labels=unique(z(:,1));
ll=length(labels); %count unique value
a=zeros(ll,2); %array preallocation
F1s = zeros(ll,1); % for precision recall
for K=1:ll
     I= sum(z(:,1)<=labels(K)); %set unique value(i) as cut-off
     table(1)=sum(z(1+I:end,2)==2); %true positives
     table(2)=sum(z(1+I:end,2)==1); %false positives
     test=[table;[ly lx]-table]; %complete the table
     a(K,:)=(diag(test)./sum(test)')'; %Sensibility and Specificity
     F1s(K) = 2*test(1,1)/(2*test(1,1) + test(1,2) + test(2,1));
end
xroc=1-a(:,2); yroc=a(:,1); %ROC points

% Finding the cutoff value co.
if exist('option', 'var') && strcmpi(option, 'TPR+TNR')
    %the best cut-off point is the point minimize TPR + TNR
    d=xroc + (1-yroc); 
    [Y,J]=min(d); %find the least distance
    co=labels(J); %set the cut-off point
elseif exist('option', 'var') && strcmpi(option, 'ACC')
    d=length(x)*xroc + length(y)*(1-yroc); 
    [Y,J] = min(d); %find the least distance
    co=labels(J); %set the cut-off point
elseif exist('option', 'var') && strcmpi(option, 'F1')
    [dc, J] = max(F1s);
    co = labels(J);    
else    
    %the best cut-off point is the closest point to (0,1)
    d=realsqrt(xroc.^2+(1-yroc).^2); %apply the Pitagora's theorem
    [Y,J]=min(d); %find the least distance
    co=labels(J); %set the cut-off point
end;
F1 = F1s(J);

rocArea = trapz(1-yroc,1-xroc); %estimate the area under the curve

thres = co;
I= sum(z(:,1)<=co);
table(1)= sum(z(1+I:end,2)==2);
table(2)= sum(z(1+I:end,2)==1);
test=[table;[ly lx]-table];

acc = 100*trace(test)/sum(test(:));
tprtnr = test(1,1)/(test(1,1) + test(2,1)) + test(2,2)/(test(1,2) + test(2,2));
tprtnr = 50*tprtnr;



if shldDisp
    %display results
    fprintf('cut-off point for best sensibility and specificity (blu circle in plot)= %0.4f\n',co)
    %display graph
    figure; subplot(1,2,1);
    plot(xroc,yroc,'r.-',xroc(J),yroc(J),'bo',[0 1],[0 1],'k')
    xlabel('False positive rate (1-specificity)')
    ylabel('True positive rate (sensibility)')
    title('ROC curve'); axis square;

    %table at cut-off point
    disp('Table at cut-off point');
    disp(test);
    disp(' ');
    partest(test);
end


function partest(x)
    %This function calculate the performance, based on Bayes theorem, of a
    %clinical test.
    %
    % Syntax: 	PARTEST(X)
    %      
    %     Input:
    %           X is the following 2x2 matrix.
    %
    %....................Unhealthy.....Healthy 
    %                    _______________________
    %Positive Test      |   True    |  False    |
    %                   | positives | positives |
    %                   |___________|___________|
    %                   |  False    |   True    |
    %Negative Test      | negatives | negatives |
    %                   |___________|___________|
    %
    %     Outputs:
    %           - Prevalence of disease
    %           - Test Sensibility 
    %           - Test Specificity
    %           - False positive and negative proportions
    %           - Youden's Index
    %           - Number needed to Diagnose (NDD)
    %           - Discriminant Power
    %           - Test Accuracy
    %           - Mis-classification Rate
    %           - Positive predictivity
    %           - Negative predictivity
    %           - Positive Likelihood Ratio
    %           - Negative Likelihood Ratio
    %           - Test bias
    %           - Diagnostic odds ratio
    %           - Error odds ratio
    %
    %      Example: 
    %
    %           X=[80 3; 5 20];
    %
    %           Calling on Matlab the function: partest(X)
    %
    %           Answer is:
    %
    %           Prevalence: 78.7037%
    %           Sensibility (probability that test is positive on unhealthy subject): 94.1176%
    %           False positive proportion: 10%
    %           Specificity (probability that test is negative on healthy subject): 86.9565%
    %           False negative proportion: 2%
    %           Youden's Index (a perfect test would have a Youden's index of +1): 0.81074
    %           Number needed to Diagnose (NDD): 1
    %           Discriminant Power: 2.9
    %               A test with a discriminant value of 1 is not effective in discriminating between affected and unaffected individuals.
    %               A test with a discriminant value of 3 is effective in discriminating between affected and unaffected individuals.
    %           Accuracy or Potency: 92.5926%
    %           Mis-classification Rate: 7.4074%
    %           Predictivity of positive test (probability that a subject is unhealthy when test is positive): 96.3855%
    %           Predictivity of negative test (probability that a subject is healthy when test is negative): 80%
    %           Positive Likelihood Ratio: 7.2157
    %           Moderate increase in possibility of disease presence
    %           Negative Likelihood Ratio: 0.067647
    %           Large (often conclusive) increase in possibility of disease absence
    %           Test bias: 0.97647
    %           Test underestimate the phenomenon
    %           Diagnostic odds ratio: 106.6667
    %           Error odds ratio: 2.4
    %
    %           Created by Giuseppe Cardillo
    %           giuseppe.cardillo-edta@poste.it
    %
    % To cite this file, this would be an appropriate format:
    % Cardillo G. (2006). Clinical test performance: the performance of a
    % clinical test based on the Bayes theorem. 
    % http://www.mathworks.com/matlabcentral/fileexchange/12705

    %Input Error handling
    [r,c] = size(x);
    if (r ~= 2 || c ~= 2)
        error('Warning: PARTEST requires a 2x2 input matrix')
    end
    clear r c %clear unnecessary variables
    s1=sum(x); %columns sum
    tot=sum(x(:)); %numbers of elements
    d=diag(x); %true positives and true negatives
    a=d./s1'; %Sensibility and Specificity
    dp=1-a; %false proportions
    acc=trace(x)/tot; %Accuracy

    %display results
    fprintf('Accuracy: %0.1f%%\n', acc*100)

    xg=s1./tot;
    subplot(1,2,2);
    hold on
    h1=fill([0 xg(1) xg(1) 0],[0 0 dp(1) dp(1)],'y');
    h2=fill([0 xg(1) xg(1) 0],dp(1)+[0 0 a(1) a(1)],'g');
    h3=fill(xg(1)+[0 xg(2) xg(2) 0],[0 0 a(2) a(2)],'b');
    h4=fill(xg(1)+[0 xg(2) xg(2) 0],a(2)+[0 0 dp(2) dp(2)],'r');
    hold off
    axis square
    title('PARTEST GRAPH')
    xlabel('Subjects proportion')
    ylabel('Parameters proportion')
    legend([h1 h2 h3 h4],'False Negative','True Positive (Sensibility)','True Negative (Specificity)','False Positive','Location','NorthEastOutside')

