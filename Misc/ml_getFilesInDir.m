function files = ml_getFilesInDir(dirPath, ext, isRecursive)   
% files = ml_getFilesInDir(dirPath, ext)   
% Get all files in a directory with extension ext
% Minh Hoai Nguyen (minhhoai@cmu.edu)
% Date: 20 July 09

    if ~exist('ext', 'var') 
        ext = [];        
    end;
    files = getFilesInDir_helper(dirPath, ext);
    
    if exist('isRecursive', 'var') && ~isempty(isRecursive);
        elems = dir(dirPath);
        elems = elems([elems(:).isdir]);
        filess = cell(1, length(elems));
        for i=1:length(elems)
            if ~strcmpi(elems(i).name, '.') && ~strcmpi(elems(i).name, '..')
                filess{i} = ml_getFilesInDir(sprintf('%s/%s', dirPath, elems(i).name), ext, isRecursive);
            end;
        end
        files = cat(2, files, cat(2, filess{:}));
    end
    

function files = getFilesInDir_helper(dirPath, ext)   

if exist('ext', 'var') && ~isempty(ext)
    fls = dir([dirPath, '/*.', ext]);
    files = cell(1, length(fls));
    for i=1:length(files)
        files{i} = [dirPath, '/', fls(i).name];
    end;
else
    fls = dir(dirPath);
    files = cell(1, length(fls) - 2);
    for i=1:length(files)
        files{i} = [dirPath, '/', fls(i+2).name];
    end;
end;

isBad = false(1, length(files));
for i=1:length(files)
    file = ml_full2shortName(files{i});
    if file(1) == '.'
        isBad(i) = 1;
    end;
end;
files = files(~isBad);
