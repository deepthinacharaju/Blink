function [initialEye,initialArea,initialXCentroid,initialYCentroid,equivDiaSq,initialMeanGL] = initialIris(eye,fileList,fileNo)
% Uses blob analysis to determine where iris is when eye is fully
% open, for comparison against blob location during fullest blink
% (irisDetector.m)

pupilIntensityThreshold = 23;
irisSizeThreshLower = 1500;
irisSizeThreshUpper = 150000;
erodeDilateElement = strel('disk',5,0);
specularIntensity = 220;

debug = false;

%% Create mask to only look for iris around eye
    h_im = imshow(eye);
    e = imellipse(gca,[200 100 1250 700]);
    BW = createMask(e,h_im);
    eye(BW==0)=150;
    set(gcf,'Visible','off');
    eyeImage = eye;

%% Find blobs

    %set minIntensity to intensity of darkest pixel in frame
    minIntensity = min(eye(:));
    fprintf('minIntensity: %d\n',sum(minIntensity(:)));
    %set irisIsolated to true for all pixels in frame within
    %pupilIntensityThreshold of minIntensity
    irisIsolated1 = eye <= minIntensity + pupilIntensityThreshold;
    %fprintf('%d\n',sum(irisIsolated1(:)));
    %add to irisIsolated frame any pixels with intensity higher than
    %specularIntensity
    irisIsolated2 = irisIsolated1 + (eye >= specularIntensity);
    %irisIsolated2 = imcrop(irisIsolated,[300, 700, 1400, 100]);
    %fprintf('%d\n',sum(irisIsolated2(:)));

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
    if debug == true
        figure(40)
        subplot(2,1,1)
        imshow(irisIsolated)
        hold on
        for k = 1 : numberOfBoundaries
        thisBoundary = boundaries{k};
        plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
        end
        hold off
        title(sprintf('Before, Initial Iris, %s',fileList(fileNo).name));
        axis on
        %pause()
    end

    %% Get properties of each blob
    %if debug == true
        fprintf('initialIris.m :\n');
    %end
    for k = 1 : numberOfBlobs                                % Loop through all blobs.
        thisBlobsPixels = blobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
        meanGL = blobMeasurements(k).MeanIntensity;          % Get mean of current blob
        blobArea = blobMeasurements(k).Area;                 % Get area.
        blobPerimeter = blobMeasurements(k).Perimeter;		 % Get perimeter.
        blobCentroid = blobMeasurements(k).Centroid;		 % Get centroid one at a time.
        blobECD(k) = sqrt(4 * blobArea / pi);                % Compute ECD - Equivalent Circular Diameter.
        blobEccentricity = blobMeasurements(k).Eccentricity; % Get ecentricity.
        %if debug == true
            fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f %8.1f\n',...
                k, meanGL, blobArea, blobPerimeter, blobCentroid, blobECD(k),blobEccentricity);
        %end
    end
    
    %% Isolate blobs we care about
    allBlobAreas = [blobMeasurements.Area];
    allowableAreaIndexes = allBlobAreas > 1000; % Take the larger objects

    allBlobCentroids = [blobMeasurements.Centroid];
    centroidsX = allBlobCentroids(1:2:end-1);
    centroidsY = allBlobCentroids(2:2:end);
    allowableXIndexes = (centroidsX >= 500) & (centroidsX <= 1100); % Take centered objects
    allowableYIndexes = (centroidsY <= 725); % Don't want blobs too close to bottom (bc they're probs eyelashes) 

    allBlobEccs = [blobMeasurements.Eccentricity];
    allowableEccs = allBlobEccs < .95;
    
    keeperIndexes = find(allowableAreaIndexes & allowableXIndexes & allowableYIndexes & allowableEccs);
    % Extract only those blobs that meet our criteria, and
    % eliminate those blobs that don't meet our criteria.
    % Note how we use ismember() to do this.  Result will be an image - 
    % the same as labeledImage but with only the blobs listed in keeperIndexes in it.
    keeperBlobsImage = ismember(irisLabeled, keeperIndexes);
    % Re-label with only the keeper blobs kept.
    initialEye = bwlabel(keeperBlobsImage, 8);     % Label each blob so we can make measurements of it
    
    if debug == true
        figure(40)
        subplot(2,1,2)
        imshow(initialEye, []);
        hold on;
        boundaries = bwboundaries(initialEye);
        numberOfBoundaries = size(boundaries, 1);
        for k = 1 : numberOfBoundaries
            thisBoundary = boundaries{k};
            plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
        end
        hold off;
        title('After')
        pause()
    end

    newBlobMeasurements = regionprops(initialEye, eye, 'all');
    newNumberOfBlobs = size(newBlobMeasurements, 1);

    %% Classify blink
    newAllBlobAreas = [newBlobMeasurements.Area];
    initialArea = sum(newAllBlobAreas);
    newAllBlobCentroids = [newBlobMeasurements.Centroid];
    newCentroidsX = newAllBlobCentroids(1:2:end-1);
    newCentroidsY = newAllBlobCentroids(2:2:end);
    equivDiaSq = sqrt(4 * initialArea / pi);
    initialXCentroid = mean(newCentroidsX);
    initialYCentroid = mean(newCentroidsY);
    initialMeanGL = [newBlobMeasurements.MeanIntensity];
    if numel(initialMeanGL) > 1
        initialMeanGL = mean(initialMeanGL(:));
    end
    newEccentricity = [newBlobMeasurements.Eccentricity];
    if numel(newEccentricity) > 1
        newEccentricity = mean(newEccentricity);
    end
    
    if initialArea == 0
        fprintf('No iris-like blobs found.\n')
        return
    end
    %if debug == true
        fprintf('New blob measurements: \n');
        fprintf(1,'# 1 %17.1f %11.1f %17.1f % 8.1f %17.1f\n', initialMeanGL, initialArea, initialXCentroid, initialYCentroid, newEccentricity);
    %end

%     if initialArea > irisSizeThreshLower && initialXCentroid >= 500 && initialXCentroid <= 1100 && initialYCentroid <= 700
%         out = 1;
%         fprintf('Blob: Partial\n');
%     else
%         out = 0;
%         fprintf('Blob: Full\n');
%     end

%% Other Figures

% if debug == true
%       figure(75)
%       fuse = imfuse(irisLabeled,eyeImage);
%       imshow(fuse);
%       pause()
% end

%     figure(70)
%     imshow(initialEye)
%     hold on
%     scatter(initialXCentroid,initialYCentroid,'ro')
%     hold off
%     axis on
%     colormap gray
%     pause()

end