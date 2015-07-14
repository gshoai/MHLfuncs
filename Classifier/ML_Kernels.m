classdef ML_Kernels
% Compute kernels    
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Last modified: 23-Nov-2012    
    
    methods (Static)
        % Inputs:
        %   trD, valD: d*nTr, d*nTst matrices
        % Outputs:
        %   Dist:  nTr*nTst matrix for the distance between trD and valD        
        function Dist = cmpDist(trD, valD, kerType)
            switch kerType
                case 'X2'                    
                    nTr = size(trD, 2);
                    parfor i=1:nTr
                        if mod(i, 500) == 0
                            fprintf('cmp X2 kernel: i %d/%d\n', i, nTr);
                        end
                        Dist(i,:)  = m_mexCmpX2kernel_helper(valD, trD(:,i));                        
                    end;
                case 'rbf'
                    Dist  = ml_sqrDist(trD, valD);                    
                otherwise
                    error('unknown option');
            end;
        end;
        
        % Inputs:
        %   trD, valD: d*nTr, d*nTst matrices
        % Outputs:
        %   trK:  nTr*nTr matrix
        %   valK: nVal*nTr matrix        
        function [trK, valK, k_gamma] = cmpKernels(trD, valD, params)
            nTr = size(trD,2);
            nVal = size(valD,2);
            
            if strcmpi(params.type, 'inter')                
                %x take 35s for nTr = 3000, nVal = 3000, d = 256;
                trK = zeros(nTr, nTr);
                valK = zeros(nTr, nVal);

                parfor i=1:nTr
                    trK(i,:)  = sum(min(trD,  repmat(trD(:,i), 1, nTr)), 1);
                    valK(i,:) = sum(min(valD, repmat(trD(:,i), 1, nVal)), 1);
                end
            elseif strcmpi(params.type, 'X2-matlab') 
                % This is actually Exponential X2: k(x,y) - exp(-sum((x-y).^2/(x+y))/gamma);
                % this is slow, use 'X2' instead.
                % take 25s for nTr = 3000, nVal = 3000, d = 256;
                
                trK = zeros(nTr, nTr);
                valK = zeros(nTr, nVal);                
                parfor i=1:nTr
                    R = repmat(trD(:,i), 1, nTr);
                    trK(i,:) = sum(((trD - R).^2)./(trD + R + eps), 1);
                    
                    R = repmat(trD(:,i), 1, nVal);
                    valK(i,:) = sum(((valD - R).^2)./(valD + R + eps), 1);
                end;
                
                
                if ~isempty(params.gamma)
                    k_gamma = params.gamma;
                else
                    k_gamma = mean(trK(:));
                    fprintf('default gamma: %g\n', k_gamma);
                end

                trK  = exp(-trK/k_gamma);
                valK = exp(-valK/k_gamma);                
            elseif strcmpi(params.type, 'X2') 
                % This is actually Exponential X2: k(x,y) - exp(-sum((x-y).^2/(x+y))/gamma);
                % This not-so-accurate name stucks because of historical reason                
                % Same with X2-matlab but faster and uses much less memory
                trK = zeros(nTr, nTr);
                valK = zeros(nTr, nVal);                
                parfor i=1:nTr     
                    if mod(i, 1000) == 0
                        fprintf('cmp X2 kernel: i %d/%d\n', i, nTr);
                    end
                    trK(i,:)  = m_mexCmpX2kernel_helper(trD, trD(:,i)); 
                    valK(i,:) = m_mexCmpX2kernel_helper(valD, trD(:,i)); 
                end;
                
                if ~isempty(params.gamma)
                    k_gamma = params.gamma;
                else
                    k_gamma = mean(trK(:));
                    fprintf('default gamma: %g\n', k_gamma);
                end

                trK  = exp(-trK/k_gamma);
                valK = exp(-valK/k_gamma);                
            elseif strcmpi(params.type, 'chi2') % true Chi-square: k(x,y) = sum(2*(x.*y)./(x + y));
%                 trK = zeros(nTr, nTr);
%                 valK = zeros(nTr, nVal);
%                 parfor i=1:nTr     
%                     if mod(i, 1000) == 0
%                         fprintf('cmp chi2 kernel: i %d/%d\n', i, nTr);
%                     end
%                     trK(i,:)  = vl_alldist2(trD, trD(:,i), 'kchi2'); 
%                     valK(i,:) = vl_alldist2(valD, trD(:,i), 'kchi2'); 
%                 end;
                trK  = vl_alldist2(trD, trD, 'kchi2');
                valK = vl_alldist2(trD, valD, 'kchi2');
            elseif strcmpi(params.type, 'aChi2') % approx Chi-square k(x,y) = sum(2*(x.*y)./(x + y));                
                mapTrD = vl_homkermap(trD, params.N);
                mapValD = vl_homkermap(valD, params.N);
                trK = mapTrD'*mapTrD;
                valK = mapTrD'*mapValD;                
            elseif strcmpi(params.type, 'hellinger')                
                trD = sqrt(trD);
                valD = sqrt(valD);
                trK = trD'*trD;
                valK = trD'*valD;
            elseif strcmpi(params.type, 'linear')
                trK = trD'*trD;
                valK = trD'*valD;
            elseif strcmpi(params.type, 'rbf')
                sqrDist = ml_sqrDist(trD, trD);
                if ~isempty(params.gamma)
                    k_gamma = params.gamma;
                else
                    k_gamma = mean(sqrDist(:));
                    fprintf('default gamma: %g\n', k_gamma);
                end                
                trK = exp(-sqrDist/k_gamma);                
                clear sqrDist;                
                valK = exp(-ml_sqrDist(trD, valD)/k_gamma);                
            else
                error('unknown params.type');
            end;
            valK = valK';                        
        end        
    end    
end

