classdef ML_VidThread
% Group video shots into threads    
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 10-Oct-2014
% Last modified: 10-Oct-2014
    methods (Static)
        
        % Grouping shots, by finding the connected components
        % imFiles: 1*n cell structure of full-path image files
        % maxDist: only compute differences for shots have at most maxDist shots apart 
        %   i.e., only compute diff for i^th shot and j^th shot if j-i <= maxDist
        %   the default is 10.
        % featType: 'hog' or 'sift', the default is 'sift'
        % Return:
        %   shotBnds: start indexes of shots, counting start from 1.
        %   threads:  a cell array, threads{i} is a list of shot indexes in the i^th thread
        function [shotBnds, threads] = getThreads(imFiles, maxDist, featType, shldDisp)
            if ~exist('maxDist', 'var') || isempty(maxDist)
                maxDist = 10;
            end;
            if ~exist('featType', 'var') || isempty(featType)
                featType = 'sift';
            end;
            
            shotBnds = ML_VidShot.detectCuts(imFiles);            
            nFrm = length(imFiles);
            nShot = length(shotBnds) + 1;
            
            shots = zeros(2, nShot);
            shots(1,1) = 1;
            shots(2, end) = nFrm;
            
            if ~isempty(shotBnds)
                shots(1, 2:end)   = shotBnds;
                shots(2, 1:end-1) = shotBnds-1;
            end
            threads = ML_VidThread.getThreads_helper(imFiles, shots, maxDist, featType);
            
            if exist('shldDisp', 'var') && shldDisp
                for j=1:length(threads)
                    fprintf('Shots in Thread %2d:',j);
                    fprintf(' %d', threads{j});
                    fprintf('\n');
                end;                                
            end            
        end
        
        function threads = getThreads_helper(imFiles, shots, maxDist, featType)
            nShot = size(shots,2);
            if strcmpi(featType, 'hog')
                cellSz = 20;
                thresh = 0.08;                
                startHogs = cell(1, nShot);
                endHogs = cell(1, nShot);            
                for i=1:nShot
                    im1 = imread(imFiles{shots(1,i)}); 
                    im2 = imread(imFiles{shots(2,i)}); 
                    hog_feat = features(double(im1), cellSz);
                    startHogs{i} = hog_feat(:);
                    hog_feat = features(double(im2), cellSz);
                    endHogs{i} = hog_feat(:);
                end;

                DiffMat = inf(nShot);            
                for i=1:nShot
                    for u=1:maxDist
                        j = i+u;
                        if j > nShot
                            break
                        end;
                        DiffMat(i,j) = mean(abs(endHogs{i} - startHogs{j})); 
                    end;
                end;
                [IY, IX] = ind2sub([nShot, nShot], find(DiffMat < thresh));
            elseif strcmpi(featType, 'sift')
                startSifts = cell(2, nShot);
                endSifts = cell(2, nShot);
                for i=1:nShot
                    im1 = imread(imFiles{shots(1,i)}); 
                    im2 = imread(imFiles{shots(2,i)}); 
                    im1 = single(rgb2gray(im1)) ;            
                    im2 = single(rgb2gray(im2)) ;            
                    [startSifts{1,i}, startSifts{2,i}] = vl_sift(im1);
                    [endSifts{1,i}, endSifts{2,i}] = vl_sift(im2);                    
                end;
                
                isMatch = zeros(nShot);
                for i=1:nShot
                    for u=1:maxDist
                        j = i+u;
                        if j > nShot
                            break
                        end;
                        isMatch(i,j) = ML_VidShot.isSiftMatch(endSifts(:,i), ...
                            startSifts(:,j), size(im1,1), size(im1,2));
                    end;
                end;                
                [IY, IX] = ind2sub([nShot, nShot], find(isMatch));                
            end;

            if nShot == 1
                threads = {1};
            else
                pairs = [IY, IX; IX, IY];
                AdjM = accumarray(pairs, 1, [nShot, nShot]); 
                AdjM(1:(nShot+1):end) = 1;

                % use Dulmage-Mendelsohn decomposition to find connected components
                % a good tutorial is: http://blogs.mathworks.com/steve/2007/03/20/connected-component-labeling-part-3/
                [p,~,r,~] = dmperm(AdjM); 
                nCC = length(r) - 1; % number of connected components

                % sort by first appearance
                firstShot = p(r(1:nCC));
                [~, ccOrder] = sort(firstShot, 'ascend');
                threads = cell(1, nCC);

                for j=1:nCC                 
                    ccIdx = ccOrder(j);
                    threads{j} = p(r(ccIdx):r(ccIdx+1)-1);                
                end;
            end;                        
        end;   
        
        % Display threads
        % nFrm: number of frames
        % shotBnds: shot boundaries, staring indexes of the shots, counting start from 1
        % threads: cell array for groups of shot indexes
        % startFrm, endFrm: start and end frames for a particular event (e.g., human action).
        function dispThreads(nFrm, shotBnds, threads, startFrm, endFrm)
            nShot = length(shotBnds) + 1;
            shots = zeros(2, nShot);
            shots(1,1) = 1;
            shots(2, end) = nFrm;
            
            if ~isempty(shotBnds)
                shots(1, 2:end)   = shotBnds;
                shots(2, 1:end-1) = shotBnds-1;
            end
            
            startShot = find(startFrm <= shots(2,:), 1, 'first');
            endShot   = find(endFrm   >= shots(1,:), 1, 'last');
            
            
            for j=1:nShot
                fprintf('%d ', j);
            end;
            fprintf('\n');
            defStrs = cell(1, nShot);
            for j=1:nShot
                defStrs{j} = repmat('-', [1, length(sprintf('%d', j))+1]);
            end;
            
            acitonLocStrs = defStrs;
            for j=startShot:endShot
                acitonLocStrs{j} = repmat('*', [1, length(sprintf('%d', j))+1]);
            end
            fprintf('%s', cat(2, acitonLocStrs{:}));
            fprintf('\n');
            
            for j=1:length(threads)
                threadStrs = defStrs;
                if length(threads{j}) > 1
                    for v=1:length(threads{j})
                        threadStrs{threads{j}(v)} = sprintf('%d-', threads{j}(v));
                    end;
                    fprintf('%s', cat(2, threadStrs{:}));
                    fprintf('\n');
                end;
            end;            
        end;
        
        % Create a gif image for each shot of a clip
        function createHtmls(imFiles, shotBnds, threads, outDir)
            nShot = length(shotBnds) + 1;
            shots = zeros(2, nShot);
            shots(1,1) = 1;
            shots(2, end) = length(imFiles);
            if nShot > 1
                shots(1, 2:end)   = shotBnds;
                shots(2, 1:end-1) = shotBnds-1;
            end
            
            cmd = sprintf('mkdir -p %s', outDir);
            fprintf('%s\n', cmd);
            system(cmd);
            
            gifFiles = cell(1, nShot);
            for j=1:nShot
                gifFile = sprintf('%s/shot_%03d.gif', outDir, j);
                gifFiles{j} = gifFile;
                ML_VidThread.createGif(imFiles(shots(1,j):shots(2,j)), gifFile);                
            end
            
            htmlFile1 = sprintf('%s/shots.html', outDir);
            ML_VidThread.crtHtml4shots(gifFiles, shots, threads, htmlFile1);
            
            htmlFile2 = sprintf('%s/threads.html', outDir);
            ML_VidThread.crtHtml4threads(gifFiles, shots, threads, htmlFile2);
        end
        
        function crtHtml4threads(gifFiles, shots, threads, outHtmlFile)                        
            fout = fopen(outHtmlFile, 'w');
            fprintf(fout, '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">\n');            
            fprintf(fout, '<html><head><meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">\n');
            fprintf(fout, '<style> img {width: 100%%; display: table-cell;} </style></head>\n\n');            
            fprintf(fout, '<table style="width: 100%%;">\n');
            
            nShot = size(shots,2);            
            fprintf(fout, '  <tr>\n');
            fprintf(fout, '     <td>All</td>\n');
            for c=1:nShot                
                fprintf(fout, '    <td><img src="%s"></td>\n', ...
                    ml_full2shortName(gifFiles{c}));                
            end;
            fprintf(fout, '  </tr>\n');
            fprintf(fout, '     <td></td>\n');
            for c=1:nShot                
                fprintf(fout, '<td><font color="black"> Shot %d: %d-%d</font></td>', ...
                    c, shots(1,c), shots(2,c));
            end;
            fprintf(fout, '  </tr>\n');            
            
            for r=1:length(threads)
                fprintf(fout, '  <tr>\n');
                fprintf(fout, '     <td>T%d</td>\n', r);
                for c=1:nShot                
                    if any(threads{r} == c)
                        fprintf(fout, '    <td><img src="%s"></td>\n', ...
                            ml_full2shortName(gifFiles{c}));                
                    else
                        fprintf(fout, '    <td></td>\n'); 
                    end
                end;
                fprintf(fout, '  </tr>\n');
                
                fprintf(fout, '  </tr>\n');
                fprintf(fout, '     <td></td>\n');
                for c=1:nShot
                    if any(threads{r} == c)
                        fprintf(fout, '<td><font color="black"> Shot %d: %d-%d</font></td>', ...
                            c, shots(1,c), shots(2,c));
                    else
                        fprintf(fout, '    <td></td>\n'); 
                    end
                end;
                fprintf(fout, '  </tr>\n');

            end;

            fprintf(fout, '</table>\n');                                    
            fprintf(fout, '<p>Threads: ');
            for i=1:length(threads)
                fprintf(fout, '['); 
                if length(threads{i}) > 1
                    fprintf(fout, '%d, ', threads{i}(1:end-1));
                    fprintf(fout, '%d', threads{i}(end));
                else
                    fprintf(fout, '%d', threads{i});
                end
                fprintf(fout, ']; ');
            end;
            fprintf(fout, '</p>\n');            
            fprintf(fout, '</html>\n');
            fclose(fout);            
        end;
        
        function crtHtml4shots(gifFiles, shots, threads, outHtmlFile)
            fout = fopen(outHtmlFile, 'w');
            fprintf(fout, '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">\n');            
            fprintf(fout, '<html><head><meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">\n');
            fprintf(fout, '<style> img {width: 100%%; display: table-cell;} </style></head>\n\n');            
            fprintf(fout, '<table style="width: 100%%;">\n');
            
            nShot = size(shots,2);
            nC = 5;            
            nR = ceil(nShot/nC);
            cnt1 = 0; cnt2 = 0;
            for r=1:nR
                fprintf(fout, '  <tr>\n');
                for c=1:nC
                    cnt2 = cnt2 + 1;
                    if cnt2 <= nShot
                        fprintf(fout, '    <td><img src="%s"></td>\n', ...
                        ml_full2shortName(gifFiles{cnt2}));
                    end
                end;                
                fprintf(fout, '  </tr>\n');
                
                fprintf(fout, '  <tr>');
                for c=1:nC
                    cnt1 = cnt1+1;
                    if cnt1 <= nShot
                        fprintf(fout, '<td><font color="blue"> Shot %d: %d-%d</font></td>', cnt1, shots(1,cnt1), shots(2,cnt1));
                    end;
                end;                
                fprintf(fout, '  </tr>\n');
            end
                        
            fprintf(fout, '</table>\n');                                    
            fprintf(fout, '<p>Threads: ');
            for i=1:length(threads)
                fprintf(fout, '['); 
                if length(threads{i}) > 1
                    fprintf(fout, '%d, ', threads{i}(1:end-1));
                    fprintf(fout, '%d', threads{i}(end));
                else
                    fprintf(fout, '%d', threads{i});
                end
                fprintf(fout, ']; ');
            end;
            fprintf(fout, '</p>\n');            
            fprintf(fout, '</html>\n');
            fclose(fout);            
        end;

                
        % Create a gif file from a list of image files
        function createGif(imFiles, outFile)
            border = 5;
            if length(imFiles) < 25
                speed = 2;
            elseif (length(imFiles) >=25) && (length(imFiles) < 50)
                speed = 3;
            else 
                speed = 4;
            end;
                
            idxs = 1:speed:length(imFiles);
            if idxs(end) ~= length(imFiles);
                idxs(end+1) = length(imFiles);
            end;
            
            for j=1:length(idxs)                
                im = imread(imFiles{idxs(j)});                                
                im = imresize(im, [150, NaN]);
                progress = ceil(j/length(idxs)*size(im,2));
                im(end-border+1:end,1:progress,1) = 0;
                im(end-border+1:end,1:progress,2) = 255;
                im(end-border+1:end,1:progress,3) = 0;
                [imind,cm] = rgb2ind(im,256);
                
                if j==1
                    imwrite(imind,cm,outFile,'gif', 'DelayTime', 0, 'Loopcount',inf);
                else
                    imwrite(imind,cm,outFile,'gif', 'DelayTime', 0, 'WriteMode','append');
                end
            end
        end;        
    end    
end

