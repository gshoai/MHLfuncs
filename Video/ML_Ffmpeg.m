classdef ML_Ffmpeg
% By: Minh Hoai Nguyen (minhhoai@cs.stonybrook.edu)
% Created: 01-Jul-2015
% Last modified: 01-Jul-2015

    methods (Static);
        function [ffmpegBin, ffprobeBin] = getFfmpegBin()
            [~, machine] = system('uname');
            machine =strtrim(machine);
            if strcmpi(machine, 'Darwin')
                ffmpegBin = '/opt/local/bin/ffmpeg';
                ffprobeBin = '/opt/local/bin/ffprobe';
            elseif strcmpi(machine, 'Linux')
                ffmpegBin = '/home/minhhoai/local/bin/ffmpeg';
                ffprobeBin = '/home/minhhoai/local/bin/ffprobe';
            else
                ffmpegBin = 'ffmpeg';
                ffprobeBin = 'ffprobe';
            end;
        end
    end    
end

