classdef ML_Hist
% Compute histogram or spatial pyramid histogram
% This supports segmentation mask
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 16-Nov-2014
% Last modified: 16-Nov-2014

    methods (Static)                
        % Code: a h*w*nBlock, a 3D array
        %   Code(:,:,i) is the clustering centroids for block i.        
        %   The values of Code are from 1 to nClust
        % nClust: number of cluster per blocks
        % regRect: left, top, right, bottom
        % levelWs: weights for different levels from 0,..., nLevel-1.               
        %   levek k: (2^k)*(2^k) cells
        %   nLevel = length(levelWs), from 0, ..., nLevel-1 levels        
        % mask: logical mask image
        function histo = cmpPyrHist(Code, nClust, regRect, levelWs, mask)
            nLevel = length(levelWs);
            [h, w, nBlock] = size(Code);
            
            if isempty(regRect)
                histo = zeros(nClust*nBlock*sum(4.^(0:(nLevel-1))), 1);
                return;
            end
            
            if ~exist('mask', 'var')
                mask = true(h, w);
            end;
            
            % compute recursively

            % base case
            if nLevel == 1                
                histo = levelWs(1)*ML_Hist.cmpHist(Code, nClust, regRect, mask);
                return;
            end
            
            % more than one level
            left   = regRect(1);
            top    = regRect(2);
            right  = regRect(3);
            bottom = regRect(4);
            mid_x  = floor((left + right)/2);
            mid_x1 = mid_x + 1;
            mid_y  = floor((top + bottom)/2);
            mid_y1 = mid_y + 1;
            
            
            histos = cell(1, 4);            
            squares{1} = [left,   top,    mid_x, mid_y];
            squares{2} = [left,   mid_y1, mid_x, bottom];
            squares{3} = [mid_x1, top,    right, mid_y];
            squares{4} = [mid_x1, mid_y1, right, bottom];
            
            for i=1:4
                histos{i} = ML_Hist.cmpPyrHist(Code, nClust, squares{i}, levelWs(2:end), mask);
            end
            histos = cat(2, histos{:});
            histo_top = sum(histos(1:nClust*nBlock,:), 2);
            histo_top = levelWs(1)/levelWs(2)*histo_top; %adjust weight;
                        
            % append all histograms
            histo = cat(1, histo_top, histos(:));            
        end            

        
        
        % Code: a h*w*nBlock, a 3D array
        %   Code(:,:,i) is the clustering centroids for block i.        
        %   The values of Code are from 1 to nClust
        % nClust: number of cluster per blocks
        % regRect: left, top, right, bottom
        function histo = cmpHist(Code, nClust, regRect, mask)
            [h, w, nBlock] = size(Code);
            left   = regRect(1);
            top    = regRect(2);
            right  = regRect(3);
            bottom = regRect(4);

            if ~exist('mask', 'var')
                [X_idxs, Y_idxs] = meshgrid(left:right, top:bottom);
            else
                [X, Y] = meshgrid(left:right, top:bottom);
                regRect_mask = mask(top:bottom, left:right);
                Y_idxs = Y(regRect_mask);
                X_idxs = X(regRect_mask);                
            end
            linIdxs = sub2ind([h,w], Y_idxs(:), X_idxs(:));            
            
            histos = cell(1, nBlock);
            for i=1:nBlock
                Code_i = Code(:,:,i);
                histos{i} = hist(Code_i(linIdxs), 1:nClust);
            end;
            histo = cat(2, histos{:})';
        end        
        
        function test()
            % Suppose we extract the im size is 120*160 and we extract
            % SIFT descriptors at every 4 pixels: 1, 5, ..., 
            % and the values are given in Code
            % Suppose the nClust is 128
            % The region to compute the Spatial pyramid is 
            %   [20; 30; 100; 80]; % left, top, right, bottom
            % The BOW encodes for the descriptors are Code
            Code = randi([1, 128], [30, 40]); % correspond to image 120*160, where SIFT are extracted at every 4 pixel
            regRect = [20; 30; 100; 80]; % in the orignal imagfe space
            
            % Here is how to compute Spatial Pyramid Code:
            
            % Step 1, get the correct values for the new region
            % new coordinate, because SIFTs are extraced every 4 pixel
            regRect2 = regRect;
            regRect2(1:2) = ceil(regRect(1:2)/4); 
            regRect2(3:4) = ceil(regRect(3:4)/4);
            nClust =128;
            
            % Normal histogram
            hist0 = ML_Hist.cmpHist(Code, nClust, regRect2);

            % Pyramid histogram
            hist1 = ML_Hist.cmpPyrHist(Code, nClust, regRect2, [0.25, 0.25, 5]);
            
            
        end;
        
    end    
end

