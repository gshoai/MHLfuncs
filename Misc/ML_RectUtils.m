classdef ML_RectUtils
% Utitlies function for boxes and rectangles
% Boxes are [left, top, with, height]
% Rectangles are [left, top, right, bottom];
% By Minh Hoai Nguyen (minhhoai@robots.ox.ac.uk)
% Date: 8 Aug 2012
% Last modified: 20 Mar 2014
    
    methods (Static)
        % box: [left, top, width, height]
        function area = getBoxArea(box)
            if isempty(box)
                area = 0;
            else
                area = box(3)*box(4);
            end;
        end;
        
        % box: [left, top, width, height]
        function area = getRectArea(rect)
            if isempty(rect)
                area = 0;
            else
                area = (rect(4)-rect(2)+1)*(rect(3)-rect(1)+1);
            end;
        end;
        
        % Union of two rectangles
        function rect = getRectUnion(rect1, rect2)
            xrange = ML_RectUtils.getSegUnion([rect1(1), rect1(3)], [rect2(1), rect2(3)]);
            yrange = ML_RectUtils.getSegUnion([rect1(2), rect1(4)], [rect2(2), rect2(4)]);
            rect = [xrange(1), yrange(1), xrange(2), yrange(2)];
        end;
        
        % Intersection of two rectangles
        function rect = getRectInter(rect1, rect2)
            xrange = ML_RectUtils.getSegInter([rect1(1), rect1(3)], [rect2(1), rect2(3)]);
            yrange = ML_RectUtils.getSegInter([rect1(2), rect1(4)], [rect2(2), rect2(4)]);
            
            if isempty(xrange) || isempty(yrange)
                rect = [];
            else
                rect = [xrange(1), yrange(1), xrange(2), yrange(2)];
            end
            
        end;
        
        % box: [left, top, width, height]
        % rect: [left, top, right, bottom]
        function rect = box2rect(box)
            rect = [box(1), box(2), box(1) + box(3) - 1, box(2) + box(4) - 1];
        end;
        
        % boxes: 4*k matrix, each column is [left; top; width; height]
        % rects: 4*k matrix, each column is [left; top; right; bottom]
        function rects = boxes2rects(boxes)
            rects = boxes;
            if ~isempty(boxes)
                rects([3,4],:) = boxes([3,4],:) + boxes([1,2], :) - 1;
            end
        end;
        
        % rects: 4*k matrix, each column is [left; top; right; bottom]
        % boxes: 4*k matrix, each column is [left; top; width; height]
        function boxes = rects2boxes(rects)
            boxes = rects;
            if ~isempty(rects)
                boxes([3,4],:) = rects([3,4],:) - rects([1,2],:) + 1;
            end
        end;
        
        % Get the union box of all boxes
        function unionBox = getBoxesUnion(boxes)
            rects = ML_RectUtils.boxes2rects(boxes);
            unionRect = ML_RectUtils.getRectsUnion(rects);
            unionBox = ML_RectUtils.rects2boxes(unionRect);
        end;
        
        % Get the union rect of all rects
        function unionRect = getRectsUnion(rects)
            unionRect = zeros(4,1);
            unionRect([1,2]) = min(rects([1,2],:), [], 2);
            unionRect([3,4]) = max(rects([3,4],:), [], 2);
        end;
        
        
        % Get union of two boxes
        % box1, box2, box: [left, top, width, height];
        function box = getBoxUnion(box1, box2)
            rect1  = ML_RectUtils.box2rect(box1);
            rect2  = ML_RectUtils.box2rect(box2);
            xrange = ML_RectUtils.getSegUnion([rect1(1), rect1(3)], [rect2(1), rect2(3)]);
            yrange = ML_RectUtils.getSegUnion([rect1(2), rect1(4)], [rect2(2), rect2(4)]);
            box = [xrange(1), yrange(1), xrange(2) - xrange(1) + 1, yrange(2) - yrange(1) + 1];
        end;
        
        
        
        % Get intersection of two boxes
        % box1, box2, box: [left, top, width, height];
        function box = getBoxInter(box1, box2)
            % x intersection of two boxes
            xInter = ML_RectUtils.getSegInter([box1(1), box1(1)-1+box1(3)], [box2(1), box2(1)-1+box2(3)]);
            
            % y intersection of two boxes
            yInter = ML_RectUtils.getSegInter([box1(2), box1(2)-1+box1(4)], [box2(2), box2(2)-1+box2(4)]);
            
            
            if isempty(xInter(1)) || isempty(yInter(1))
                box = [];
            else
                box = [xInter(1), yInter(1), xInter(2) - xInter(1) + 1, yInter(2) - yInter(1) + 1];
            end;
        end
        
        
        % box1, box2: [left, top, width, height]
        % return the area of intersection over the area of union
        function iou = getBoxInterOverUnion(box1, box2)
            box_inter = ML_RectUtils.getBoxInter(box1, box2);
            box_union = ML_RectUtils.getBoxUnion(box1, box2);
            iou = ML_RectUtils.getBoxArea(box_inter)/ML_RectUtils.getBoxArea(box_union);
        end
        
        function iou = getRectInterOverUnion(rect1, rect2)
            rect_inter = ML_RectUtils.getRectInter(rect1, rect2);
            rect_union = ML_RectUtils.getRectUnion(rect1, rect2);
            iou = ML_RectUtils.getRectArea(rect_inter)/ML_RectUtils.getRectArea(rect_union);
        end;
        
        
        % Union of two segments
        function unionSeg = getSegUnion(ev1, ev2)
            unionSeg = [min(ev1(1), ev2(1)), max(ev1(2), ev2(2))];
        end
        
        
        
        % Get the intersection of two segments (or two events)
        % Inputs:
        %   ev1, ev2: two vectors of size two. ev1(1) <= ev1(2) and ev2(1) <= ev2(2)
        % Outputs:
        %   Return the intersection of ev1 and ev2.
        %   If the intersection is empty, this returns [];
        function intSeg = getSegInter(ev1, ev2)
            if ev1(1) <= ev2(1)
                fstEv = ev1;
                sndEv = ev2;
            else
                fstEv = ev2;
                sndEv = ev1;
            end;
            
            if fstEv(2) < sndEv(1)
                intSeg = [];
            elseif fstEv(2) >= sndEv(2)
                intSeg = sndEv;
            else
                intSeg = [sndEv(1), fstEv(2)];
            end;
        end
        
        
        function drawBoxes(boxes, colors, lineWidth)
            if ~exist('color', 'var') || isempty(color)
                colors = {'r', 'g', 'b', 'c', 'm', 'y'};
            end;
            
            if ~exist('lineWidth', 'var') || isempty(lineWidth)
                lineWidth = 3;
            end;
            for i=1:size(boxes,2);
                rectangle('Position', boxes(1:4,i), 'LineWidth', lineWidth, 'EdgeColor', colors{mod(i-1, 6) + 1});                
            end;
            
            if size(boxes,1) > 4
                for i=1:size(boxes,2)
                    text(boxes(1,i), boxes(2,i), sprintf('%d: %.2f', i, boxes(5,i)), ...
                    'BackgroundColor',[.7 .9 .7], 'FontSize', 16, ...
                    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
                end
            end;
        end;
        
        function drawRect(rect, color, lineWidth)
            if ~exist('color', 'var') || isempty(color)
                color = [1, 0, 0];
            end;
            
            if ~exist('lineWidth', 'var') || isempty(lineWidth)
                lineWidth = 3;
            end;
            left   = rect(1);
            right  = rect(3);
            top    = rect(2);
            bottom = rect(4);
            line([left right right left left], [top top bottom bottom top], ...
                'LineWidth', lineWidth, 'Color', color);
        end;
        
        
        
        function im = drawRect2(im, rect, colors)
            if ~exist('colors', 'var')
                colors = [1, 0, 0];
            end;
            
            [imH, imW, nC] = size(im);
            rect = ML_RectUtils.clipRects(imH, imW, rect);
            
            x  = rect(1);
            y  = rect(2);
            x2 = rect(3);
            y2 = rect(4);
            
            maxVal = double(max(im(:)));
            boundVals = maxVal*colors;
            
            for i=1:nC
                im_i = im(:,:,i);
                im_i(y:y+2, x:x2)   = boundVals(i);
                im_i(y2-2:y2, x:x2) = boundVals(i);
                im_i(y:y2,x:x+2)    = boundVals(i);
                im_i(y:y2,x2-2:x2)  = boundVals(i);
                im(:,:,i) = im_i;
            end;
        end;
        
        
        % Given a rectangle, get the extended rect
        % extFactors is for left, top, right, bottom
        % extFactors(1) = 0.5 mean the left corner is shitfted to the left
        %   half the width of the box.
        % This performs clipping, ex_bbox will be valid box within image
        % boundaries
        function extRect = extendRect(imH, imW, rect, extFactors)
            if isempty(rect)
                extRect = [];
                return;
            end;
            left   = rect(1);
            top    = rect(2);
            right  = rect(3);
            bottom = rect(4);
            box_height = bottom - top + 1;
            box_width  = right - left + 1;
            
            lr = round([left - extFactors(1)*box_width, right + extFactors(3)*box_width]);
            tb = round([top  - extFactors(2)*box_height, bottom + extFactors(4)*box_height]);
            extRect = [lr(1); tb(1); lr(2); tb(2)];
            extRect = ML_RectUtils.clipRects(imH, imW, extRect);
        end
        
        
        % Given a reference rect, compute the absolute positions of other
        % rects relative to the reference rect.
        % Inputs:
        %   refRect a 4*1 column vector
        %   relRects a 4*k matrix for k boxes
        % Outputs:
        %   absRects: absolute positions
        function absRects = relRects2absRects(refRect, relRects)
            if size(relRects,1) == 1
                relRects = relRects(:);
            end;
            bbH = refRect(4) - refRect(2); % don't add 1
            bbW = refRect(3) - refRect(1);
            absRects = zeros(size(relRects));
            absRects([1,3],:) = refRect(1) + round(relRects([1,3],:)*bbW);
            absRects([2,4],:) = refRect(2) + round(relRects([2,4],:)*bbH);
        end
        
        % Given a reference rect, compute the relative positions of some
        % rects wrt to the refenrence box.
        % Inputs:
        %   refRect:  4*1 column vector
        %   absRects: 4*k matrix for k boxes
        % Outputs:
        %   relRects: relative positions of absRects wrt refRect
        function relRects = absRects2relRects(refRect, absRects)
            if size(absRects,1) == 1
                absRects = absRects(:);
            end;
            
            bbH = refRect(4) - refRect(2); % don't add 1
            bbW = refRect(3) - refRect(1);
            
            relRects = zeros(size(absRects));
            relRects([1,3],:) = (absRects([1,3],:) - refRect(1))/bbW;
            relRects([2,4],:) = (absRects([2,4],:) - refRect(2))/bbH;
        end
        
        
        
        % Get the relative boxes from the absolute boxes
        % refBox: [left; top; width; height], the reference box
        % boxes: 4*k for k boxes, each column is [left; top; width; height]
        % relBoxes: 4*k for k relative boxes
        %   relBoxes(:,i) is (rel_x, rel_y, rel_w, rel_h)
        %       rel_w, rel_h are relative sizes wrt to the size of refBox
        %       rel_x, rel_y are the distance between center of a box to the center of
        %       the refBox, normalized by the size of refBox
        function relBoxes = absBoxes2relBoxes(refBox, boxes)
            % get center of the reference box
            width = refBox(3);
            height = refBox(4);
            refBoxCx = refBox(1) + (width-1)/2;
            refBoxCy = refBox(2) + (height-1)/2;
            
            % Specify the boxes by the centers of the boxes
            relBoxes = boxes;
            relBoxes(1,:) = relBoxes(1,:) + (relBoxes(3,:)-1)/2;
            relBoxes(2,:) = relBoxes(2,:) + (relBoxes(4,:)-1)/2;
            
            % Shift the coordinate origin to the center of the reference boxes
            relBoxes(1,:) = relBoxes(1,:) - refBoxCx;
            relBoxes(2,:) = relBoxes(2,:) - refBoxCy;
            relBoxes([1,3],:) = relBoxes([1,3],:)/width;
            relBoxes([2,4],:) = relBoxes([2,4],:)/height;
        end
        
        % Get the absBoxes from the relative boxes
        % refBox: [left; top; width; height], the reference box
        % relBoxes: 4*k for k relative boxes
        %   relBoxes(:,i) is (rel_x, rel_y, rel_w, rel_h)
        %       rel_w, rel_y are relative sizes wrt to the size of refBox
        %       rel_xOffset, rel_yOffset are the distance between center of a box to the center of
        %       the refBox, normalized by the size of refBox
        % absBoxes: 4*k matrix, each column is [left; top; width; height]
        function absBoxes = relBoxes2absBoxes(refBox, relBoxes)
            % get center of the reference box
            width = refBox(3);
            height = refBox(4);
            refBoxCx = refBox(1) + (width-1)/2;
            refBoxCy = refBox(2) + (height-1)/2;
            
            absBoxes = relBoxes;
            % rescale
            absBoxes([2,4],:) = absBoxes([2,4],:)*height;
            absBoxes([1,3],:) = absBoxes([1,3],:)*width;
            
            % shift to top-left corner coordinate
            absBoxes(2,:) = absBoxes(2,:) + refBoxCy;
            absBoxes(1,:) = absBoxes(1,:) + refBoxCx;
            
            % specify using the top-left corner of the absBoxes, instead of the center
            absBoxes(1,:) = absBoxes(1,:) - (absBoxes(3,:)-1)/2;
            absBoxes(2,:) = absBoxes(2,:) - (absBoxes(4,:)-1)/2;
        end
        
        
        
        % clip the rects to within the borders of an image
        % rects: 4*k matrix for k rectangles
        function rects = clipRects(imH, imW, rects)
            rects(1:4,:) = max(rects(1:4,:), 1);
            rects([1,3],:) = min(rects([1,3],:), imW);
            rects([2,4],:) = min(rects([2,4],:), imH);
        end
        
        % Adapted from Pacal VOC.
        % Compute the symmetric intersection over union overlap between rects set of
        % rects and a single rect
        % rects a 4*k matrix where each column specifies a rectangle
        % a_rect a 4*1 single rectangle
        function o = rectOverlap(rects, a_rect)
            rects = rects';
            a_rect = a_rect';
            
            x1 = max(rects(:,1), a_rect(1));
            y1 = max(rects(:,2), a_rect(2));
            x2 = min(rects(:,3), a_rect(3));
            y2 = min(rects(:,4), a_rect(4));
            
            w = x2-x1 + 1;
            h = y2-y1 + 1;
            inter = w.*h;
            aarea = (rects(:,3)-rects(:,1) + 1) .* (rects(:,4)-rects(:,2) + 1);
            barea = (a_rect(3)-a_rect(1) + 1) * (a_rect(4)-a_rect(2) + 1);
            % intersection over union overlap
            o = inter ./ (aarea+barea-inter);
            % set invalid entries to 0 overlap
            o(w <= 0) = 0;
            o(h <= 0) = 0;
        end
        
        % Compute assymmetric overlap of intersection over the area of a_rect
        function o = rectOverlap2(rects, a_rect)
            rects = rects';
            a_rect = a_rect';
            
            x1 = max(rects(:,1), a_rect(1));
            y1 = max(rects(:,2), a_rect(2));
            x2 = min(rects(:,3), a_rect(3));
            y2 = min(rects(:,4), a_rect(4));
            
            w = x2-x1 + 1;
            h = y2-y1 + 1;
            inter = w.*h;            
            barea = (a_rect(3)-a_rect(1) + 1) * (a_rect(4)-a_rect(2) + 1);
            % intersection over union overlap
            o = inter./barea;
            % set invalid entries to 0 overlap
            o(w <= 0) = 0;
            o(h <= 0) = 0;
        end

        % Compute assymmetric overlap of intersection over the area of rects
        function o = rectOverlap3(rects, a_rect)
            rects = rects';
            a_rect = a_rect';
            
            x1 = max(rects(:,1), a_rect(1));
            y1 = max(rects(:,2), a_rect(2));
            x2 = min(rects(:,3), a_rect(3));
            y2 = min(rects(:,4), a_rect(4));
            
            w = x2-x1 + 1;
            h = y2-y1 + 1;
            inter = w.*h;
            aarea = (rects(:,3)-rects(:,1) + 1) .* (rects(:,4)-rects(:,2) + 1);
            % intersection over union overlap
            o = inter./aarea; 
            % set invalid entries to 0 overlap
            o(w <= 0) = 0;
            o(h <= 0) = 0;
        end

        
        % Non-maximum suppression.
        % Greedily select high-scoring detections and skip detections
        % that are significantly covered by a previously selected detection.
        % rects: 5*m rectangles, rects(:,i) is [x1, y1, x2, y2, score]
        function [top, pick] = nms(rects, overlap)
            boxes = rects';
            if isempty(boxes)
                pick = [];
                top = [];
            else
                x1 = boxes(:,1);
                y1 = boxes(:,2);
                x2 = boxes(:,3);
                y2 = boxes(:,4);
                s  = boxes(:,5);
                area = (x2-x1+1) .* (y2-y1+1);
                
                [vals, I] = sort(s);
                pick = [];
                while ~isempty(I)
                    last = length(I);
                    i = I(last);
                    pick = [pick; i];
                    suppress = [last];
                    for pos = 1:last-1
                        j = I(pos);
                        xx1 = max(x1(i), x1(j));
                        yy1 = max(y1(i), y1(j));
                        xx2 = min(x2(i), x2(j));
                        yy2 = min(y2(i), y2(j));
                        w = xx2-xx1+1;
                        h = yy2-yy1+1;
                        if w > 0 && h > 0
                            % compute overlap
                            o = w * h / area(j);
                            if o > overlap
                                suppress = [suppress; pos];
                            end
                        end
                    end
                    I(suppress) = [];
                end
                top = boxes(pick,:)';
            end            
        end
        
        % Non-maximum suppression.
        % Greedily select high-scoring detections and skip detections
        % that are significantly covered by a previously selected detection.
        % rects: 5*m rectangles, rects(:,i) is [x1, y1, x2, y2, score]
        function [top, pick] = nms2(rects, overlap1, overlap2)
            boxes = rects';
            if isempty(boxes)
                pick = [];
                top = [];
            else
                x1 = boxes(:,1);
                y1 = boxes(:,2);
                x2 = boxes(:,3);
                y2 = boxes(:,4);
                s  = boxes(:,5);
                area = (x2-x1+1) .* (y2-y1+1);
                
                [vals, I] = sort(s);
                pick = [];
                while ~isempty(I)
                    last = length(I);
                    i = I(last);
                    pick = [pick; i];
                    suppress = [last];
                    for pos = 1:last-1
                        j = I(pos);
                        xx1 = max(x1(i), x1(j));
                        yy1 = max(y1(i), y1(j));
                        xx2 = min(x2(i), x2(j));
                        yy2 = min(y2(i), y2(j));
                        w = xx2-xx1+1;
                        h = yy2-yy1+1;
                        if w > 0 && h > 0
                            % compute overlap
                            o1 = w * h / area(j);
                            o2 = w*h/area(i);
                            if o1 > overlap1 || o2 > overlap2
                                suppress = [suppress; pos];
                            end
                        end
                    end
                    I(suppress) = [];
                end
                top = boxes(pick,:)';
            end            
        end
        
    end
end

