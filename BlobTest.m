clf; clear all;
close all;
filepath = 'C:\Users\dnacharaju\Documents\GitKraken\blink\SampleVideos\TestFolder'; % change to actual location

%GenerateBlinkVideos(filepath); %generates videos for each blink

fileList = dir([filepath,'\*.avi']);

c = cell(numel(fileList),2);
out = 1;
oldcenter = [];
pupilIntensityThreshold = 25;
irisMovementThreshold = 150;
eccentricityThreshold = 1;
centroidPrev = [0 0];
irisSizeThreshold = 5000;
erodeDilateElement = strel('disk',5,0);
specularIntensity = 220;

for fileNo = 1:size(fileList,1);
    if ~strcmp(fileList(fileNo).name(end-6:end),'RAW.avi') %allows original file to be skipped
        c{fileNo, 1} = fileList(fileNo).name;
        tic
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        fprintf(fileList(fileNo).name)
        fprintf('\n')
        
        while hasFrame(clip)
            eye = readFrame(clip);
            irisIsolated = eye;
            %set minIntensity to intensity of darkest pixel in frame
            minIntensity = min(irisIsolated(:));
            %set irisIsolated to true for all pixels in frame within
            %pupilIntensityThreshold of minIntensity
            irisIsolated = irisIsolated <= minIntensity + pupilIntensityThreshold;
            %add to irisIsolated frame any pixels with intensity higher than
            %specularIntensity
            irisIsolated = irisIsolated + (irisIsolated >= specularIntensity);
            %dilate irisIsolated
            irisIsolated = imdilate(irisIsolated, erodeDilateElement);
            %fill holes in irisIsolated
            irisIsolated = imfill(irisIsolated,'holes');
            %erode twice and dilate irisIsolated
            irisIsolated = imdilate(imerode(imerode(irisIsolated,erodeDilateElement),erodeDilateElement),erodeDilateElement);
            %fill holes in irisIsolated
            irisIsolated = imfill(irisIsolated,'holes');
            %set irisLabeled to label all contiguous blobs in pupilIsolated
            irisIsolated = rgb2gray(irisIsolated);
            irisLabeled = bwlabel(irisIsolated);
            %calculate area, centroid, and eccentricity for each block in
            %pupilIsolated
            stats = regionprops(irisIsolated, 'Area','Centroid','Eccentricity');
            %set irisArea to the size of the largest blob in irisIsolated. set
            %irisLabel to the label number of the largest blob in irisIsolated.
            [irisArea, irisLabel] = max([stats.Area]);
            %set centroid to that of largest blob in irisIsolated.
            centroid = round(stats(irisLabel).Centroid);
            %set eccentricity to that of largest blob in irisIsolated.
            eccentricity = stats(irisLabel).Eccentricity;
            %blob must have low eccentricity (i.e. approximate a circle) and have a
            %minimum number of pixels to be considered the iris.
            %if eccentricity < eccentricityThreshold &  irisArea > irisSizeThreshold
            if irisArea > irisSizeThreshold && irisArea < 500000
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
                        %If the pupil has exceeded the movement threshold, set
                        %pupilIsolated to black.
                    else
                        irisIsolated = [];
                        fprintf('Centroid moved too much\n')
                        out = 0;
                        continue
                    end
                else
                    %If the previous centroid value was [0 0] (i.e. has not been
                    %established yet), this frame is not counted as a blink frame.
                    irisIsolated  = (irisLabeled == irisLabel);
                    centroidPrev = centroid;
                end
            else
                irisIsolated = [];
                fprintf('Iris not found\n')
                out = 0;
                continue
            end
            subplot(1,3,1)
            imshow(irisIsolated);
            subplot(1,3,2)
            imshow(rgb2gray(eye))
            pause(.5);
            subplot(1,3,3)
            fuse = imfuse(rgb2gray(eye),irisIsolated);
            imshow(fuse)
            colormap gray
        end
    end
    
    if out == 1
        fprintf('Partial Blink\n')
        c{fileNo, 2} = 'Partial';
        toc
    end
    if out == 0
        fprintf('Full Blink\n')
        c{fileNo, 2} = 'Full';
        toc
    end
end    

T = cell2table(c,'VariableNames',{'File_Name','Partial_or_Full'});
writetable(T,'Blinks.csv')