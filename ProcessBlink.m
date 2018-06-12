 
%% Download video 
 
tic
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\SampleVideos'
clip = VideoReader('V0000000006_RAW_Blink11.avi');
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\Blink'
Switch = 0;
 
while hasFrame(clip)
 
    video = readFrame(clip);
 
    video = imgaussfilt(video,2);
 
    image(video);

    pause(1/clip.FrameRate);
 
    [out,centers,radii] = PupilOverlay(video,0);
    h = viscircles(centers,radii);
    pause(.5);
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