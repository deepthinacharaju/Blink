clf;
fontSize = 14;

vidObject = VideoReader('V0000000031_RAW.avi');           %load video
numberOfFrames = vidObject.NumberOfFrames;                %number of frames
vidHeight = vidObject.Height;                             %dimensions of video (832x1664)
vidWidth = vidObject.Width;
numberOfFramesWritten = 0;
figure(1)

meanGrayLevels = zeros(numberOfFrames, 1);

for frame = 1 : numberOfFrames
    % Extract the frame from the movie structure.
	thisFrame = read(vidObject, frame);    
    
    % Calculate the mean gray level.
    grayImage = rgb2gray(thisFrame);
    meanGrayLevels(frame) = mean(grayImage(:));
end

plot(meanGrayLevels, 'k-', 'LineWidth', 2);
grid on;
title('Mean Gray Levels', 'FontSize', fontSize);

[peaksTotal,locsTotal,pTotal] = findpeaks(meanGrayLevels,'MinPeakHeight',...
    min(meanGrayLevels)+3,'MinPeakDistance',4,'MinPeakProminence',3);
totalBlinks = numel(peaksTotal);
[peaksFullBlink,locsFull,pFull] = findpeaks(meanGrayLevels,'MinPeakHeight',...
    max(peaksTotal)-(max(peaksTotal)- mean(meanGrayLevels))/2,'MinPeakDistance',4,...
    'MinPeakProminence',3);
fullBlinks = numel(peaksFullBlink);
partialBlinks = totalBlinks - fullBlinks;