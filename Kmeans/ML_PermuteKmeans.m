classdef ML_PermuteKmeans
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Created: 21-Mar-2013
% Last modified: 21-Mar-2013
% 
% K-means with permutatable set of feature vectors.
% Suppose each data point is associated with multiple (m) feature vectors.
% Given these feature vectors, we can concatenate them into a single feature vector and do k-means. 
% Furthermore, we allows the order of concatenation to be artitary. 
% This code outputs a k-means cluster model and the best permuation for each data point. 
%
% An example for the benefit of this code:
% Suppose we want to build a cluster model for face orientations
% Conceptually, we want 4 clusters: profile-left, frontal-left, profile-right, frontal-right
% We know that profile-left and profile-right are dual of each other, i.e., if a face belongs
% to the profile-left then the left-right flipped image should belong to the profile-right. 
% Similarly, frontal-left and frontal-right are dual clusters. 
% How do we build a cluster model with guaranteed duality? 
% One can build the model by dividing the images into left-facing and right-facing subsets,
% and build an two-cluster model for each subset. However, left-facing and right-facing division
% is not trivia, i.e., an image is assigned to frontal-left at first might be better assigned
% to frontal-right later. 
%
% This codes solves this problem. It outputs k groups of duality clusters. 
% Each cluster is represented by a mean vector, which is essentially the concatenation of m 
% clusters that belong to the same duality groups. 
% To use this code for the above usecase, we will need to construct two feature vectors for
% each face image, once for the original face and once for the left-right flipped face.
  
    methods (Static)
        % D: (m*d)*n matrix for n data point, m feature vectors of dim d
        % m: number of feature vectors per point
        % k: number of clusters
        % mus: (m*d)*k matrix for k mean vectors for k groups of clusters
        % clustAssgn: 1*n vector for cluster assignment, values are from 1 to k
        % grpPerm: m*n matrix for permuation
        %   grpPerm(:,i) is a permuation of 1:m. The j-th vector of mus(:,i) should be mapped to
        %   the grpPerm(j,i)-th of D(:,i)
        % sse: 1*n for sum of squared errors. sse(i) is the sum of squared error from D(:,i)
        %   to the corresponding centroid (take into account the best permuation).
        function [mus, clustAssgn, grpPerm, sse] = cluster(D, m, k)
            tol     = 1e-4;
            maxIter = 100;

            mus = vgg_kmeans(D, k, 'verbose', 0); % initialization with vgg_kmeans            
            n = size(D, 2);
            d = size(D,1)/m;
            
            clustAssgn = zeros(1,n);            
            grpPerm    = zeros(m, n);
            sse        = zeros(1, n);
            totalSse_old = inf; 
            if m==2
                D_flip = [D(d+1:end,:); D(1:d,:)];
            end;
                
            for iter=1:maxIter
                %fprintf('iter %d\n', iter);
                % update the assignment and permuation                                
                if m == 2 % special case, optimize for speed
                    Dist1 = ml_sqrDist(D, mus);
                    Dist2 = ml_sqrDist(D_flip, mus);
                    [minVal1, idxs1] = min(Dist1, [], 2);
                    [minVal2, idxs2] = min(Dist2, [], 2);
                    
                    flipIdxs = minVal2 < minVal1; 
                    grpPerm(1,:) = 1;
                    grpPerm(2,:) = 2;
                    grpPerm(1, flipIdxs) = 2;
                    grpPerm(2, flipIdxs) = 1;
                    clustAssgn = idxs1;
                    clustAssgn(flipIdxs) = idxs2(flipIdxs);
                    sse = minVal1;
                    sse(flipIdxs) = minVal2(flipIdxs);

                else % general case
                    Dist = ml_sqrDist(reshape(D, d, m*n), reshape(mus, d, m*k));                
                    for i=1:n
                        assignment = cell(1,k);
                        cost = zeros(1,k);
                        for j=1:k
                            % distance between vectors of D(:,i) to vectors of mus(:,j)
                            Dist_ij = Dist(1+(i-1)*m:i*m, 1+(j-1)*m:j*m);
                            [assignment{j}, cost(j)] = assignmentoptimal(Dist_ij');                                                
                        end;
                        [sse(i), clustAssgn(i)] = min(cost);
                        grpPerm(:,i) = assignment{clustAssgn(i)};                    
                    end                    
                end
                totalSse = sum(sse);
                if totalSse > (1-tol)*totalSse_old % decresase is small, stop
                    break;
                else
                    totalSse_old = totalSse;
                end;
                                
                % update the mean
                D_perm = ML_PermuteKmeans.permute(D, grpPerm);
                for i=1:k
                    mus(:,i) = mean(D_perm(:, clustAssgn == i), 2);
                end;                
            end;        
        end;
        
        % Permute the data using grpPerm
        function D_perm = permute(D, grpPerm)            
            [m,n] = size(grpPerm);
            d = size(D,1)/m;
            noPermIdxs = mat2cell((1:d*m)', d*ones(m,1), 1);
            D_perm = D;
            for i=1:n
                permIdxs = cat(1,noPermIdxs{grpPerm(:,i)});
                D_perm(:,i) = D(permIdxs, i);
            end;
        end;
        
        function test2()
            d = 2;
            n = 100;
            m = 4;
            Ds = cell(1, m);
            Ds{1} = randn(d, n);
%             flipPnts = [5 5; -4 -4; 5 -5]';            
            flipPnts = [2 2; -2 -2; 2 -2]';            
            for i=2:m
                Ds{i} = repmat(flipPnts(:,i-1), 1, n) - Ds{1};
            end
            D = cat(1, Ds{:});
            k = 3;
            [mus, clustAssgn, grpPerm] = M_PermuteKmeans.cluster(D, m, k);
                        
            clf;
            subplot(1,2,1);            
            colors = {'+r', '.b', 'k', '*m'};
            for i=1:m
                scatter(Ds{i}(1,:), Ds{i}(2,:), colors{i}); hold on;
            end;
            
            subplot(1,2,2); hold on;
            markers = {'+', '.', '', '*'};
            colors = {'r', 'b', 'k', 'm'};
            for i=1:k
                D_perm = M_PermuteKmeans.permute(D, grpPerm);
                clustAssgn_i = clustAssgn == i;
                
                for j=1:m
                    color = sprintf('%s%s', markers{j}, colors{i});
                    scatter(D_perm(2*j-1, clustAssgn_i), D_perm(2*j, clustAssgn_i), color);
                end
            end;
            title('same color: same duality group');
        end;
        
        function test1()
            d = 2;
            n = 100;
            D1 = randn(d, n);
            D2 = 1 - D1;
            D = cat(1, D1, D2);
            k = 2;
            m = 2;
            [mus, clustAssgn, grpPerm] = M_PermuteKmeans.cluster(D, m, k);
            
            clf;
            B1 = D1;
            B2 = D2;
            for i=1:size(D,2)
                if grpPerm(1,i) == 1
                    B1(:,i) = D1(:,i);
                    B2(:,i) = D2(:,i);
                else
                    B2(:,i) = D1(:,i);
                    B1(:,i) = D2(:,i);
                end
            end
            
            clf;
            subplot(1,2,1);            
            scatter(D1(1,:), D1(2,:), '+r'); hold on;
            scatter(D2(1,:), D2(2,:), '.b');            
            axis ij equal; 
            title('+: non-flip, o: flip');
            subplot(1,2,2);
            colors1 = {'+r', 'k'};
            colors2 = {'+b', 'm'};
            for i=1:k
                scatter(B1(1,clustAssgn==i), B1(2,clustAssgn==i), colors1{i}); hold on;
                scatter(B2(1,clustAssgn==i), B2(2,clustAssgn==i), colors2{i}); 
            end
            axis ij equal; 
        end;
    end    
end
