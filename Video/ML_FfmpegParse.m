classdef ML_FfmpegParse
% By: Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Created: 11-Jan-2014
% Last modified: 27-Jun-2015

    methods (Static)
        % dispHeight, dispWidth: display height and width
        function [dispHeight, dispWidth] = getDispResolution(vidFile, varargin)
            videoStreamAttrs = ML_FfmpegParse.getAttrs(vidFile, varargin{:});
            for i=1:length(videoStreamAttrs)
                if strcmp(videoStreamAttrs(i).Name, 'width')
                    width = str2double(videoStreamAttrs(i).Value);
                elseif strcmp(videoStreamAttrs(i).Name, 'height')
                    height = str2double(videoStreamAttrs(i).Value);
                elseif strcmp(videoStreamAttrs(i).Name, 'display_aspect_ratio')
                    vals = videoStreamAttrs(i).Value;
                    [aw, ah] = strtok(vals, ':');
                    ah = strtok(ah, ':');
                    aw = str2double(aw);
                    ah = str2double(ah);
                end
            end;
            
            dispHeight = height;
            if exist('ah', 'var') && exist('aw', 'var') && ah ~=0 && aw ~=0
                dispWidth  = dispHeight/ah*aw;
            else
                dispWidth = width;
            end;            
        end
        
        function duration = getDuration(vidFile, varargin)
            videoStreamAttrs = ML_FfmpegParse.getAttrs(vidFile, varargin{:});
            for i=1:length(videoStreamAttrs)
                if strcmp(videoStreamAttrs(i).Name, 'duration')
                    duration = str2double(videoStreamAttrs(i).Value);
                    break;
                end
            end;            
        end
        
        function fps = getFps(vidFile, varargin)
            videoStreamAttrs = ML_FfmpegParse.getAttrs(vidFile, varargin{:});
            for i=1:length(videoStreamAttrs)
                if strcmp(videoStreamAttrs(i).Name, 'tbr')
                    fps = str2double(videoStreamAttrs(i).Value);
                    break;
                end
            end;            
        end
                
        function [videoStreamAttrs, audioStreamAttrs] = getAttrs(vidFile, ffprobeBin)
            if ~exist('ffprobeBin', 'var')                
                [~, ffprobeBin] = ML_Ffmpeg.getFfmpegBin();
            end;
            
            tmpDir = sprintf('/tmp/ML_FfmpegParse_%s/', ml_randStr());
            cmd = sprintf('mkdir -p %s', tmpDir);
            system(cmd);
            
            tmpFile = sprintf('%s/%s_%s.xml', tmpDir, ml_full2shortName(vidFile), ml_randStr());
            tmpFile_err = sprintf('%s.err', tmpFile);
            cmd = sprintf('%s -print_format xml -show_streams -loglevel fatal %s 1> %s 2> %s', ...
                ffprobeBin, vidFile, tmpFile, tmpFile_err);
            fprintf('%s\n', cmd);            
            system(cmd);            
                        
            try
                fprintf('Parsing %s\n', tmpFile);
                [videoStreamAttrs, audioStreamAttrs] = ML_FfmpegParse.parseXml(tmpFile);
            catch exp
                % Sometimes, xml file contains an illegal utf-8 sequence
                % We retry by removing the illegal sequences
                cmd = 'uname -a';
                fprintf('%s\n', cmd);
                system(cmd);
                
                fprintf('Encounter error while parsing %s\n', tmpFile);
                fprintf('Remove illegal utf-8 chars and retry\n');                
                tmpFile2 = sprintf('%s_retry.xml', tmpFile(1:end-4));                
                cmd = sprintf('iconv -f utf-8 -t utf-8 -c %s > %s', tmpFile, tmpFile2);
                fprintf('%s\n', cmd);                
                system(cmd);
                
                fprintf('Parsing %s\n', tmpFile2);
                [videoStreamAttrs, audioStreamAttrs] = ML_FfmpegParse.parseXml(tmpFile2);
                
                cmd = sprintf('rm %s', tmpFile2);
                fprintf('%s\n', cmd);
                system(cmd);
            end

            cmd = sprintf('rm -rf %s', tmpDir);            
            fprintf('%s\n', cmd);
            system(cmd);
        end
        
        function [videoStreamAttrs, audioStreamAttrs]= parseXml(xmlFile)
            fullFile = ls(xmlFile);
            fullFile = fullFile(1:end-1);
            
            ffprobe = parseXML(fullFile);            
            streams = ffprobe.Children(2);
            
            videoStreamAttrs = [];
            audioStreamAttrs = [];
            for i=1:length(streams.Children)
                if strcmp(streams.Children(i).Name, 'stream')
                    stream = streams.Children(i);
                    for j=1:length(stream.Attributes)
                        if strcmp(stream.Attributes(j).Name, 'codec_type')
                            if strcmpi(stream.Attributes(j).Value, 'video')                                
                                videoStreamAttrs = stream.Attributes;
                                break;
                            elseif strcmpi(stream.Attributes(j).Value, 'audio')                                
                                audioStreamAttrs = stream.Attributes;
                                break;
                            end
                        end                        
                    end
                end           
                if ~isempty(audioStreamAttrs) && ~isempty(videoStreamAttrs)
                    break;
                end;
            end;
        end
    end    
end

% Helper functions, copied from xmlread examples

function theStruct = parseXML(filename)
    % PARSEXML Convert XML file to a MATLAB structure.
    try
       tree = xmlread(filename);
    catch exp
       error('Failed to read XML file %s.',filename);
    end

    % Recurse over child nodes. This could run into problems 
    % with very deeply nested trees.
    try
       theStruct = parseChildNodes(tree);
    catch
       error('Unable to parse XML file %s.',filename);
    end
end


% ----- Local function PARSECHILDNODES -----
function children = parseChildNodes(theNode)
    % Recurse over node children.
    children = [];
    if theNode.hasChildNodes
       childNodes = theNode.getChildNodes;
       numChildNodes = childNodes.getLength;
       allocCell = cell(1, numChildNodes);

       children = struct(             ...
          'Name', allocCell, 'Attributes', allocCell,    ...
          'Data', allocCell, 'Children', allocCell);

        for count = 1:numChildNodes
            theChild = childNodes.item(count-1);
            children(count) = makeStructFromNode(theChild);
        end
    end
end

% ----- Local function MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
    % Create structure of node info.

    nodeStruct = struct(                        ...
       'Name', char(theNode.getNodeName),       ...
       'Attributes', parseAttributes(theNode),  ...
       'Data', '',                              ...
       'Children', parseChildNodes(theNode));

    if any(strcmp(methods(theNode), 'getData'))
       nodeStruct.Data = char(theNode.getData); 
    else
       nodeStruct.Data = '';
    end
end

% ----- Local function PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
    % Create attributes structure.

    attributes = [];
    if theNode.hasAttributes
       theAttributes = theNode.getAttributes;
       numAttributes = theAttributes.getLength;
       allocCell = cell(1, numAttributes);
       attributes = struct('Name', allocCell, 'Value', ...
                           allocCell);

       for count = 1:numAttributes
          attrib = theAttributes.item(count-1);
          attributes(count).Name = char(attrib.getName);
          attributes(count).Value = char(attrib.getValue);
       end
    end
end
