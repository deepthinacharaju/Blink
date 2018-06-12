function [maxGray,maxGrayFrame] = maxGrayFinder(vidObj)

filepath = 'C:\Users\esimons\Documents\MATLAB\Test';
fileList = dir([filepath,'\*.avi']);

meanGrayLevels = [];
while hasFrame(vidObj)
    video = readFrame(vidObj);
    video = imgaussfilt(video,2);
    meanGrayLevels = [meanGrayLevels; mean(video(:))];
end
[maxGray, maxGrayFrame] = max(meanGrayLevels);