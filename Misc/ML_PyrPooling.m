classdef ML_PyrPooling
% Multi-dimensional Pyramid pooling
% Special cases: spatial pyramid, temporal pyramid, spatio-temporal pyramid pooling
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 14-Jul-2015
% Last modified: 14-Jul-2015    
    
    methods (Static)        
        % FeatLocs: k*n matrix, each column is a k-dim location vector.
        %   k could be any positive number, special cases are: 
        %       k = 1, temporal pooling
        %       k = 2, sptial pooling
        %       k = 3, spatio-temporal pooling        
        % FeatVecs: d*n matrix, each column is a feature vector
        % poolArea: k*2 matrix, pool(i,:) is the [min,max] of the pooling area for dimension i.
        % poolMethod: either 'mean', 'max', 'sum', 'min'
        % levelWs: nLevel*1 weight vector. Compute a pyramid of nLevel. 
        % emptyPolicy: {'inf', '-inf', 'zero', 'error'}
        %   What to do when there is a cell in the pyramid has no feature points inside
        %   error: output error
        %   zero: return a zero vector
        %   inf, -inf: return a inf/-inf vector
        % Outputs:
        %   poolVec: d*1 vector for the pooled feature or [] if there is no features in the poolArea
        %   nFeatInArea: number of features in the area
        function [poolVec, nFeatInArea] = pyrPool(FeatLocs, FeatVecs, poolArea, poolMethod, levelWs, emptyPolicy)
            nLevel = length(levelWs);
            k = size(FeatLocs, 1);
            d = size(FeatVecs, 1);

            % base case
            if nLevel == 1                
                [poolVec, nFeatInArea] = ...
                    ML_PyrPooling.pool(FeatLocs, FeatVecs, poolArea, poolMethod);
                poolVec = poolVec*levelWs(1);
                if isempty(poolVec)
                    if strcmpi(emptyPolicy, 'zero') 
                        poolVec = zeros(d, 1);
                    elseif strcmpi(emptyPolicy, 'inf') 
                        poolVec = inf(d, 1);
                    elseif strcmpi(emptyPolicy, '-inf') 
                        poolVec = -inf(d, 1);
                    else
                        error('a pooling area is empty');
                    end                        
                end                    
                return;
            end
            
            % compute recursively
            midPnts = mean(poolArea,2);            
            poolAreas = [poolArea(:,1), midPnts, midPnts + eps, poolArea(:,2)];
            
            poolVecs = cell(1, 2^k);
            nF = zeros(1, 2^k);
            for i=1:2^k  
                divIdxs = zeros( 1, k);
                for j=1:k
                    divIdxs(j) = bitget(i,j);                    
                end                
                
                minAreaIdxs = sub2ind([k, 4], 1:k, 2*divIdxs + 1);
                maxAreaIdxs = sub2ind([k, 4], 1:k, 2*divIdxs + 2);
                poolArea_i = [poolAreas(minAreaIdxs)', poolAreas(maxAreaIdxs)'];
                
                [poolVecs{i}, nF(i)] = ML_PyrPooling.pyrPool(FeatLocs, FeatVecs, poolArea_i, ...
                    poolMethod, levelWs(2:end), emptyPolicy);                
            end;
                        
            poolVecs = cat(2, poolVecs{:});
            nFeatInArea = sum(nF);
            if strcmpi(poolMethod, 'sum')
                poolVec_top = sum(poolVecs(1:d,:), 2);
            elseif strcmpi(poolMethod, 'max')
                poolVec_top = max(poolVecs(1:d,:), [], 2);
            elseif strcmpi(poolMethod, 'min')
                poolVec_top = min(poolVecs(1:d,:), [], 2);
            elseif strcmpi(poolMethod, 'mean')
                poolVec_top = sum(poolVecs(1:d,:).*repmat(nF, d, 1), 2)/nFeatInArea;
            else
                error('ML_PyrPooling.pyrPool: Unkown pooling option');
            end;
            poolVec_top = levelWs(1)/levelWs(2)*poolVec_top;                        
            poolVec = cat(1, poolVec_top, poolVecs(:));            
        end
        
        % FeatLocs: k*n matrix, each column is a k-dim location vector.
        %   k could be any positive number, special cases are: 
        %       k = 1, temporal pooling
        %       k = 2, sptial pooling
        %       k = 3, spatio-temporal pooling        
        % FeatVecs: d*n matrix, each column is a feature vector
        % poolArea: k*2 matrix, pool(i,:) is the [min,max] of the pooling area for dimension i.
        % poolMethod: either 'mean', 'max', 'sum', 'min'
        % Outputs:
        %   poolVec: d*1 vector for the pooled feature or [] if there is no features in the poolArea
        %   nFeatInArea: number of features in the area
        function [poolVec, nFeatInArea] = pool(FeatLocs, FeatVecs, poolArea, poolMethod)
            n = size(FeatLocs, 2);
            A = cat(1, FeatLocs >=  repmat(poolArea(:,1), 1, n), ...
                       FeatLocs <=  repmat(poolArea(:,2), 1, n));
            inPoolAreaIdxs  = all(A,1); % indexes of features in the pool area
            nFeatInArea = sum(inPoolAreaIdxs);
            if nFeatInArea > 0
                if strcmpi(poolMethod, 'mean')
                    poolVec = mean(FeatVecs(:,inPoolAreaIdxs), 2);
                elseif strcmpi(poolMethod, 'max')
                    poolVec = max(FeatVecs(:,inPoolAreaIdxs), [], 2);
                elseif strcmpi(poolMethod, 'min')
                    poolVec = min(FeatVecs(:,inPoolAreaIdxs), [], 2); 
                elseif strcmpi(poolMethod, 'sum')
                    poolVec = sum(FeatVecs(:,inPoolAreaIdxs), 2);
                else
                    error('ML_PyrPooling.pool: Unkown pooling option');
                end
            else
                poolVec = [];
            end;
        end                   
    end    
    
    methods (Static, Access = private)
        function test1()
            FeatLocs = [1 1 2 2;
                        1 2 1 2];
            FeatVecs = eye(4);
            poolVec = ML_PyrPooling.pool(FeatLocs, FeatVecs, [1, 2; 1, 2], 'sum');
            poolVec = ML_PyrPooling.pool(FeatLocs, FeatVecs, [1, 2; 1, 2], 'mean');            
            poolVec = ML_PyrPooling.pyrPool(FeatLocs, FeatVecs, [1, 2; 1, 2], 'sum', [1 1 1], 'zero');            
        end
        
        function test2()
            imH = 20;
            imW = 30;
            nBin = 10;
            im = randi(nBin, [imH, imW]); % a random assignment of pixels to histogram bin
            [X, Y] = meshgrid(1:imW, 1:imH);
            FeatVecs = zeros(nBin, numel(im));
            FeatVecs(sub2ind([nBin, numel(im)], im(:)', 1:numel(im))) = 1;
            FeatLocs = [X(:)'; Y(:)'];
            poolVec = ML_PyrPooling.pool(FeatLocs, FeatVecs, [1, imW; 1, imH], 'sum');            
            poolVec = ML_PyrPooling.pyrPool(FeatLocs, FeatVecs, [1, imW; 1, imH], 'mean', [1, 1, 1], 'zero');            
        end;        
        
        function test3()
            imH = 480;
            imW = 640;
            
            n = 1000;
            d = 10;
            FeatLocs = [randi(imW, [1, n]); randi(imH, [1, n])];
            FeatVecs = randn(d, n);
            
            poolVec1 = ML_PyrPooling.pool(FeatLocs, FeatVecs, [imW/2+eps, imW; 1, imH/2], 'max');            
            poolVec2 = ML_PyrPooling.pool(FeatLocs, FeatVecs, [1, imW/2; 1, imH/2], 'max');
            pyrPoolVec = ML_PyrPooling.pyrPool(FeatLocs, FeatVecs, [1, imW; 1 imH], 'max', [1, 1], 'zero');            
            
            err1 = sum(abs(pyrPoolVec(d+1:2*d) - poolVec1));
            err2 = sum(abs(pyrPoolVec(end-d+1:end) - poolVec2));
            fprintf('errs should be close to zero, err1: %g, err2: %g\n', err1, err2);            
        end;        

    end
end

