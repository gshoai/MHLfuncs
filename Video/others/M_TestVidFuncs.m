classdef M_TestVidFuncs
% Demos for the classes in ./Video
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 11-Oct-2014
% Last modified: 11-Oct-2014    

    methods (Static)        
        % Extracting a video for a specific part of a longer video
        function demo1()
            clip.file = 'ori.mp4';
            clip.start ='00:01:00,000';
            clip.end = '00:01:30,269';            
            opts.ffmpegBin = ML_FfmpegParse.getFfmpegBin();
            opts.newH = 480;
            ML_VidClip.extVid(clip, 'out.mp4', opts);
        end;
        
        % Extracting frames
        function demo2()
            % Example 1, extracting a clip
            clip.file = 'sample.mp4';            
            outFrmDir = 'frames';
            opts.ffmpegBin = ML_FfmpegParse.getFfmpegBin();
            ML_VidClip.extFrms(clip, outFrmDir, opts);
            
            % Example 2, with various options
            outFrmDir2 = 'frames2';
            clip2.file = 'sample.mp4';            
            clip2.start = '00:00:02,000'; % specific section of the clip
            clip2.end = '00:00:05,250';
            clip2.flip = 1; % flip horizontally
            opts2.ffmpegBin = ML_FfmpegParse.getFfmpegBin();
            opts2.fps = 10;
            opts2.newH = 200;
            opts2.frmQuality = '-q:v 4';
            opts2.frmExt = 'jpg';
            ML_VidClip.extFrms(clip2, outFrmDir2, opts2);
        end;

        % Extract frames, detect hard cuts, display shots and threads for a video clip
        function demo3()            
            clip.file = 'sample.mp4';            
            outFrmDir = 'frames';
            %clip.file = 'Frasier_01x02_begin.mp4';            
            %outFrmDir = 'frames';
            opts.ffmpegBin = ML_FfmpegParse.getFfmpegBin();
            
            % first extract frames
            ML_VidClip.extFrms(clip, outFrmDir, opts);
            
            imFiles = ml_getFilesInDir(outFrmDir, 'png');
            maxDist = 5;
            featType = 'sift';
            shldDisp = 1;

            [shotBnds, threads] = ML_VidThread.getThreads(imFiles, maxDist, featType, shldDisp);
            
            % Suppose there is an event from frames 250 to 550
            eventStart = 250;
            eventEnd = 550;
            ML_VidThread.dispThreads(length(imFiles), shotBnds, threads, eventStart, eventEnd);
            
            outHtmlDir = './gifs/';
            ML_VidThread.createHtmls(imFiles, shotBnds, threads, outHtmlDir);
            fprintf('Use an Internet browser to open %s/shots.html to display shots\n', outHtmlDir);
            fprintf('Use an Internet browser to open %s/threads.html to display threads\n', outHtmlDir);
        end;
        
        % Compute Fisher vector encoding for dense trajectory features
        function demo4()            
            clip.file = 'sample.mp4';            
            outFrmDir = 'frames';
            opts.ffmpegBin = ML_FfmpegParse.getFfmpegBin();
            
            % first extract frames
            ML_VidClip.extFrms(clip, outFrmDir, opts);
            
            imFiles = ml_getFilesInDir(outFrmDir, 'png');
            maxDist = 5;
            featType = 'sift';
            shldDisp = 1;

            [shotBnds, threads] = ML_VidThread.getThreads(imFiles, maxDist, featType, shldDisp);
            nFrm = length(imFiles);
            nShot = length(shotBnds) + 1;
            
            shots = zeros(2, nShot);
            shots(1,1) = 1;
            shots(2, end) = nFrm;
            
            if ~isempty(shotBnds)
                shots(1, 2:end)   = shotBnds;
                shots(2, 1:end-1) = shotBnds-1;
            end

            
            % Let get a Fisher Vector encoding for Thread 3            
            % First, extract all frames from Thread 3 and put the indexes in order
            frmIdxss = cell(1, length(threads{3}));
            for i=1:length(threads{3});
                shotId = threads{3}(i);
                frmIdxss{i} = shots(1,shotId):shots(2,shotId);                    
            end            
            frmIdxs = cat(2, frmIdxss{:}); % indexes of frames in Thread 3
            
            gmmModelFile = 'GMM.mat'; % the GMM model file for Fisher Vector encoding
                                      % Replace it with your own model file if necessary

            % Get the Fisher Vector feature
            fv = ML_IDTD.fvEncode4dir(outFrmDir, 'png', frmIdxs, gmmModelFile);
        end;
    end    
end

