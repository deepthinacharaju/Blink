function [out,irisLabeled,totalArea,totalXCentroid,totalYCentroid,newMeanGL] = IrisDetector(eye,initialXCentroid,initialYCentroid,equivDiaSq)
% Uses blob analysis to determine if iris can be identified during frame
% with max gray level (fullest blink), and if it's in same place as fully
% open eye

out = 2;
% these values are arbitrary...
pupilIntensityThreshold = 25;
irisSizeThreshold = 115; %previously 150
irisMovementThreshold = 213;
irisSizeThreshLower = 2000;
irisSizeThreshUpper = 150000;
erodeDilateElement = strel('disk',5,0);
specularIntensity = 220;
movementThresholdX = 150;
movementThresholdY = 215.5;

debug = false;

%% Mask for Eye, to only look at area iris initially was

origEye = eye;
eyeImage = eye;
imagesizex = size(eye,2);
imagesizey = size(eye,1);
sizeEye = size(eye);
[colImage, rowImage] = meshgrid(1:imagesizex,1:imagesizey); % meshgrid is same size as image (eye)
circlepixels = zeros(sizeEye);
z = circlepixels;
centerX = initialXCentroid; % center of mask corresponds to center of blob from initialIris.m
centerY = initialYCentroid;
ind = sub2ind(sizeEye,centerY,centerX);
actualRadius = equivDiaSq / 2;
radius = actualRadius + irisSizeThreshold; % mask has a radius slightly bigger than equiv radius of blob from initialIris.m
% if mask goes out of frame, error has occured
if centerY > imagesizey - actualRadius || centerY < actualRadius || ...
        centerX < actualRadius || centerX > imagesizex - actualRadius
    fprintf('Error: Mask goes out of frame, no iris found.\n');
    fprintf('Size: %i x %i\nCenter: [%f, %f]\nRadius: %f\n',imagesizex, imagesizey,centerX,centerY,radius);
    out = 2;
    irisLabeled = [];
    totalArea = [];
    totalXCentroid = [];
    totalYCentroid = [];
    newMeanGL = [];
    return
end
circlepixels((rowImage - centerY).^2 + (colImage - centerX).^2 <= radius^2) = 1;

h = fspecial('disk',radius);
thresh = 10000000;
h(h~=0) = thresh;
hsize = size(h);
% fprintf('size(eye): %i x %i\n centerX: %f\n centerY: %f\n radius: %f\n hsize: %i x %i\n', ...
%      size(eye),centerX,centerY, radius, size(h));
centerYhsize1 = ceil(centerY - hsize(1)./2);
centerYhsize2 = ceil(centerY + hsize(1)./2) - 1;

if centerYhsize1 <= 0 % centerYhsize1 can't be negative, and centerYhsize2 must be same size
    absCenterY = abs(centerYhsize1);
    centerYhsize1 = 1;
    centerYhsize2 = centerYhsize2 + absCenterY + 1;
end
eye(centerYhsize1 : centerYhsize2, ceil(centerX - hsize(2)./2) : ceil(centerX + hsize(2)./2) - 1) = h;
eye2 = eye;
eye2(eye == 255) = 255;
mask = eye2;
mask(eye ~= 255) = 0;
eyeImage(mask == 0) = 150; % set everything that's not mask to gray (plain white seemed to mess it up)

if debug == true
    figure(35)
    imshow(eyeImage);
    axis on
    set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
    pause(5)
end

eye = eyeImage;


%% Find blobs

%set minIntensity to intensity of darkest pixel in frame
minIntensity = min(eye(:));
if debug == true
    fprintf('minIntensity: %f\n',minIntensity);
end
%set irisIsolated to true for all pixels in frame within
%pupilIntensityThreshold of minIntensity
irisIsolated1 = eye <= minIntensity + pupilIntensityThreshold;
%add to irisIsolated frame any pixels with intensity higher than
%specularIntensity
irisIsolated2 = irisIsolated1 + (eye >= specularIntensity); %I don't understand this line

%dilate irisIsolated
irisIsolated = imdilate(irisIsolated2, erodeDilateElement);
%fill holes in irisIsolated
irisIsolated = imfill(irisIsolated,'holes');
%erode twice and dilate irisIsolated
irisIsolated = imdilate(imerode(imerode(irisIsolated,erodeDilateElement),erodeDilateElement),erodeDilateElement);

if debug == true
    figure(40)
    subplot(1,3,1)
    imshow(irisIsolated1);
    subplot(1,3,2)
    imshow(irisIsolated2);
    subplot(1,3,3)
    imshow(irisIsolated);
    %pause()
end

%set irisLabeled to label all contiguous blobs in pupilIsolated
irisLabeled = bwlabel(irisIsolated);

% Get info on blobs
blobMeasurements = regionprops(irisLabeled, eye, 'all');
numberOfBlobs = size(blobMeasurements, 1);
boundaries = bwboundaries(irisIsolated);
numberOfBoundaries = size(boundaries, 1);

if numberOfBlobs == 0
    fprintf('No blobs found.\n');
    out = 0;
    irisLabeled = [];
    totalArea = [];
    totalXCentroid = [];
    totalYCentroid = [];
    newMeanGL = [];
    return
end

if debug == true
    figure(45)
    subplot(2,1,1)
    imshow(irisIsolated)
    hold on
    for k = 1 : numberOfBoundaries
        thisBoundary = boundaries{k};
        plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
    end
    title('Before, Iris Detector')
    hold off
    %pause()
end

%% Get properties of each blob
if debug == true
    fprintf('IrisDetector.m :\n');
end
for k = 1 : numberOfBlobs                                   % Loop through all blobs.
    thisBlobsPixels = blobMeasurements(k).PixelIdxList;     % Get list of pixels in current blob.
    meanGL = blobMeasurements(k).MeanIntensity;             % Get mean of current blob
    blobArea = blobMeasurements(k).Area;                    % Get area.
    blobPerimeter = blobMeasurements(k).Perimeter;      	% Get perimeter.
    blobCentroid = blobMeasurements(k).Centroid;        	% Get centroid one at a time
    blobECD(k) = sqrt(4 * blobArea / pi);					% Compute ECD - Equivalent Circular Diameter.
    blobEccentricity = blobMeasurements(k).Eccentricity; % Get ecentricity.
    if debug == true
        fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f %8.3f\n',...
            k, meanGL, blobArea, blobPerimeter, blobCentroid, blobECD(k),blobEccentricity);
    end
end

%% Isolate blobs we care about

allBlobAreas = [blobMeasurements.Area];
allowableAreaIndexes = allBlobAreas > 1250 & allBlobAreas < 1384440; % Take the larger objects (but not the ones that are the entire frame)
allBlobCentroids = [blobMeasurements.Centroid];
centroidsX = allBlobCentroids(1:2:end-1);
centroidsY = allBlobCentroids(2:2:end);
allowableXIndexes = abs(centroidsX - initialXCentroid) <= 150;  % Centroid is allowed to move further in y dir than x
allowableYIndexes = abs(centroidsY - initialYCentroid) <= 215.5;
allMeanGL = [blobMeasurements.MeanIntensity];
allowableGL = allMeanGL < 190;                                  % Don't want really light-colored blobs
allowablesmallGL = allMeanGL < 60;
%allEccentricity = [blobMeasurements.Eccentricity];
%allowableEcc = allEccentricity < 0.9957; % prev .9957            % Basically all blobs that aren't straight lines

% if smaller blobs (1000 pixels) make up more than half of the blobs and
% are really close to each other (like a bigger blob getting broken up 
% by eyelashes), use different area index to allow them
%numSmallBlobs = sum(allBlobAreas > 1000 & allBlobAreas < 2250);

% if numSmallBlobs > 1 && numberOfBlobs/numSmallBlobs < 2 % && sum(allowableXIndexes) > 1 && sum(allowableYIndexes) > 1
%     if sum(abs(diff(centroidsX)) < 8) >= 1 || sum(abs(diff(centroidsY)) < 8) >= 1 %previously 7.5, prev |
%         if debug == true
%             fprintf('Allowing smaller blobs\n');
%         end
%         allowableAreaIndexes = allBlobAreas > 1000 & allBlobAreas < 1384440;
%     end
% end

keeperIndexes = find(allowableAreaIndexes & allowableXIndexes & allowableYIndexes & allowableGL);

% isolate darkest blobs, if multiple blobs
% if numberOfBlobs > 1 && sum(allowablesmallGL) >= 1
%     if debug == true
%         fprintf('Isoalting dark blob(s)\n');
%     end
%     keeperIndexes = find(allowableAreaIndexes & allowableXIndexes ...
%         & allowableYIndexes & allowableEcc & allowablesmallGL);
% end

% Extract only those blobs that meet our criteria, and
% eliminate those blobs that don't meet our criteria.
% Note how we use ismember() to do this.  Result will be an image -
% the same as labeledImage but with only the blobs listed in keeperIndexes in it.
keeperBlobsImage = ismember(irisLabeled, keeperIndexes);
% Re-label with only the keeper blobs kept.
irisLabeled = bwlabel(keeperBlobsImage, 8);     % Label each blob so we can make measurements of it

if debug == true
    figure(45)
    subplot(2,1,2)
    imshow(irisLabeled, []);
    hold on;
    boundaries = bwboundaries(irisLabeled);
    numberOfBoundaries = size(boundaries, 1);
    for k = 1 : numberOfBoundaries
        thisBoundary = boundaries{k};
        plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
    end
    hold off;
    title('After')
    pause(5)
end

% new properties
newBlobMeasurements = regionprops(irisLabeled, eye, 'all');
newNumberOfBlobs = size(newBlobMeasurements, 1);
allBlobAreas = [newBlobMeasurements.Area];
allBlobCentroids = [newBlobMeasurements.Centroid];
centroidsX = allBlobCentroids(1:2:end-1);
centroidsY = allBlobCentroids(2:2:end);
allMeanGL = [newBlobMeasurements.MeanIntensity];
allowableGL = allMeanGL < 190;
smallGL = allMeanGL < 60;
%allEccentricity = [newBlobMeasurements.Eccentricity];

% If more than two blobs, make requirements stricter (bigger blobs,
% closer to previous centroid, darker)
areaThresh = 250;
centerThresh = 25; %prev 50
loopCount = 0;
while newNumberOfBlobs > 2 && loopCount < 5
    if debug == true
        fprintf('Reducing number of blobs, attempt %i.\n %i blobs left.\n',loopCount+1,newNumberOfBlobs);
    end
    % requirements become stricter with each trip through the loop (except
    % eccentricity)
    allowableAreaIndexes = allBlobAreas > 2250 + loopCount*areaThresh & allBlobAreas < 1384440;
    allowableXIndexes = abs(centroidsX - initialXCentroid) <= 125 - loopCount*centerThresh;
    allowableYIndexes = abs(centroidsY - initialYCentroid) <= 215 - loopCount*centerThresh;
    %allowableEcc = allEccentricity < .9957; % prev .9957
    
    % if smaller blobs (1000 pixels) are really close to each other (like a
    % bigger blob getting broken up by eyelashes), use different area index
%     if sum(allBlobAreas > 1000 & allBlobAreas < 2250) > 1 && sum(allowableXIndexes) > 1 && sum(allowableYIndexes) > 1
%         if sum(abs(diff(centroidsX)) < 8) >= 1 | sum(abs(diff(centroidsY)) < 8) >= 1 %previously 7.5
%             if debug == true
%                 fprintf('Allowing smaller blobs\n');
%             end
%             allowableAreaIndexes = allBlobAreas > 1000 + loopCount*areaThresh & allBlobAreas < 1384440;
%         end
%     end
    
    % isolate dark blobs if present
%     if sum(smallGL) >= 1
%         allowableGL = allMeanGL < 60;
%     end
    
    keeperIndexes = find(allowableAreaIndexes & allowableXIndexes & allowableYIndexes & allowableGL);
    keeperBlobsImage = ismember(irisLabeled, keeperIndexes);
    irisLabeled = bwlabel(keeperBlobsImage, 8);
    if debug == true
        figure(45)
        subplot(2,1,2)
        imshow(irisLabeled, []);
        hold on;
        boundaries = bwboundaries(irisLabeled);
        numberOfBoundaries = size(boundaries, 1);
        for k = 1 : numberOfBoundaries
            thisBoundary = boundaries{k};
            plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
        end
        hold off;
        title('After')
        pause(5)
    end
    newBlobMeasurements = regionprops(irisLabeled, eye, 'all');
    newNumberOfBlobs = size(newBlobMeasurements, 1);
    loopCount = loopCount + 1;
end

%% Recharacterize blobs

if newNumberOfBlobs == 0
    fprintf('No blobs found\n');
    out = 0;
    totalArea = [];
    totalXCentroid = [];
    totalYCentroid = [];
    newMeanGL = [];
    if debug == true
        fprintf('full\n');
        pause()
    end
    return
end

newAllBlobAreas = [newBlobMeasurements.Area];
totalArea = sum(newAllBlobAreas);
newAllBlobCentroids = [newBlobMeasurements.Centroid];
newCentroidsX = newAllBlobCentroids(1:2:end-1);
if debug == true
    fprintf('X Centroids: %f\n',newCentroidsX);
end
newCentroidsY = newAllBlobCentroids(2:2:end);
newMeanGL = [newBlobMeasurements.MeanIntensity];
%totalEccentricity = [newBlobMeasurements.Eccentricity];

% weight centroids, gray levels, and eccentricities with respect to area of blobs
if newNumberOfBlobs > 1
    totalXCentroid = sum((newCentroidsX.*newAllBlobAreas)/totalArea);
    totalYCentroid = sum((newCentroidsY.*newAllBlobAreas)/totalArea);
    newMeanGL = sum((newMeanGL.*newAllBlobAreas)/totalArea);
    %totalEccentricity = sum((totalEccentricity.*newAllBlobAreas)/totalArea);
else
    totalXCentroid = newCentroidsX;
    totalYCentroid = newCentroidsY;
end

if debug == true
    fprintf('New blob measurements: \n');
    fprintf(1,'# 1 %17.1f %11.1f %17.1f % 8.1f\n', newMeanGL, ...
        totalArea, totalXCentroid, totalYCentroid);
end

%% Classify blinks

% Blob must be at least a certain size to qualify as iris
if totalArea > irisSizeThreshLower
        %   Blob centroid cannot too far in X or Y directions from initial
        %   blob centroid
%         movementX = abs(totalXCentroid - initialXCentroid);
%         movementY = abs(totalYCentroid - initialYCentroid);
%         if movementX < movementThresholdX
%             if movementY < movementThresholdY
                if newMeanGL / mean(origEye(:)) < 0.5607 % prev .561
                    out = 1;
                    fprintf('gray level intensity: %3.5f\n',newMeanGL/mean(origEye(:)));
                    fprintf('partial\n');
                else
                    fprintf('Blob not dark enough, gray level intensity: %3.3f\n',newMeanGL/mean(origEye(:)));
                    out = 0;
                    fprintf('full\n');
                    return
                end
%             else
%                 fprintf('Blob moved too far in y direction - %3.5f pixels\n',movementY);
%                 out = 0;
%                 fprintf('full\n');
%                 return
%             end
%         else
%             fprintf('Blob moved too far in x direction - %3.5f pixels\n',movementX);
%             out = 0;
%             fprintf('full\n');
%             return
%         end
else
    fprintf('Blob not correct size\n');
    out = 0;
    fprintf('full\n');
    return
end
if debug == true
    pause()
end

%% Other Figures

%     figure(65)
%     imshow(irisLabeled)
%     hold on
%     scatter(totalXCentroid,totalYCentroid,'ro')
%     hold off
%     axis on
%     colormap gray
%     pause()
end