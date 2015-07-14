classdef ML_IDTD
% Compute improved dense trajectory descriptors
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 10-Oct-2014
% Last modified: 10-Oct-2014

    properties (Constant)
        % Based on Improved DTD, ICCV13 paper of Heng Wang and Cordelia Schmid
        denseTrackBin = '~/Study/Libs/improved_trajectory_release_mod/release/m_DenseTrackStab';
        export_cmd = 'export LD_LIBRARY_PATH=/usr/local/lib/:/users/omkar/arnie/lib/:/users/minhhoai/local/lib/opencv_old/:/opt/gridware/pkg/compilers/gcc/4.7.1/lib64/:/users/minhhoai/local/openblas/lib/:/users/omkar/local_new/lib:/users/omkar/local_new/lib/boost:/users/alonso/local/lib/';
    end
        
    methods (Static)                
        % frmExt: 'jpg', 'png' or what?
        % frmIdxs: indexes of the frames to encode a Fisher vector feature
        % gmmModelFile: 
        function fv = fvEncode4dir(frmDir, frmExt, frmIdxs, gmmModelFile)
            tmpDir = sprintf('%s/tmp_%s', frmDir, ml_randStr()); 
            cmd = sprintf('mkdir -p %s', tmpDir);
            fprintf('%s\n', cmd);
            system(cmd);
            
            imFiles = ml_getFilesInDir(frmDir, frmExt);
            frmPattern = sprintf('%s/%%06d.png', tmpDir);
            for i=1:length(frmIdxs)
                cmd = sprintf('cp %s %s', imFiles{frmIdxs(i)},  sprintf(frmPattern, i));
                fprintf('%s\n', cmd);
                system(cmd);
            end;
            fv = ML_IDTD.fvEncode4pattern(frmPattern, length(frmIdxs), gmmModelFile);
            cmd = sprintf('rm -rf %s', tmpDir);
            fprintf('%s\n', cmd);
            system(cmd);
        end;
        
        % Fisher vector encoding for a set of frames
        function fv = fvEncode4pattern(frmPattern, nFrm, gmmModelFile)
            [~,frmDir] = ml_full2shortName(frmPattern);            
            % Compute DTD feature file, store in a temp file
            tmpDtdFilePrefix = sprintf('%s/dtdFeat_%s', frmDir, ml_randStr());
            tmpDtdFiles = ML_IDTD.cmpDTD(frmPattern, nFrm, tmpDtdFilePrefix);
            descTypes = {'trajXY', 'trajHog', 'trajHof', 'trajMbh'};            

            % Load the pre-learned GMM model
            load(gmmModelFile, 'GMM', 'PCA');
            ns = zeros(1, length(tmpDtdFiles));
                        
            for i=1:length(tmpDtdFiles)
                % Load DTD features and convert to double format            
                A = load(tmpDtdFiles{i});
                ns(i) = size(A.trajXY,1);
                if ns(i) == 0
                    continue;
                end;
                A.trajXY = double(A.trajXY')/A.trajXY_scale;            
                for j=2:length(descTypes)
                    A.(descTypes{j}) = double(A.(descTypes{j})')/A.desc_scale;
                end;
                
                % Apply PCA and all VL_FEAT for fisher vector encoding
                for j=1:length(descTypes)
                    % apply PCA first
                    PCA_j = PCA.(descTypes{j});
                    A.(descTypes{j}) = A.(descTypes{j}) - repmat(PCA_j.mu, 1, size(A.(descTypes{j}),2));
                    A.(descTypes{j}) = PCA_j.PcaBasis'*A.(descTypes{j});
                                     
                    % get fisher vector
                    GMM_j = GMM.(descTypes{j});
                    fvs(i).(descTypes{j}) = vl_fisher(A.(descTypes{j}), GMM_j.mus, GMM_j.covs, GMM_j.priors);                
                end;                
            end
            
            % combine feature vectors for each parts into a double feature vector
            for j=1:length(descTypes)
                fv_j = 0;                
                for i=1:length(tmpDtdFiles)
                    if ns(i) > 0 
                        fv_j = fv_j + ns(i)*fvs(i).(descTypes{j});
                    end;
                end;          
                fv.(descTypes{j}) = fv_j/sum(ns);
            end;
            
            % Power-law normalized, alpha = 0.5
            for j=1:length(descTypes)
                fv.(descTypes{j}) = sign(fv.(descTypes{j})).*sqrt(abs(fv.(descTypes{j})));
            end;
            
            % L2 normalized
            for j=1:length(descTypes)
                L2_norm = sqrt(sum(fv.(descTypes{j}).^2));
                fv.(descTypes{j}) = fv.(descTypes{j})/L2_norm;
            end;
            fv.nTraj = sum(ns);            
            
            % Delete the temp DTD file 
            for i=1:length(tmpDtdFiles)
                cmd = sprintf('rm -rf %s', tmpDtdFiles{i});
                fprintf('%s\n', cmd);
                system(cmd);
            end
            
            if sum(ns) == 0
                fv = [];
            end;
        end;

        % Compute DTD features for a set of frames and save it into one or multiple files
        % If necessary the sequence of frames is divided in to batches
        % to overcome the problem of memory constraint due to lots of frames
        % frmPattern: frame pattern, e.g., '.BigBangTheory/frm%06d.jpg'
        % nFrm: number of frames
        % outFilePrefix: file name without the extension. 
        % Outputs:
        %   outFiles: a list of Mat files 
        function outFiles = cmpDTD(frmPattern, nFrm, outFilePrefix)
            maxFrmPerBatch = 125; % correspond to 5s
            nFrmPerTraj = 15;            
            nBatch = ceil((nFrm - maxFrmPerBatch)/(maxFrmPerBatch + 1 - nFrmPerTraj)) + 1;
            
            outFiles = cell(1, nBatch);
            for i=1:nBatch
                startIdx = (i-1)*(maxFrmPerBatch + 1 - nFrmPerTraj) + 1;
                endIdx   = (i-1)*(maxFrmPerBatch + 1 - nFrmPerTraj) + maxFrmPerBatch;
                endIdx   = min(endIdx, nFrm);
                
                % DTD extract trajectories by dense sampling at the beginning and then track.
                % When we call DTD code for each batch, the beginning often has more trajectories 
                % than the end. Thus, we extends the beginning of the batch and then remove
                % irrelevant trajectories                
                extStartIdx = max(startIdx - 2*nFrmPerTraj, 1);                 
                
                outFilePrefix_i = sprintf('%s_%06d-%06d', outFilePrefix, startIdx, endIdx);
                outDtdFile = ML_IDTD.cmpDTD_helper(frmPattern, extStartIdx, endIdx, outFilePrefix_i);
                
                load(outDtdFile, 'trajLen', 'trajXY_scale', 'desc_scale', 'trajStat', 'trajXY', ...
                    'trajHog', 'trajHof', 'trajMbh');
                if ~isempty(trajStat)
                    validIdxs = trajStat(:,1) >= startIdx + nFrmPerTraj - 1;                
                    trajLen  = trajLen(validIdxs);
                    trajStat = trajStat(validIdxs, :);
                    trajXY   = trajXY(validIdxs, :);
                    trajHog  = trajHog(validIdxs, :);
                    trajHof  = trajHof(validIdxs, :);
                    trajMbh  = trajMbh(validIdxs, :);                    
                end
                                
                save(outDtdFile, 'trajLen', 'trajXY_scale', 'desc_scale', 'trajStat', 'trajXY', ...
                    'trajHog', 'trajHof', 'trajMbh', '-v7.3');
                outFiles{i} = outDtdFile;
            end;
        end
        
        % Compute improved dense trajectory descriptors and save them into a file
        % frmPattern: e.g., '.BigBangTheory/frm%06d.jpg'
        % outFilePrefix: file name without the extension. 
        % humanDetFile: use human detection results for finding background motion
        % Outputs:
        %   outFile: the output Mat file that contain dense trajectory descriptors        
        function outFile = cmpDTD_helper(frmPattern, startIdx, endIdx, outFilePrefix, humanDetFile)
            defTrajLen = 15;
            minTrajLen = 3; % if lower number is used, the value could be nan
            if ~isempty(startIdx)
                startOpt = sprintf('-S %d', startIdx);
            else
                startOpt = '';
            end
            if ~isempty(endIdx)
                endOpt = sprintf('-E %d', endIdx);
            else
                endOpt = '';
            end;
            
            if ~isempty(startIdx) && ~isempty(endIdx) && (endIdx - startIdx + 1) < defTrajLen 
                trajLen = endIdx - startIdx + 1;                
            else
                trajLen = defTrajLen;
            end;
            trajLen = max(trajLen, minTrajLen);
            
            if exist('humanDetFile', 'var') && ~isempty(humanDetFile)
                humanDetOpt = sprintf('-H %s', humanDetFile);
            else
                humanDetOpt = '';
            end;
            
            % output to text file first
            cmd = sprintf('%s; %s %s %s %s -L %d %s> %s', ...
                ML_IDTD.export_cmd, ML_IDTD.denseTrackBin, frmPattern, ...
                startOpt, endOpt, trajLen, humanDetOpt, sprintf('%s.txt', outFilePrefix));
            fprintf('%s\n', cmd);
            system(cmd);            
            
            % encode to save memory footprint, reduce the footfprint by a factor of 8.
            trajXY_scale = 2^15; % 1B encoding is as good as 2B encoding
            desc_scale   = 2^16;
            
            % load the text file
            Desc = load(sprintf('%s.txt', outFilePrefix));
            
            nSE = 10; % number of summary elements
            d1 = 96; d2 = 108; 
            if ~isempty(Desc)
                trajStat = Desc(:,1:nSE); % summary statistics of trajectories
                trajXY   = Desc(:,(nSE+1):(nSE+2*trajLen));% relative coordinates of succesive points forming the trajectory
                Desc = Desc(:, (nSE+2*trajLen+1):end); % HOG, HOF1, MBH_X, MBH_Y

                trajXY = int16(trajXY_scale*trajXY); % mapping from [-1, 1] to int16
                Desc   = uint16(desc_scale*Desc); % mapping from [0, 1] to uint16                
                trajHog  = Desc(:, 1:d1);
                trajHof  = Desc(:, d1+1:d1+d2);            
                trajMbh  = Desc(:, d1+d2+1:3*d1+d2);                
                trajLen  = repmat(trajLen, size(Desc,1), 1);                
            else
                trajStat= [];
                trajHog = [];
                trajHof = [];
                trajMbh = [];
                trajXY  = [];                
                trajLen = [];
            end
                            
            % To recover original trajXY (upto some precision), use double(trajXY)/trajXY_scale
            % To recover original hog desc (upto some precision), use double(trajHog)/desc_scale;
            outFile = sprintf('%s.mat', outFilePrefix);
            save(outFile, 'trajStat', 'trajXY', 'trajHog', 'trajHof', ...
                'trajMbh', 'trajXY_scale', 'desc_scale', 'trajLen');
            
            % delete the text file
            cmd = sprintf('rm %s.txt', outFilePrefix);
            fprintf('%s\n', cmd);
            system(cmd);
        end
    end    
end

