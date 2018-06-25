function [blinkFrameList,firstframe] = AltGenerateBlinkVideos(filepath)
% Uses AltBlinkDetect.m to generate individual videos for each blink

fileList = dir([filepath,'\*RAW.avi']);

for fileNo = 1:size(fileList,1);
    disp(fileList(fileNo).name);
    obj = VideoReader([filepath,'\',fileList(fileNo).name]);

%% Determine Start Frame
meanGray =[];
frames = 0;
hold on
while hasFrame(obj)
    video = readFrame(obj);
    video=rgb2gray(video);
    newmean = mean(video(:));
    meanGray = [meanGray; newmean];
    frames = frames + 1;
end
%         figure(2)
%                 plot(1:1:frames,meanGray)
%                 %pause(1)
%                 title('Mean Gray Values')
%                 xlabel('Frame Number')
%                 ylabel('Gray')
% Locate first frame with open eye
begin =0;
framefind = 1;
allmeanGray=meanGray;
meanofall= mean(allmeanGray(:));

while begin == 0
    % prevents videos that start with eyes closed from counting as a blink
    if allmeanGray(framefind) < ((max(allmeanGray)-min(allmeanGray))*.3 + min(allmeanGray))
        firstframe = framefind;
        begin = 1;
    end
    if framefind > 20
        if allmeanGray(framefind) < ((max(allmeanGray)-min(allmeanGray))*.45 + min(allmeanGray))
            firstframe = framefind;
            begin = 1;
        end
    end
    if framefind > numel(meanGray)
        fprintf('Cant locate start frame\n')
        return
    end
    framefind = framefind + 1;
end
%% Writes video
    obj = VideoReader([filepath,'\',fileList(fileNo).name]);
    mov = read(obj);
    if size(mov,3) > 1
        mov = mov(:,:,1,:);
    end
    [blinkFrameList,startFrame,endFrame] = AltBlinkDetect(obj,firstframe,meanofall);
    blinkNo = 1;

    for k=1:numel(startFrame)
        blinkMov = mov(:,:,:,startFrame(k):endFrame(k));
        blinkVideo = VideoWriter([filepath,'\',fileList(fileNo).name(1:end-4),'_Blink',num2str(blinkNo),'.avi'], 'Uncompressed AVI');
        blinkVideo.FrameRate = 2;
        open(blinkVideo)
        writeVideo(blinkVideo, blinkMov);
        close(blinkVideo);
        blinkNo = blinkNo + 1;          
    end
end
end
                