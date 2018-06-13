 
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
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\SampleVideos'
clip = VideoReader('V0000000006_RAW_Blink6.avi');
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\Blink'
Switch = 0;
figure(1)
oldcenter = [];
while hasFrame(clip)
    video = readFrame(clip);
    video=rgb2gray(video);
    video = imgaussfilt(video,2);
    video = adapthisteq(video,'clipLimit',0.02,'Distribution','rayleigh'); 

    imshow(video);

    pause(1/clip.FrameRate);
 
    [out,centers,radii] = PupilOverlay(video,0,oldcenter);
    oldcenter = centers;
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