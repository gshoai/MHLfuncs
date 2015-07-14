function ml_matrix2latex_confusion(A, format, grayRng, labels)
% ml_matrix2latex_confusion(A, format, grayRng, labels)
% Print a matrix in Latex format
% Inputs:
%   A: the matrix to display, value should be from 0 to 1 or the format should be adjusted
%   format: the format of the fprintf which governs  how much space given to each number in the matrix. 
%       default value of 'format' is '.%02.0f';
%   grayRng: [0, 1] should be mapped to what gray valued?
%       default: [1 0.3], 1 is white, 0.3 is quite dark
%   labels: the row labels
% Outputs:
%   No output, this print to the standard output.
% By Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 1 Mar 2011

if ~exist('format', 'var') || isempty(format)
    format = ('.%02.0f');
end;

if ~exist('grayRng', 'var') || isempty(grayRng)
    % 1 is white, 0.3 is very dark, 0 of A is mapped to 1, 1 of A is mapped to 0.3
    
    grayRng = [1 0.3]; 
end;

b = grayRng(1);
a = grayRng(2) - grayRng(1);


for i=1:size(A,1)
    fprintf(labels{i});
    for j=1:size(A,2)
        color = a*A(i,j) + b;
        fprintf('&\\cellcolor[gray]{%.1f}%s', color, sprintf(format, 100*A(i,j)));
    end;
    fprintf('\\\\ \\hline \n');
end;
