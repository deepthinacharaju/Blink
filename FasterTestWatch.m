clf;
fontSize = 14;

filepath = 'C:\Users\esimons\Documents\MATLAB\Test'; % change to actual location
vidObject = VideoReader('V0000000019_RAW.avi');           %load video
numberOfFrames = vidObject.NumberOfFrames;                %number of frames
vidHeight = vidObject.Height;                             %dimensions of video (832x1664)
vidWidth = vidObject.Width;
numberOfFramesWritten = 0;
figure(1)
meanGrayLevels = zeros(numberOfFrames, 1);
    
for frame = 1 : numberOfFrames
    % Extract the frame from the movie structure.
  thisFrame = read(vidObject, frame);
    
    % Display it
   hImage = subplot(2, 1, 1);
  image(thisFrame);
  caption = sprintf('Frame %4d of %d.', frame, numberOfFrames);
  title(caption, 'FontSize', fontSize);
   drawnow;
    
    % Calculate the mean gray level.
    thisFrame =rgb2gray(thisFrame);
    meanGrayLevels(frame) = mean(thisFrame(:));
    
     % Plot the mean gray levels.
    hPlot = subplot(2,1,2);
    plot(meanGrayLevels, 'k-', 'LineWidth', 2);
    grid on;
    
    % Put title back because plot() erases the existing title.
    title('Mean Gray Levels', 'FontSize', fontSize);
    if frame == 1
        xlabel('Frame Number');
        ylabel('Gray Level');
        % Get size data later for preallocation if we read
        % the movie back in from disk.
        [rows, columns, numberOfColorChannels] = size(thisFrame);
    end
    
   numberOfFramesWritten = numberOfFramesWritten + 1;
   pause
 end

[peaksTotal,locsTotal,pTotal] = findpeaks(meanGrayLevels,'MinPeakHeight',...
    min(meanGrayLevels)+3,'MinPeakDistance',4,'MinPeakProminence',3);
totalBlinks = numel(peaksTotal);
[peaksFullBlink,locsFull,pFull] = findpeaks(meanGrayLevels,'MinPeakHeight',...
    max(peaksTotal)-(max(peaksTotal)- mean(meanGrayLevels))/2,'MinPeakDistance',4,...
    'MinPeakProminence',3);
fullBlinks = numel(peaksFullBlink);
partialBlinks = totalBlinks - fullBlinks;