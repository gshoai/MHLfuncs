function a = ml_nth(v, k, mode, order)
% a = ml_nth(v, k)
% a = ml_nth(v, k, mode)
% a = ml_nth(v, k, mode, order)
% Inputs:
%   v: a vector of scalars.
%   mode, k: if mode is 0 (default), then k must be an integer number and
%       the method with return the k_th element of v after sorting.
%       if mode is 1, then k (value from 0 to 1) indicates the percentile
%       of the element that you want to retrieve. 
%   order: a string to indicate that you want the list v to be sorted in
%       the ascending or descending order. order could be either 'ascend'
%       or 'descend'. The default value is 'ascend'.
% Outputs:
%   a: the value of element that we want to retrieve.
% By Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 14 June 07.

if exist('mode', 'var') && mode == 1
    k = round(numel(v)*k);
end;

if exist('order', 'var') && strcmp(order, 'descend')
    v = sort(v, 'descend');
else
    v = sort(v, 'ascend');
end;

if k == 0 && exist('order', 'var') && strcmp(order, 'descend')
    a = v(1) + eps;
elseif k== 0
    a = v(1) - eps;
else
    a = v(k);
end



