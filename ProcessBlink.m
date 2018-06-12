 
%% Download video 
 
tic
 
Clip = 'blink419.avi';
 
clip = VideoReader(Clip);
 
Switch = 0;
 
while hasFrame(clip)
 
    video = readFrame(clip);
 
    video = imgaussfilt(video,2);
 
    image(video);
 
    pause(1/clip.FrameRate);
 
    [out] = PupilOverlay(video,0);
 
    if out == 0 && Switch == 0
 
        fprintf('Full Blink \n')
 
        Switch = 1;
 
        toc
 
        return
 
    end
 
end
 
if Switch == 0
 
    fprintf('Partial Blink \n')
 
    toc
 
end