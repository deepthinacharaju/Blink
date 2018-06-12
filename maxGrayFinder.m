function [maxGray,maxGrayFrame] = maxGrayFinder(clip)

filepath = 'C:\Users\esimons\Documents\MATLAB\Test';
fileList = dir([filepath,'\*.avi']);

meanGrayLevels = [];
while hasFrame(clip)
    video = readFrame(clip);
    video = imgaussfilt(video,2);
    meanGrayLevels = [meanGrayLevels; mean(video(:))];
end
[maxGray, maxGrayFrame] = max(meanGrayLevels);