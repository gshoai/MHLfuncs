classdef ML_VidShot   
% Shot boundary detection and related functions.
% Currently, only hard-cuts are detected. 
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 10-Oct-2014
% Last modified: 27-Jun-2015
% Required libraries: vl_feat for SIFT and HOG feature computation
    
    methods (Static)
        
        % Detect hard cuts and fade-out transitions (fade to black or white)
        % imFiles: a cell structure for image files, e.g., imFiles = {'im1.jpg', ..., 'im1000.jpg'}
        % shotBndIdxs: a row vector for the begining of the shots.
        %   indexes are counted from 1. E.g., if shotBndIdxs is [10, 42], then there 
        %   are three shots: [1,9] [10, 41], [42, nFrm]
        % This algorithm is based on: HOG, SIFT, and adapative threshold
        function shotBndIdxs = detectCuts(imFiles, verbose)
            nFrm = length(imFiles);
            hogdiff = zeros(1, nFrm -1);
            imIntensity = zeros(1, nFrm - 1);
            
            startT = tic;            
            prevImHog = ML_VidShot.cmpHogFeat(imread(imFiles{1}));
            for i=1:nFrm-1
                if mod(i, 100) == 0
                    fprintf('Shot-boundary detection, hog-diff, frame %d/%d, etime: %g\n', ...
                        i, nFrm-1, toc(startT));
                end;
                im = imread(imFiles{i+1});
                curImHog = ML_VidShot.cmpHogFeat(im);                
                imIntensity(i) = mean(im(:));
                hogdiff(i) = mean(abs(curImHog - prevImHog));
                prevImHog = curImHog;
            end;
                        
            % half window size for adaptive threshold
            wSz = 5;
            meanFilter = ones(1, 2*wSz+1)/(2*wSz+1);
            
            % Compute mean value over 2*wSz+1 window
            padded_hogdiff = zeros(1, 2*wSz + nFrm-1);
            padded_hogdiff(wSz+1:wSz+nFrm-1) = hogdiff;
            padded_hogdiff(1:wSz) = hogdiff(wSz+1:-1:2);
            padded_hogdiff(wSz+nFrm:end) = hogdiff(nFrm-2:-1:nFrm-1-wSz);
            
            % mean value, over 2*wSz+1 window
            mean_hogdiff = conv(padded_hogdiff, meanFilter, 'valid');
            
            % Compute std value over 2*wSz+1 window
            padded_hogdiffSqr = padded_hogdiff.^2;            
            mean_hogdiffSqr = conv(padded_hogdiffSqr, meanFilter, 'valid');
            
            var_hogdiff = sqrt(mean_hogdiffSqr - mean_hogdiff.^2);
                        
            % hogdiff > 0.0715 to prevents still scence + text appearing
            % When this occurs, the difference between hogdiff and
            % mean_hogdiff might be much bigger than the variance
            % var_hogdiff, but the total diff rgbdiff is small             
            % Thresholds from training data (combining SP + Holly Train)
            % 99%: 0.0837, 98.5%: 0.0715, 98%: 0.0642, 97%: 0.0564, 95%: 0.0469
            hogThresh = 0.0715;
            boundary_idxs2 = find(and(hogdiff > hogThresh, hogdiff > mean_hogdiff + 1.5*var_hogdiff)) + 1; 
                       
            
            % Finally, use SIFT matching (expensive) to verify the cut
            % This requires VLFEAT library installed
            isMatch = false(1, length(boundary_idxs2));
            for j=1:length(boundary_idxs2)
                frmIdx = boundary_idxs2(j);
                prevIm = imread(imFiles{frmIdx-1});
                prevIm = single(rgb2gray(prevIm));                
                im = imread(imFiles{frmIdx});                
                im = single(rgb2gray(im));                
                [f1, d1] = vl_sift(im);                
                [f2, d2] = vl_sift(prevIm);       
                
                isMatch(j) = ML_VidShot.isSiftMatch({f1,d1}, {f2,d2}, size(im,1), size(im,2)); 
            end
            boundary_idxs3 = boundary_idxs2(~isMatch);            
                        
            % find boundaries between too dark or too bright regions
            blackInds = imIntensity < 20;
            blackInds = find(diff(blackInds)) + 2; 
            whiteInds = imIntensity > 235;
            whiteBnds = find(diff(whiteInds)) + 2; 
            
            % combine hardcuts and fade-out-to-black and fade-out-to-white transitions
            shotBndIdxs = unique(cat(2, boundary_idxs3, blackInds, whiteBnds));
                        
            if exist('verbose', 'var') && verbose 
                fprintf('#boundaries: %d\n', length(shotBndIdxs));
                fprintf('  boundary idxs: '); fprintf('%d ', shotBndIdxs); fprintf('\n');                            
            end;                        
        end;
                        
        function hogFeat = cmpHogFeat(im)
            nHBin = 12;
            nWBin = 16;
            cellSz = 8;            
            im = imresize(im, cellSz*[nHBin, nWBin]);
            %hogFeat = features(double(im), cellSz);
            hogFeat = vl_hog( single(im), cellSz);
            hogFeat = hogFeat(:);
        end;
        
        % Matching SIFT points computed for two near-duplicate images
        % f1d1 is a 1*2 cell of f1, d1 for sift points and sift descriptors
        function [isMatch, nMatch] = isSiftMatch(f1d1, f2d2, imH, imW)
            nMatchThresh = 40;
            xThresh = imW/4;
            yThresh = imH/4;
            
            [matches, ~] = vl_ubcmatch(f1d1{2}, f2d2{2}) ; % matching descriptor         
            
            % location of the matched points
            f1 = f1d1{1}(:, matches(1,:));
            f2 = f2d2{1}(:, matches(2,:));
            
            xDiff = f1(1,:) - f2(1,:);
            yDiff = f1(2,:) - f2(2,:);
            isGood = and(abs(xDiff) < xThresh, abs(yDiff) < yThresh);            
            nMatch = sum(isGood);            
            %isMatch = nMatch >= max(nMatchThresh, 0.1*min(size(f1d1{1},2), size(f2d2{1},2)));            
            isMatch = nMatch >= nMatchThresh;
        end;
        
        function [isMatch, hogDiff] = isHogMatch(im1, im2)
            hog1 = MNC_ShotBndDet.cmpHogFeat(im1); 
            hog2 = MNC_ShotBndDet.cmpHogFeat(im2);             
            hogDiff = mean(abs(hog1(:) - hog2(:)));
            % Thresholds from training data (combining SP + Holly Train)
            % 99%: 0.0837, 98.5%: 0.0715, 98%: 0.0642, 97%: 0.0564, 95%: 0.0469
            isMatch = hogDiff <= 0.0715;
        end;
    end    
end
