function [out,irisIsolated,irisArea,centroid,avgPixelx,avgPixely] = IrisDetector(eye)
out = [1];
pupilIntensityThreshold = 20;
irisMovementThreshold = 20;
eccentricityThreshold = 1;
centroidPrev = [0 0];
irisSizeThreshLower = 1000;
irisSizeThreshUpper = 150000;
erodeDilateElement = strel('disk',5,0);
specularIntensity = 220;
counter = 0;

%%

    %set minIntensity to intensity of darkest pixel in frame
    minIntensity = min(eye(:));
    %fprintf('%d\n',sum(minIntensity(:)));
    %set irisIsolated to true for all pixels in frame within
    %pupilIntensityThreshold of minIntensity
    irisIsolated1 = eye <= minIntensity + pupilIntensityThreshold;
    %fprintf('%d\n',sum(irisIsolated1(:)));
    %add to irisIsolated frame any pixels with intensity higher than
    %specularIntensity
    irisIsolated2 = irisIsolated1 + (eye >= specularIntensity);
    %fprintf('%d\n',sum(irisIsolated2(:)));
%     while sum(irisIsolated2(:)) < 10000
%         minIntensity = 10 + counter;
%         irisIsolated1 = eye <= minIntensity + pupilIntensityThreshold;
%         irisIsolated2 = irisIsolated1 + (eye >= specularIntensity);
%         fprintf('counter: %d\n',counter);
%         counter = counter + 5;
%     end
    %dilate irisIsolated
    irisIsolated = imdilate(irisIsolated2, erodeDilateElement);
    %fill holes in irisIsolated
    irisIsolated = imfill(irisIsolated,'holes');
    %erode twice and dilate irisIsolated
    irisIsolated = imdilate(imerode(imerode(irisIsolated,erodeDilateElement),erodeDilateElement),erodeDilateElement);
    %set irisLabeled to label all contiguous blobs in pupilIsolated
    irisLabeled = bwlabel(irisIsolated);
    %calculate area, centroid, and eccentricity for each block in
    %pupilIsolated
    stats = regionprops(irisIsolated,'Area','Centroid','Eccentricity','PixelList');
    %set irisArea to the size of the largest blob in irisIsolated. set
    %irisLabel to the label number of the largest blob in irisIsolated.
    [irisArea, irisLabel] = max([stats.Area]);
    %set centroid to that of largest blob in irisIsolated.
    centroid = round(stats(irisLabel).Centroid);
    %set eccentricity to that of largest blob in irisIsolated.
    eccentricity = stats(irisLabel).Eccentricity;
    %set pixel list to that of largest blob in irisIsolated.
    pixelList = stats(irisLabel).PixelList;
    
    %%
    avgPixelx = mean(pixelList(1));
    avgPixely = mean(pixelList(2));
    if irisArea > 7000 && (max(pixelList(1)) < 200 || min(pixelList(1)) > 1175)    
        irisIsolated = [];
        fprintf('Too big and far from center: Area: %d   x Distance: [%d,%d]\n',irisArea,avgPixelx,avgPixely);
        out = 0;
        return
        %end
    end
    
    if irisArea > 20000 && (max(pixelList(1)) < 300 || min(pixelList(1)) > 1300)     %used 300 for vids 4-6
        irisIsolated = [];
        fprintf('Way too big and far from center: Area: %d   Center: [%d,%d]\n',irisArea,avgPixelx,avgPixely);
        out = 0;
        return
    end
    
    %blob must have low eccentricity (i.e. approximate a circle) and have a
    %minimum number of pixels to be considered the iris.
    %if eccentricity < eccentricityThreshold &  irisArea > irisSizeThreshold
    if irisArea > irisSizeThreshLower && irisArea < irisSizeThreshUpper && eccentricity && eccentricityThreshold
    %check that the iris centroid did not move more than
    %irisMovementThreshold from its previous location
        if centroidPrev ~= [0 0]
            centroidMovement = (centroid(1) - centroidPrev(1))^2 + (centroid(2) - centroidPrev(2))^2;
            %If the pupil has not moved more than irisMovementThreshold
            %from the previous frame, set pupilIsolate to true for the
            %largest blob
            if centroidMovement < irisMovementThreshold^2
                irisIsolated  = (irisLabeled == irisLabel);
                centroidPrev = centroid;
                out = 1;
            %If the pupil has exceeded the movement threshold,
            %delete frame
            else
                irisIsolated = [];
                fprintf('Centroid moved %d pixels\n',centroidMovement)
                out = 0;
                return
            end
        else
            %If the previous centroid value was [0 0] (i.e. has not been
            %established yet), then this frame is not a blink frame
            irisIsolated  = (irisLabeled == irisLabel);
            centroidPrev = centroid;
            out = 1;
        end             
    else
        irisIsolated = [];
        fprintf('Incorrect size: %d pixels\n',irisArea)
        out = 0;
        return
    end

%%
%     if isempty(irisIsolated) == 1;
%         out = 0;
%     end
%     subplot(1,3,1)
%     imshow(irisIsolated);
%     subplot(1,3,2)
%     imshow(eye);
%     subplot(1,3,3)
%     fuse = imfuse(eye,irisIsolated);
%     imshow(fuse);
%     pause(.5)
%     colormap gray
end