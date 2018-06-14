function GenerateBlinkVideos(filepath)

fileList = dir([filepath,'\*RAW.avi']);

for fileNo = 1:size(fileList,1);
    disp(fileList(fileNo).name);
    obj = VideoReader([filepath,'\',fileList(fileNo).name]);
    mov = read(obj);
    if size(mov,3) > 1
        mov = mov(:,:,1,:);
    end
    
    blinkFrameList = AltBlinkDetect(mov);
    blinkNo = 1;
    endFrame = 0;
    if sum(blinkFrameList > 0)
        blinkFound = 1;
        while blinkFound
            startFrame = find(blinkFrameList(endFrame + 1:end),1,'first') + endFrame;
            if isempty(startFrame)
                blinkFound = 0;
            else
                endFrame = find(~blinkFrameList(startFrame + 1:end),1,'first') + startFrame - 1;
                if isempty(endFrame)
                    endFrame = size(blinkFrameList,1);
                end
                blinkMov = mov(:,:,:,startFrame:endFrame);
                blinkVideo = VideoWriter([filepath,'\',fileList(fileNo).name(1:end-4),'_Blink',num2str(blinkNo),'.avi'], 'Uncompressed AVI');
                blinkVideo.FrameRate = 2;
                open(blinkVideo)
                writeVideo(blinkVideo, blinkMov);
                close(blinkVideo);
                blinkNo = blinkNo + 1;
                if endFrame == size(blinkFrameList,1)
                    blinkFound = 0;
                end
            end
        end
    end
end
                