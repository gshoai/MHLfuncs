function randStr = ml_randStr(nDigit)
% Generate a random string
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Created: 14-May-2014
% Last modified: 14-May-2014

if ~exist('nDigit', 'var')
    nDigit = 7;
end

nowStr = sprintf('%.0f', now*1e20);
nowStr = nowStr(end-nDigit+4:end);
randStr = sprintf('%s%03d', nowStr, randi(999));

