classdef ML_SlideWin
% Implement efficient sliding window     
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 25-Jul-2015
% Last modified: 25-Jul-2015    
    properties (Access = private)   
        Data;
        winSz;
        stepSz;        
        nBatch;
        winLinIdxs;
        batchLinIdxs;
        batchSubIdxs;
    end
    
    methods
        % Data: multi-dim tensor, let k be the number of dimensions
        %   Special cases: an RGB image is 3-dim tensor, a grayscale image is 2-dim tensor
        % winSz: k*1 vector of positive integers for the windowsize
        %   winSz(i) is the size for dimension i^th. 
        %   For RGB image, winSz = [winH; winW; 3];
        %   For Greyscale image, winSz = [winH; winW];
        % stepSz: k*1 vector of positive integers for the step sizes
        %   For RGB image, stepSz = [vertical_step; horizontal_step; 3];
        % memLimit: memory limit to determine the number of batches 
        %   a number, 1 means 1MB, 2 means 2MB. Default 100MB
        function obj = ML_SlideWin(Data, winSz, stepSz, memLimit)
            % Sanity check
            k = ndims(Data);
            if length(winSz) ~= k || length(stepSz) ~= k
                error('Inconsistent number of dimensions');
            end
            
            [startIdxs, rngIdxs, startCmbn, pixCmbn] = deal(cell(1, k));
            for i=1:k
                % Possible start indexes for dimension i
                startIdxs{i} = 1:stepSz(i):(size(Data,i) - winSz(i)+1);
                
                % Pixel indexes for the dimension i of the first window
                rngIdxs{i} = 1:winSz(i);
            end
            
            [startCmbn{:}] = ndgrid(startIdxs{:}); % Start combination
            [pixCmbn{:}] = ndgrid(rngIdxs{:});     % index combinaion for pixels in first window
            
            for i=1:k                
                % startCmbn{i}(j) is the start index in the dimension i, of the j^th combination
                startCmbn{i} = startCmbn{i}(:);   
                
                % pixCmbn{i}{j} is the index in the dimension i of the j^th pixel of the window
                pixCmbn{i} = pixCmbn{i}(:);
            end;
            
            startLinIdxs = sub2ind(size(Data), startCmbn{:}); % linear indexes of start points            
            obj.winLinIdxs = sub2ind(size(Data), pixCmbn{:}) - 1; % linear indexes of the first window
            
            [startLinIdxs, idxs] = sort(startLinIdxs);
            startCmbn = cat(2, startCmbn{:});
            startCmbn = startCmbn(idxs,:)';
            startLinIdxs = startLinIdxs';
                        
            if ~exist('memLimit', 'var') || isempty(memLimit)
                memLimit = 100;
            end;
            
            % maximum number of elmements for a matrix, assuming double precision (16Bytes)
            maxMatrixSize = memLimit*10^6/16;             
            nWinPerBatch =  floor(maxMatrixSize/length(obj.winLinIdxs));
            nBatch_ = ceil(length(startLinIdxs)/nWinPerBatch);
            
            obj.Data = Data;
            obj.winSz = winSz;
            obj.stepSz = stepSz;      
            obj.nBatch = nBatch_;
            obj.batchLinIdxs = cell(1, nBatch_);
                        
            idxss = ml_kFoldCV_Idxs(length(startLinIdxs), nBatch_, 0);
            for i=1:nBatch_
                obj.batchLinIdxs{i} = startLinIdxs(idxss{i});                
                obj.batchSubIdxs{i} = startCmbn(:, idxss{i});
            end            
        end
        
        % Get the number of batches
        % The number of batches is automatically determined, based on memory limit
        function nBatch = getNBatch(self)
            nBatch = self.nBatch;
        end;
    
        % Get the batch of windows 
        % batchId: ID of the batch
        % D: d*m matrix, d: number of pixels in a window, m: number of windows
        % startLocs: k*m matrix, k: number of dimensions of tensor data
        %   startLocs(i,j) is the pixel index for the i dimension of the j^th window
        function [D, startLocs] = getBatch(self, batchId)
            startLocs = self.batchSubIdxs{batchId};
            A = repmat(self.winLinIdxs, 1, length(self.batchLinIdxs{batchId})) + ...
                repmat(self.batchLinIdxs{batchId}, length(self.winLinIdxs), 1);
            D = self.Data(A);            
        end
    end
    
    methods (Static)
        function demo()
            im = imread('peppers.png'); % Suppose we have an image
            
            % Let consider a small region
            startX = 300;
            startY = 150;
            winH = 40;
            winW = 25;            
            imReg = im(startY:startY+winH-1, startX:startX+winW-1,:);
            subplot(2,2,1); imshow(im);
            ML_RectUtils.drawBoxes([startX, startY, winW, winH]', {'g'});
            title('Location of extracted region');
            subplot(2,2,2); imshow(imReg); title('The region');
            imReg = imnoise(imReg, 'salt & pepper');
            subplot(2,2,3); imshow(imReg); title('Corrupted region');
            
            % Even though the region is corrupted, let's find the best match using a sliding window
            % approach
            im = double(im);
            imReg = double(imReg(:));
            
            winSz_ = [winH; winW; 3]; % window size
            stepSz_ = [10; 5; 1]; % Step size
            
            startT = tic;
            swObj = ML_SlideWin(im, winSz_, stepSz_);            
            [subIdxss, l2dists] = deal(cell(1, swObj.getNBatch()));
            for i=1:swObj.getNBatch()
                % Each column D(:,j) is the vectorized pixels in the sliding window 
                [D, subIdxss{i}] = swObj.getBatch(i); 
                d2 = sum(D.^2, 1);
                l2dists{i} = d2 - 2*imReg'*D;                
            end;
            subIdxs = cat(2, subIdxss{:});
            l2dist = cat(2, l2dists{:}) + sum(imReg.^2);
            
            [~, idx] = min(l2dist);
            bestSubIdx = subIdxs(:,idx);
            bestX = bestSubIdx(2);
            bestY = bestSubIdx(1);
            fprintf('Searching over %d windows takes %gs\n', length(l2dist), toc(startT));
           
            subplot(2, 2, 4); imshow(uint8(im));
            ML_RectUtils.drawBoxes([bestX, bestY, winW, winH]', {'g'}); title('Best match');
        end;        
        
        % Get some random sliding windows and display of a grayscale image
        function demo2()
            im = imread('peppers.png'); % Suppose we have an image        
            im = rgb2gray(im);
            winH = 40;
            winW = 25;            
            winSz_ = [winH; winW]; % window size
            stepSz_ = [10; 5]; % Step size            
            memLimit = 15; % suppose 15MB memory limit
            swObj = ML_SlideWin(im, winSz_, stepSz_, memLimit);            
            
            [randWins, randLocs] = deal(cell(1, swObj.getNBatch()));
            nSamplePerBatch = 10;
            for i=1:swObj.getNBatch()
                % Each column D(:,j) is the vectorized pixels in the sliding window 
                [winD, startLocs] = swObj.getBatch(i); 
                
                randIdxs = randsample(size(winD,2), nSamplePerBatch);
                randWins{i} = winD(:, randIdxs);
                randLocs{i} = startLocs(:, randIdxs);
            end;
            randWins = cat(2, randWins{:});
            randLocs = cat(2, randLocs{:});
            
            % Draw the locations of the random windows
            boxes = [randLocs(2,:); randLocs(1,:)]; 
            boxes(3,:) = winW;
            boxes(4,:) = winH;
            figure; imshow(im); ML_RectUtils.drawBoxes(boxes);
            
            % Display the windows
            figure;
            nC = ceil(sqrt(size(randWins,2)));
            nR = ceil(size(randWins,2)/nC);
            for i=1:size(randWins,2)
                imReg = reshape(randWins(:,i), [winH, winW]);
                subplot(nR, nC, i); 
                imshow(imReg);
            end;
        end;
    end    
end

