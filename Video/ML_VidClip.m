classdef ML_VidClip
% Extracting frames of a video clip, shifting and converting time strings
%
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 11-Oct-2014
% Last modified: 11-Oct-2014    
    methods (Static)
        
        % Extracting frames from a clip
        % Inputs: 
        %   clip is a struct, with several fields
        %       clip.file: full path to the video data
        %       clip.flip: if the video should be flipped left-right
        %       clip.start: start of the clip, e.g, '00:02:15,125'. If this field is not present,
        %           it is assumed the begining of the video file
        %       clip.end: end of the clip, e.g., '00:02:18,000'. If this field is not present,
        %           it is assumed the end of the video file
        %   outFrmDir: output director for frames
        %   opts:
        %       fps: number of frames per second, default is the same as the video
        %       newH, newW: desired output H & W, default are the display H & W of the video
        %           if only one of these two parameters is specified, the aspect ratio is perserved
        %       frmExt: default is 'png'
        %       frmQuality: default for 'jpg' is '-q:v 4'
        %       nThread: number of threads, default is unlimited
        %       ffmpegBin
        %       frmPrefix: default frm_
        % Outputs:
        %   frmPattern: the pattern of the output frames
        function frmPattern = extFrms(clip, outFrmDir, opts)
            vidFile = clip.file;
            
            if isfield(clip, 'start') && ~isempty(clip.start)
                startSecond = ML_VidClip.timeStr2second(clip.start);
            else
                startSecond = 0;
            end;
            if isfield(clip, 'end')  && ~isempty(clip.end)
                endSecond   = ML_VidClip.timeStr2second(clip.end);
                duration    = endSecond - startSecond;
            else
                duration = [];
            end;
            
            if isfield(clip, 'flip') && clip.flip
                flipOpt = '-vf "hflip"';
            else
                flipOpt = '';
            end;
            
            frmPrefix = ML_VidClip.parseOpts(opts, 'frmPrefix', 'frm_');
            ffmpegBin = ML_VidClip.parseOpts(opts, 'ffmpegBin', ML_Ffmpeg.getFfmpegBin());
            fps = ML_VidClip.parseOpts(opts, 'fps', []);
            if isempty(fps)
                fpsOpt = '';
            else
                fpsOpt = sprintf('-r %d', fps);
            end;
            
            frmExt = ML_VidClip.parseOpts(opts, 'frmExt', 'png');
            if strcmpi(frmExt, 'png')
                frmQuality = '';
            else
                frmQuality = ML_VidClip.parseOpts(opts, 'frmQuality', '-q:v 4');
            end;
            
            % Sometimes we need to limit the number of CPU threads used. The default is no limit
            nThread = ML_VidClip.parseOpts(opts, 'nThread', '');
            if isempty(nThread)
                threadOpt = '';
            else
                threadOpt = sprintf('-threads %d', nThread);
            end;
            
            % Get the image resolution, default is display H and W
            newH = ML_VidClip.parseOpts(opts, 'newH', []);
            newW = ML_VidClip.parseOpts(opts, 'newW', []);
            
            [dispH, dispW] = ML_FfmpegParse.getDispResolution(vidFile);            
            if isempty(newH) && isempty(newW) % if newH and newW are not specified
                newH = dispH; newW = dispW;
            elseif isempty(newW) % if newH is specified, newW is auto, keeping aspect ratio
                newW = newH*dispW/dispH; 
                newW = 4*round(newW/4); % make it divisible by 4
            elseif isempty(newH) % if newW is specified, newH is auto, keeping aspect ratio
                newH = newW*dispH/dispW;
                newH = 4*round(newH/4); % make it divisible by 4
            end
            frmResolution = sprintf('-s %d*%d', newW, newH);

            frmPattern = sprintf('%s/%s%%06d.%s', outFrmDir, frmPrefix, frmExt);
            cmd = sprintf('mkdir -p %s', outFrmDir);
            fprintf('%s\n', cmd);
            system(cmd);                        
            
            logFile = sprintf('%s/frmExtract.log', outFrmDir);            
            
            % combine fast and accurate seeking in ffmpeg
            if startSecond <= 30
                fastStartOpt = ''; % no need for fast seeking
                accStartTime  = startSecond;
            else
                fastStartOpt = sprintf('-ss %.3f', startSecond - 30); % fast seeking
                accStartTime  = 30;
            end;
                
            if ~isempty(duration)
                durationOpt = sprintf('-t %.3f', duration);
            else
                durationOpt = '';
            end
            
            cmd = sprintf('%s %s %s -i %s -ss %.3f %s -loglevel error %s %s %s %s -f image2 %s &> %s', ...
               ffmpegBin, threadOpt, fastStartOpt, vidFile, accStartTime, ...
               durationOpt, fpsOpt, frmResolution, flipOpt, frmQuality, frmPattern, logFile);

            fprintf('%s\n', cmd);            
            system(cmd);
        end;
        
        
        % Extracting a video file from a clip
        % Inputs: 
        %   clip is a struct, with several fields
        %       clip.file: full path to the video data
        %       clip.flip: if the video should be flipped left-right
        %       clip.start: start of the clip, e.g, '00:02:15,125'. If this field is not present,
        %           it is assumed the begining of the video file
        %       clip.end: end of the clip, e.g., '00:02:18,000'. If this field is not present,
        %           it is assumed the end of the video file
        %   outVidFile: output director for frames
        %   opts:
        %       fps: number of frames per second, default is the same as the video
        %       newH, newW: desired output H & W, default are the display H & W of the video
        %           if only one of these two parameters is specified, the aspect ratio is perserved
        %       nThread: number of threads, default is unlimited
        function extVid(clip, outVidFile, opts)
            vidFile = clip.file;            
            if isfield(clip, 'start') && ~isempty(clip.start)
                startSecond = ML_VidClip.timeStr2second(clip.start);
            else
                startSecond = 0;
            end;
            if isfield(clip, 'end')  && ~isempty(clip.end)
                endSecond   = ML_VidClip.timeStr2second(clip.end);
                duration    = endSecond - startSecond;
            else
                duration = [];
            end;
            
            if isfield(clip, 'flip') && clip.flip
                flipOpt = '-vf "hflip"';
            else
                flipOpt = '';
            end;
            
            ffmpegBin = ML_VidClip.parseOpts(opts, 'ffmpegBin', ML_Ffmpeg.getFfmpegBin());
            fps = ML_VidClip.parseOpts(opts, 'fps', []);
            if isempty(fps)
                fpsOpt = '';
            else
                fpsOpt = sprintf('-r %d', fps);
            end;
            
            
            % Sometimes we need to limit the number of threads used. The default is no limit
            nThread = ML_VidClip.parseOpts(opts, 'nThread', '');
            if isempty(nThread)
                threadOpt = '';
            else
                threadOpt = sprintf('-threads %d', nThread);
            end;
            
            % Get the image resolution, default is display H and W
            newH = ML_VidClip.parseOpts(opts, 'newH', []);
            newW = ML_VidClip.parseOpts(opts, 'newW', []);
            
            [dispH, dispW] = ML_FfmpegParse.getDispResolution(vidFile);            
            if isempty(newH) && isempty(newW) % if newH and newW are not specified
                newH = dispH; newW = dispW;
            elseif isempty(newW) % if newH is specified, newW is auto, keeping aspect ratio
                newW = newH*dispW/dispH; 
                newW = 4*round(newW/4); % make it divisible by 4
            elseif isempty(newH) % if newW is specified, newH is auto, keeping aspect ratio
                newH = newW*dispH/dispW;
                newH = 4*round(newH/4); % make it divisible by 4
            end
            frmResolution = sprintf('-s %d*%d', newW, newH);

            % combine fast and accurate seeking in ffmpeg
            if startSecond <= 30
                fastStartOpt = ''; % no need for fast seeking
                accStartTime  = startSecond;
            else
                fastStartOpt = sprintf('-ss %.3f', startSecond - 30); % fast seeking
                accStartTime  = 30;
            end;
                
            if ~isempty(duration)
                durationOpt = sprintf('-t %.3f', duration);
            else
                durationOpt = '';
            end
            
            cmd = sprintf('%s %s %s -i %s -ss %.3f %s -strict -2 %s %s %s %s', ...
               ffmpegBin, threadOpt, fastStartOpt, vidFile, accStartTime, ...
               durationOpt, fpsOpt, frmResolution, flipOpt, outVidFile);

            fprintf('%s\n', cmd);            
            system(cmd);
            
        end;
        
        % Create MP4 file from a list of image files
        function createMp4(imFiles, fps, outFile)            
            % Strip the extension
            if length(outFile) >= 4 && strcmpi(outFile(end-2:end), 'mp4')
                outFile = outFile(1:end-4);
            end;
                            
            aviFile = sprintf('%s_tmp.avi', fullfile(outFile));                        
            outputVideo = VideoWriter(aviFile);
            outputVideo.FrameRate = fps;
            open(outputVideo)
            
            for i = 1:length(imFiles);
                img = imread(imFiles{i});
                writeVideo(outputVideo,img)
            end
            close(outputVideo);                        
            cmd = sprintf('%s -i %s -y %s.mp4', ML_Ffmpeg.getFfmpegBin(), aviFile, outFile);            
            fprintf('%s\n', cmd);
            system(cmd);            
            
            cmd = sprintf('rm %s', aviFile);
            fprintf('%s\n', cmd);
            system(cmd);            
        end;


        
        % convert time string from hh:mm:ss,fff to number of second
        function nSecond = timeStr2second(timeStr)
            tokens = textscan(timeStr, '%d', 'Delimiter', ':,', 'MultipleDelimsAsOne', 1);
            tokens = tokens{1};
            hh = tokens(1);
            mm = tokens(2);
            ss = tokens(3);
            nSecond = double(hh*3600 + mm*60 + ss);
            if length(tokens) > 3
                fff = tokens(4);       
                fffStr = sprintf('%d', fff);
                nSecond = nSecond + double(fff)/(10^length(fffStr));
            end;
        end;
        
        % Shift time backward some second
        % e.g, timeStr = 00:00:12,109, nSecond = 3, output = 00:00:09,109
        % outTimeStr cannot be negative
        function outTimeStr = shiftTimeStr(timeStr, nSecond)
            tokens = textscan(timeStr, '%d', 'Delimiter', ':,', 'MultipleDelimsAsOne', 1);
            tokens = tokens{1};
            hh = tokens(1);
            mm = tokens(2);
            ss = tokens(3);
            ms = double(tokens(4))/1000;
            newTime = double(hh*3600 + mm*60 + ss) + ms - nSecond;
            if (newTime < 0)
                newTime = 0;
            end;
            
            outTimeStr = ML_VidClip.second2timeStr(newTime);
        end;
        
        % newTime: time in second
        function timeStr = second2timeStr(newTime)
            hh = floor(newTime/3600);
            newTime = newTime - 3600*hh;
            mm = floor(newTime/60);
            newTime = newTime - 60*mm;
            ss = floor(newTime);
            ms = newTime - ss;            
            timeStr = sprintf('%02d:%02d:%02d,%03.0f', hh, mm, ss, 1000*ms);            
        end

        function val = parseOpts(opts, fieldName, defVal)
            if isfield(opts, fieldName)
                val = opts.(fieldName);
            else
                val = defVal;
            end;
        end;
    end    
end

