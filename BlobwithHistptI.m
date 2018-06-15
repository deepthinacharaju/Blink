
%% Download Image
close all
clear all
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\SampleVideos'
eye = imread('missedblink2.PNG');
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\Blink'
figure(1)
imshow(eye)
oldcenter =[];
PupilOverlay(eye,1,oldcenter)
%% Download video
clear all
close all
fprintf('Begin:\n')
tic
filepath = 'C:\Users\dnacharaju\Documents\GitKraken\blink\SampleVideos\TestFolder'; % change to actual location
%GenerateBlinkVideos(filepath); %generates videos for each blink
fileList = dir([filepath,'\*.avi']);
c = cell(numel(fileList),2);
for fileNo = 1:size(fileList,1)
    if ~strcmp(fileList(fileNo).name(end-6:end),'RAW.avi') %allows original file to be skipped
        c{fileNo, 1} = fileList(fileNo).name;
        tic
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        Switch = 0;
        fprintf(fileList(fileNo).name)
        fprintf('\n')
        figure(1)
        oldcenter = [];
        meanGray =[];
        frames = 0;
        hold on
        while hasFrame(clip)
            video = readFrame(clip);
            video=rgb2gray(video);
            newmean = mean(video(:));
            meanGray = [meanGray; newmean];
            frames = frames + 1;
        end
        plot(1:1:frames,meanGray)
        title('Mean Gray Values')
        xlabel('Frame Number')
        ylabel('Gray')
        % Locate first frame with open eye
        begin =0;
        framefind = 1;
        while begin == 0
            if meanGray(framefind) < ((max(meanGray)-min(meanGray))*.25+min(meanGray))
                startframe = framefind;
                begin = 1;
                line([startframe startframe],[min(meanGray) max(meanGray)+.1*max(meanGray)])
                axis tight
            end
            framefind = framefind + 1;
            if framefind > numel(meanGray)
                fprintf('Cant locate start frame\n')
                return
            end
        end
        % Determine if open or closed
        clip2 = VideoReader([filepath,'\',fileList(fileNo).name]);
        figure(2)
        counter =0;
        centroidPrev = [0, 0];
        while hasFrame(clip2)
            video = readFrame(clip2);
            counter = counter + 1;
            if counter < startframe
                continue
            else
                if meanGray(counter) == max(meanGray)

                end
            end
            
        end
    end
end
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\SampleVideos\TestFolder'
T = cell2table(c,'VariableNames',{'File_Name','Partial_or_Full','Method','Overlap'});
writetable(T,'Blinks.csv')