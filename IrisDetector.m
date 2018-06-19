function [out,irisLabeled,totalArea,totalXCentroid] = IrisDetector(eye)
% Uses blob analysis to determine if pupil and iris can be identified
% during frame with max gray level (fullest blink)

out = [];
pupilIntensityThreshold = 25;
irisMovementThreshold = 20;
eccentricityThreshold = 1;
centroidPrev = [0 0];
irisSizeThreshLower = 1500;
irisSizeThreshUpper = 150000;
erodeDilateElement = strel('disk',5,0);
specularIntensity = 220;

%% Mask for Eye, to try and get rid of blobs in corners being picked up
% xPoly = [200 400 600 800 1000 1200 1400 1200 1000 800 600 400 200];
% yPoly = [500 225 100 100 100  225 500  780  780  790 780 700 500];
% BW = poly2mask(xPoly,yPoly,832/2,1664/2);
    
%% Find blobs
%     croppedEye = imcrop(eye,[200 1 1200 832]);
%     eye = croppedEye;

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
    %irisIsolated2 = imcrop(irisIsolated,[300, 700, 1400, 100]);
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
    
    % Get all the blob properties.  
    blobMeasurements = regionprops(irisLabeled, eye, 'all');
    numberOfBlobs = size(blobMeasurements, 1);
    boundaries = bwboundaries(irisIsolated);
    numberOfBoundaries = size(boundaries, 1);
%     figure(21)
%     subplot(2,1,1)
%     imshow(irisIsolated)
%     hold on
%     for k = 1 : numberOfBoundaries
% 	thisBoundary = boundaries{k};
% 	plot(thisBoundary(:,2), thisBoundary(:,1), 'g', 'LineWidth', 2);
%     end
%     title('Before')
%     hold off

    %% Get properties of each blob
    for k = 1 : numberOfBlobs           % Loop through all blobs.
        thisBlobsPixels = blobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
        meanGL = blobMeasurements(k).MeanIntensity; % Get mean of current blob
        blobArea = blobMeasurements(k).Area;		% Get area.
        blobPerimeter = blobMeasurements(k).Perimeter;		% Get perimeter.
        blobCentroid = blobMeasurements(k).Centroid;		% Get centroid one at a time
        blobECD(k) = sqrt(4 * blobArea / pi);					% Compute ECD - Equivalent Circular Diameter.
        fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f\n', k, meanGL, blobArea, blobPerimeter, blobCentroid, blobECD(k));
    end
    
    %% Isolate blobs we care about
    allBlobAreas = [blobMeasurements.Area];
    allowableAreaIndexes = allBlobAreas > 1000; % Take the larger objects

    allBlobCentroids = [blobMeasurements.Centroid];
    centroidsX = allBlobCentroids(1:2:end-1);
    centroidsY = allBlobCentroids(2:2:end);
    allowableXIndexes = (centroidsX >= 500) & (centroidsX <= 1100); % Take centered objects
    allowableYIndexes = (centroidsY <= 725); % Don't want blobs too close to bottom (bc they're probs eyelashes) 

    keeperIndexes = find(allowableAreaIndexes & allowableXIndexes & allowableYIndexes);
    % Extract only those blobs that meet our criteria, and
    % eliminate those blobs that don't meet our criteria.
    % Note how we use ismember() to do this.  Result will be an image - 
    % the same as labeledImage but with only the blobs listed in keeperIndexes in it.
    keeperBlobsImage = ismember(irisLabeled, keeperIndexes);
    % Re-label with only the keeper blobs kept.
    irisLabeled = bwlabel(keeperBlobsImage, 8);     % Label each blob so we can make measurements of it
%     figure(21)
%     subplot(2,1,2)
%     imshow(irisLabeled, []);
%     hold on;
%     boundaries = bwboundaries(irisLabeled);
%     numberOfBoundaries = size(boundaries, 1);
%     for k = 1 : numberOfBoundaries
%         thisBoundary = boundaries{k};
%         plot(thisBoundary(:,2), thisBoundary(:,1), 'g', 'LineWidth', 2);
%     end
%     hold off;
%     title('After')

    newBlobMeasurements = regionprops(irisLabeled, eye, 'all');
    newNumberOfBlobs = size(newBlobMeasurements, 1);

    %% Classify blink
    newAllBlobAreas = [newBlobMeasurements.Area];
    totalArea = sum(newAllBlobAreas);
    newAllBlobCentroids = [newBlobMeasurements.Centroid];
    newCentroidsX = newAllBlobCentroids(1:2:end-1);
    newCentroidsY = newAllBlobCentroids(2:2:end);
    totalXCentroid = mean(newCentroidsX);
    totalYCentroid = mean(newCentroidsY);
    if totalArea > irisSizeThreshLower && totalXCentroid >= 500 && totalXCentroid <= 1100 && totalYCentroid <= 700
        out = 1;
        fprintf('Blob: Partial\n');
    else
        out = 0;
        fprintf('Blob: Full\n');
    end
    %% Old Code
    %calculate area, centroid, and eccentricity for each block in
    %pupilIsolated
    %stats = regionprops(irisLabeled,'Area','Centroid','Eccentricity','PixelList');
    %set irisArea to the size of the largest blob in irisIsolated. set
    %irisLabel to the label number of the largest blob in irisIsolated.
    %[irisArea, irisLabel] = max([stats.Area]);
    %set centroid to that of largest blob in irisIsolated.
    %centroid = round(stats(irisLabel).Centroid);
    %set eccentricity to that of largest blob in irisIsolated.
    %eccentricity = stats(irisLabel).Eccentricity;
    %set pixel list to that of largest blob in irisIsolated.
    %pixelList = stats(irisLabel).PixelList;
%       figure(5)
%       imshow(irisIsolated)

%     avgPixelx = mean(pixelList(1));
%     avgPixely = mean(pixelList(2));
%     if irisArea > 7000 && (max(pixelList(1)) < 200 || min(pixelList(1)) > 1175)    
%         irisIsolated = [];
%         fprintf('Too big and far from center: Area: %d   x Distance: [%d,%d]\n',irisArea,avgPixelx,avgPixely);
%         out = 0;
%         return
%         %end
%     end
%     
%     if sum(sum(irisIsolated(750:end,:))) > 0 
%         irisIsolated = [];
%         fprintf('Blob too low: [%d,%d]\n',avgPixelx,avgPixely);
%         out = 0;
%         return
%     end
%     
%     if irisArea > 15000 && (max(pixelList(1)) < 425 || min(pixelList(1)) > 1300)     %used 300 for vids 4-6
%         irisIsolated = [];
%         fprintf('Way too big and far from center: Area: %d   Center: [%d,%d]\n',irisArea,avgPixelx,avgPixely);
%         out = 0;
%         return
%     end
    
    %blob must have low eccentricity (i.e. approximate a circle) and have a
    %minimum number of pixels to be considered the iris.
    %if eccentricity < eccentricityThreshold &  irisArea > irisSizeThreshold
%     if irisArea > irisSizeThreshLower && irisArea < irisSizeThreshUpper
    %check that the iris centroid did not move more than
    %irisMovementThreshold from its previous location
%         if centroidPrev ~= [0 0]
%             centroidMovement = (centroid(1) - centroidPrev(1))^2 + (centroid(2) - centroidPrev(2))^2;
            %If the pupil has not moved more than irisMovementThreshold
            %from the previous frame, set pupilIsolate to true for the
            %largest blob
%             if centroidMovement < irisMovementThreshold^2
%                 irisIsolated  = (irisLabeled == irisLabel);
%                 %centroidPrev = centroid;
%                 out = 1;
            %If the pupil has exceeded the movement threshold,
            %delete frame
%             else
%                 irisIsolated = [];
%                 fprintf('Centroid moved %d pixels\n',centroidMovement)
%                 out = 0;
%                 return
%             end
%         else
%             %If the previous centroid value was [0 0] (i.e. has not been
%             %established yet), then this frame is not a blink frame
%             irisIsolated  = (irisLabeled == irisLabel);
%             centroidPrev = centroid;
%             out = 1;
%         end             
%     else
%         irisIsolated = []; %if iris not found (full blink), delete entry
%         fprintf('Incorrect size: %d pixels\n',irisArea)
%         out = 0;
%         return
%     end

%% Other Figures
%     if isempty(irisIsolated) == 1;
%         out = 0;
%     end
%     figure(5)
%     subplot(1,3,1)
%     imshow(irisIsolated);
%     subplot(1,3,2)
%     imshow(eye);
%     subplot(1,3,3)
%     fuse = imfuse(eye,irisIsolated);
%     imshow(fuse);
%     pause(.5)

%       figure(5)
%       imshow(irisIsolated)
%       pause
%       hold on
%       plot(xPoly,yPoly,'r','LineWidth',2)
%       hold off
%       axis on
%     colormap gray
end