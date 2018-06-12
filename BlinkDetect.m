function blinkFrameList = BlinkDetect(mov)

debug = false;

pupilIntensityThreshold = 20;
pupilMovementThreshold = 50;
eccentricityThreshold = 1;
centroidPrev = [0 0];
pupilSizeThreshold = 5000;
erodeDilateElement = strel('disk',5,0);
specularIntensity = 220;

blinkFrameList = false(size(mov,4),1);

if size(mov,3) > 1
    mov = mov(:,:,1,:);
end

if debug
    figure();
end

for frameNo = 1:size(mov,4)
    %set frame to current frame in mov
    frame = mov(:,:,frameNo);
    
    if debug
        debugFrame = zeros([size(frame),3],'uint8');
        debugFrame(:,:,1) = frame;
        debugFrame(:,:,2) = frame;
        debugFrame(:,:,3) = frame;
    end
    
    %set minIntensity to intensity of darkest pixel in frame
    minIntensity = min(frame(:));
    %set pupilIsolated to true for all pixels in frame within
    %pupilIntensityThreshold of minIntensity
    pupilIsolated = frame <= minIntensity + pupilIntensityThreshold;
    %add to pupilIsolated frame any pixels with intensity higher than
    %specularIntensity
    pupilIsolated = pupilIsolated + (frame >= specularIntensity);
    %dilate pupilIsolated
    pupilIsolated = imdilate(pupilIsolated, erodeDilateElement);
    %fill holes in pupilIsolated
    pupilIsolated = imfill(pupilIsolated,'holes');
    %erode twice and dilate pupilIsolated
    pupilIsolated = imdilate(imerode(imerode(pupilIsolated,erodeDilateElement),erodeDilateElement),erodeDilateElement);
    %set pupilLabeled to label all contiguous blobs in pupilIsolated
    pupilLabeled = bwlabel(pupilIsolated);
    %if pixels remain in pupilIsolated, continue with the analysis,
    %otherwise this is a blink frame.
    if sum(pupilLabeled(:)) > 0
        %calculate area, centroid, and eccentricity for each block in
        %pupilIsolated
        stats = regionprops(pupilLabeled, 'Area','Centroid','Eccentricity');
        %set pupilArea to the size of the largest blob in pupilIsolated. set
        %pupilLabel to the label number of the largest blob in pupilIsolated.
        [pupilArea, pupilLabel] = max([stats.Area]);
        %set centroid to that of largest blob in pupilIsolated.
        centroid = round(stats(pupilLabel).Centroid);
        %set eccentricity to that of largest blob in pupilIsolated.
        eccentricity = stats(pupilLabel).Eccentricity;
        %blob must have low eccentricity (i.e. approximate a circle) and have a
        %minimum number of pixels to be considered the pupil. If such a blob is
        %not detected, the frame is identified as a blink frame.
        if eccentricity < eccentricityThreshold &&  pupilArea > pupilSizeThreshold
            %check that the pupil centroid did not move more than
            %pupilMovementThreshold from its previous location
            if centroidPrev ~= [0 0]
                centroidMovement = (centroid(1) - centroidPrev(1))^2 + (centroid(2) - centroidPrev(2))^2;
                %If the pupil has not moved more than pupilMovementThreshold
                %from the previous frame, set pupilIsolate to true for the
                %largest blob
                if centroidMovement < pupilMovementThreshold^2
                    pupilIsolated  = (pupilLabeled == pupilLabel);
                    centroidPrev = centroid;
                    
                    if debug
                        debugFrame(centroid(2) - 2:centroid(2) + 2, centroid(1) - 2:centroid(1) + 2, 1) = 255;
                        debugFrame(centroid(2) - 2:centroid(2) + 2, centroid(1) - 2:centroid(1) + 2, 2) = 0;
                        debugFrame(centroid(2) - 2:centroid(2) + 2, centroid(1) - 2:centroid(1) + 2, 3) = 0;
                    end
                    
                    %If the pupil has exceeded the movement threshold, set
                    %pupilIsolated to black.
                else
                    pupilIsolated = false(size(frame));
                    blinkFrameList(frameNo) = true;
                end
            else
                %If the previous centroid value was [0 0] (i.e. has not been
                %established yet), this frame is not counted as a blink frame.
                pupilIsolated  = (pupilLabeled == pupilLabel);
                centroidPrev = centroid;
                
                if debug
                    debugFrame(centroid(2) - 2:centroid(2) + 2, centroid(1) - 2:centroid(1) + 2, 1) = 255;
                    debugFrame(centroid(2) - 2:centroid(2) + 2, centroid(1) - 2:centroid(1) + 2, 2) = 0;
                    debugFrame(centroid(2) - 2:centroid(2) + 2, centroid(1) - 2:centroid(1) + 2, 3) = 0;
                end
            end
        else
            pupilIsolated = false(size(frame));
            blinkFrameList(frameNo) = true;
        end
    else
        pupilIsolated = false(size(frame));
        blinkFrameList(frameNo) = true;
    end
    
    if debug
        subplot(2,1,1)
        imshow(debugFrame);
        subplot(2,1,2)
        imshow(pupilIsolated);
        pause(0.001)
    end
end

%Pad each blink frame by three frames on either side.
blinkFrameListTemp = blinkFrameList;

for frameNo = 1:size(blinkFrameList, 1)
    blinkFrameListTemp(frameNo) = max(blinkFrameList(max(1,frameNo - 3):min(size(blinkFrameList,1),frameNo + 3)));
end

blinkFrameList = blinkFrameListTemp;
                