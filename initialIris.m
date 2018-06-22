function [initialEye,initialArea,initialXCentroid,initialYCentroid,equivDiaSq,initialMeanGL] = initialIris(eye,fileList,fileNo)
% Uses blob analysis to determine where iris is when eye is fully
% open, for comparison against blob location during fullest blink
% (irisDetector.m)

% These values are arbitrary
pupilIntensityThreshold = 23;
irisSizeThreshLower = 1500;
irisSizeThreshUpper = 80000;
erodeDilateElement = strel('disk',5,0);
specularIntensity = 220;

debug = false;

%% Create mask to only look for iris around eye
    figure(50)
    eyeImage = eye;
    eye2 = eye;
    h_im = imshow(eye);
    e = imellipse(gca,[200 100 1250 700]);
    BW = createMask(e,h_im);
    eye2(BW==0)=150;
    fig = gcf;
    set(gcf,'visible','off');
    eye = eye2;

%% Find blobs

    %set minIntensity to intensity of darkest pixel in frame
    minIntensity = min(eye(:));
    if debug == true
        fprintf('minIntensity: %d\n',sum(minIntensity(:)));
    end
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
        figure(25)
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
  
    % Get rid of really big blobs that contain iris & eyelashes by
    % decreasing pupilIntensityThreshold
    largeBlobAreas = allBlobAreas > irisSizeThreshUpper;
    areaCount = 0;
    while sum(largeBlobAreas(:)) > 0 && areaCount < 6
        pupilIntensityThreshold = 20 - areaCount*2.5;
        irisIsolated1 = eye <= minIntensity + pupilIntensityThreshold;
        irisIsolated2 = irisIsolated1 + (eye >= specularIntensity);
        irisIsolated = imdilate(irisIsolated2, erodeDilateElement);
        irisIsolated = imfill(irisIsolated,'holes');
        irisIsolated = imdilate(imerode(imerode(irisIsolated,erodeDilateElement),erodeDilateElement),erodeDilateElement);
        irisLabeled = bwlabel(irisIsolated);
        blobMeasurements = regionprops(irisLabeled, eye, 'all');
        numberOfBlobs = size(blobMeasurements, 1);
        boundaries = bwboundaries(irisIsolated);
        numberOfBoundaries = size(boundaries, 1);

        if debug == true
            figure(25)
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
        
        %if debug == true
            fprintf('Big blobs, running again (Attempt %i):\n',(areaCount+1));
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
                fprintf(1,'#%2d %17.1f %11.1f %8.1f %8.1f %8.1f % 8.1f %8.3f\n',...
                    k, meanGL, blobArea, blobPerimeter, blobCentroid, blobECD(k),blobEccentricity);
            %end
        end
        allBlobAreas = [blobMeasurements.Area];
        largeBlobAreas = allBlobAreas > irisSizeThreshUpper;
        areaCount = areaCount + 1;
    end            
    
    if areaCount == 6
        fprintf('Error: Could not get rid of large blobs, no iris found\n');
        return
    end
    
    allowableAreaIndexes = allBlobAreas > 1000; % Take the larger objects
    allBlobCentroids = [blobMeasurements.Centroid];
    centroidsX = allBlobCentroids(1:2:end-1);
    centroidsY = allBlobCentroids(2:2:end);
    allowableXIndexes = (centroidsX >= 500) & (centroidsX <= 1100); % Take centered objects
    allowableYIndexes = (centroidsY <= 725); % Don't want blobs too close to bottom (bc they're probs eyelashes) 
    allBlobEccs = [blobMeasurements.Eccentricity];
    allowableEccs = allBlobEccs < 1;

    
%     fprintf('Area: %3.1f\n',allowableAreaIndexes);
%     fprintf('X In: %3.1f\n',allowableXIndexes);
%     fprintf('Y In: %3.1f\n',allowableYIndexes);
%     fprintf('Eccs: %3.1f\n',allowableEccs);
    
    keeperIndexes = find(allowableAreaIndexes & allowableXIndexes & allowableYIndexes & allowableEccs);
%     fprintf('keeperIndexes: %f\n',keeperIndexes);
    % Extract only those blobs that meet our criteria, and
    % eliminate those blobs that don't meet our criteria.
    % Note how we use ismember() to do this.  Result will be an image - 
    % the same as labeledImage but with only the blobs listed in keeperIndexes in it.
    keeperBlobsImage = ismember(irisLabeled, keeperIndexes);
    % Re-label with only the keeper blobs kept.
    initialEye = bwlabel(keeperBlobsImage, 8);     % Label each blob so we can make measurements of it
    
    if debug == true
        figure(25)
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
        pause(5)
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
    
    % weight centroids and gray levels with respect to area of blobs
    if newNumberOfBlobs > 1
        initialXCentroid = sum((newCentroidsX.*newAllBlobAreas)/initialArea);
        initialYCentroid = sum((newCentroidsY.*newAllBlobAreas)/initialArea);
        initialMeanGL = sum((initialMeanGL.*newAllBlobAreas)/initialArea);
    end

    % if blob is really, really dark, increase it a bit so the GLRatio
    % isn't impossibly low
    if initialMeanGL < 10
        initialMeanGL = 10;
    end
    newEccentricity = [newBlobMeasurements.Eccentricity];
    
    if debug == true
        fprintf('Updated initialIris.m blobs (before Ecc test):\n');
        for k = 1 : newNumberOfBlobs                                % Loop through all blobs.
        thisBlobsPixels = newBlobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
        meanGL2 = newBlobMeasurements(k).MeanIntensity;          % Get mean of current blob
        blobArea2 = newBlobMeasurements(k).Area;                 % Get area.
        blobPerimeter2 = newBlobMeasurements(k).Perimeter;		 % Get perimeter.
        blobCentroid2 = newBlobMeasurements(k).Centroid;		 % Get centroid one at a time.
        blobEccentricity2 = newBlobMeasurements(k).Eccentricity; % Get ecentricity.
        fprintf(1,'#%2d %17.1f %11.1f %17.1f %8.1f %17.3f\n',...
           k, meanGL2, blobArea2, blobCentroid2,blobEccentricity2);
        end
    end
    
    % if there's multiple blobs (of the correct size) but one is really 
    % circular (eccentricity less than 0.7), get rid of less circular blobs
    smallEccs = newEccentricity < 0.71;
    fprintf('Number of Blobs with Small Eccentricities: %i\n',sum(smallEccs));
    if newNumberOfBlobs > 1 && sum(smallEccs) >= 1
        if debug == true
            figure(30)
            subplot(2,1,1)
            imshow(initialEye, []);
            hold on;
            boundaries = bwboundaries(initialEye);            
            numberOfBoundaries = size(boundaries, 1);
            for k = 1 : numberOfBoundaries
                thisBoundary = boundaries{k};
                plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
            end
            hold off;
            title(sprintf('Before Eccentricity Constrains, %s',fileList(fileNo).name'))
        end
        fprintf('Isolating most circular blob\n');
        allowableAreaIndexes2 = newAllBlobAreas > 1000; % Take the larger objects
        centroidsX = newAllBlobCentroids(1:2:end-1);
        centroidsY = newAllBlobCentroids(2:2:end);
        allowableXIndexes2 = (centroidsX >= 500) & (centroidsX <= 1100); % Take centered objects
        allowableYIndexes2 = (centroidsY <= 725);
        allowableEccs2 = newEccentricity < 0.71;
        keeperIndexes2 = find(allowableAreaIndexes2 & allowableXIndexes2 & allowableYIndexes2 & allowableEccs2);
        keeperBlobsImage2 = ismember(initialEye, keeperIndexes2);
        initialEye = bwlabel(keeperBlobsImage2, 8); 
        if debug == true
            figure(30)
            subplot(2,1,2)
            imshow(initialEye, []);
            hold on;
            boundaries2 = bwboundaries(initialEye);
            numberOfBoundaries2 = size(boundaries2, 1);
            for k = 1 : numberOfBoundaries2
                thisBoundary = boundaries2{k};
                plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
            end
            hold off;
            title('After, New n Improved')
            %pause()
        end
        
        % Reclassify 
        newBlobMeasurements = regionprops(initialEye, eye, 'all');
        newNumberOfBlobs = size(newBlobMeasurements, 1);
        newAllBlobAreas = [newBlobMeasurements.Area];
        initialArea = sum(newAllBlobAreas);
        newAllBlobCentroids = [newBlobMeasurements.Centroid];
        newCentroidsX = newAllBlobCentroids(1:2:end-1);
        newCentroidsY = newAllBlobCentroids(2:2:end);
        equivDiaSq = sqrt(4 * initialArea / pi);
        initialXCentroid = mean(newCentroidsX);
        initialYCentroid = mean(newCentroidsY);
        initialMeanGL = [newBlobMeasurements.MeanIntensity];
        
        % weight centroids and gray levels with respect to area of blobs
        if newNumberOfBlobs > 1
            initialXCentroid = sum((newCentroidsX.*newAllBlobAreas)/initialArea);
            initialYCentroid = sum((newCentroidsY.*newAllBlobAreas)/initialArea);
            initialMeanGL = sum((initialMeanGL.*newAllBlobAreas)/initialArea);
        end
        % if blob is really, really dark, increase it a bit so the GLRatio
        % isn't impossibly low
        if initialMeanGL < 10
            initialMeanGL = 10;
        end
        newEccentricity = [newBlobMeasurements.Eccentricity];
    end
    
    if debug == true
        fprintf('Updated initialIris.m blobs:\n');
        for k = 1 : newNumberOfBlobs                                % Loop through all blobs.
        thisBlobsPixels = newBlobMeasurements(k).PixelIdxList;  % Get list of pixels in current blob.
        meanGL3 = newBlobMeasurements(k).MeanIntensity;          % Get mean of current blob
        blobArea3 = newBlobMeasurements(k).Area;                 % Get area.
        blobCentroid3 = newBlobMeasurements(k).Centroid;		 % Get centroid one at a time.
        blobEccentricity3 = newBlobMeasurements(k).Eccentricity; % Get ecentricity.
        fprintf(1,'#%2d %17.1f %11.1f %17.1f %8.1f %17.3f\n',...
           k, meanGL3, blobArea3, blobCentroid3,blobEccentricity3);
        end
    end
        
    if numel(newEccentricity) > 1
        newEccentricity = mean(newEccentricity);
    end
    
    if initialArea == 0
        fprintf('No iris-like blobs found.\n')
        return
    end
    %if debug == true
        fprintf('New blob measurements: \n');
        fprintf(1,'# 1 %17.1f %11.1f %17.1f % 8.1f %17.3f\n', initialMeanGL, initialArea, initialXCentroid, initialYCentroid, newEccentricity);
    %end
    if debug == true
        pause()
    end

%% Other Figures

% if debug == true
%       figure(55)
%       fuse = imfuse(irisLabeled,eyeImage);
%       imshow(fuse);
%       pause()
% end

%     figure(60)
%     imshow(initialEye)
%     hold on
%     scatter(initialXCentroid,initialYCentroid,'ro')
%     hold off
%     axis on
%     colormap gray
%     pause()

end