function [blinkFrameList,startFrame,endFrame] = AltBlinkDetect(obj,firstframe,meanofall)
% Reads each frame of a video and determines where the blinks occur using
% mean gray levels

clf;
fontSize = 14;
frameBuffer = 10;
numberOfFrames = obj.NumberOfFrames;            
numberOfFramesWritten = 0;
% figure(1)
meanGrayLevels = zeros(numberOfFrames, 1);

%% Find mean gray levels of each frame
for frame = 1 : numberOfFrames
    % Extract the frame from the movie structure.
    thisFrame = read(obj, frame);
    if frame < firstframe
    meanGrayLevels(frame) = meanofall;

    else
    % Display it
    %  	hImage = subplot(2, 1, 1);
    % 	image(thisFrame);
    % 	caption = sprintf('Frame %4d of %d.', frame, numberOfFrames);
    % 	title(caption, 'FontSize', fontSize);
    %     [rows, columns, numberOfColorChannels] = size(thisFrame);
    %  	drawnow;
    
    % Calculate the mean gray level.
    thisFrame =rgb2gray(thisFrame);
    meanGrayLevels(frame) = mean(thisFrame(:));
    
    % Plot the mean gray levels.
    %     hPlot = subplot(2,1,2);
    %     plot(meanGrayLevels, 'k-', 'LineWidth', 2);
    %     grid on;
    
    % Put title back because plot() erases the existing title.
    %     title('Mean Gray Levels', 'FontSize', fontSize);
    %     if frame == 1
    %         xlabel('Frame Number');
    %         ylabel('Gray Level');
    %         % Get size data later for preallocation if we read
    %         % the movie back in from disk.
    %         [rows, columns, numberOfColorChannels] = size(thisFrame);
    %     end
    
    numberOfFramesWritten = numberOfFramesWritten + 1;
    end
end

%%

[peaksTotal,locsTotal] = findpeaks(meanGrayLevels,'MinPeakHeight',...
    min(meanGrayLevels)+.25*(max(meanGrayLevels)-min(meanGrayLevels)),'MinPeakDistance',4,'MinPeakProminence',3);

blinkFrameList = zeros(numel(meanGrayLevels),1);
holdFrame = [];
startFrame = [];
endFrame = [];
figure(1)
title('Mean Gray Levels', 'FontSize', fontSize);
plot(meanGrayLevels, 'k-', 'LineWidth', 2);
hold on
for frame = 1 : numberOfFrames
    thisFrame = read(obj, frame);
    for k=1:1:numel(peaksTotal)
        if meanGrayLevels(frame) == peaksTotal(k) 
            %blinkFrameList stores frame with peak gray level (blink)
            blinkFrameList(frame) = true;
            holdFrame = [holdFrame;frame];
            %fprintf('Peak at frame %d\n',frame);
            line([frame, frame],[min(meanGrayLevels), max(meanGrayLevels)]);
            %blink video contains a few frames before and after blink
            startFrame = [startFrame;frame - frameBuffer]; 
            endFrame = [endFrame;frame + frameBuffer];
            if k~=1
                % if two blinks are close to each other, don't want videos
                % to capture two blinks
                if startFrame(k) < endFrame(k-1)
                    startFrame(k) = round((endFrame(k-1)-frameBuffer)+(frame - (endFrame(k-1)-frameBuffer))/2);
                    endFrame(k-1) = startFrame(k);
                end
            end
        end
    end
    startFrame(startFrame<1)=1; %can't have frame less than frame one
    endFrame(endFrame>numel(blinkFrameList))=numel(blinkFrameList); %can't have frame number higher than total frames
    hold off
    grid on;
    xlabel('Frame Number');
    ylabel('Gray Level');
end

end

