 
%% Download video 
tic
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\SampleVideos'
%cd 'C:\Users\esimons\Documents\MATLAB\Test'
clip = VideoReader('V0000000006_RAW_Blink6.avi');
%eye = imread('missedblink2.PNG');
%figure(1)
% imshow(eye)
% eye = rgb2gray(eye);
% eye = imadjust(eye);
% figure(2)
%imshow(eye)
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\Blink'
%cd 'C:\Users\esimons\Documents\MATLAB\Blink-Classifier2\Blink'
%PupilOverlay(eye,1)
Switch = 0;
figure(1)
oldcenter = [];
while hasFrame(clip)
 close all
    video = readFrame(clip);
 
    video = imgaussfilt(video,2);
 
    image(video);

    %pause(1/clip.FrameRate);
 
    [out,centers,radii,mask] = PupilOverlay(video,0,oldcenter);
    oldcenter = centers;
    h = viscircles(centers,radii);
    %pause(0.5)
    
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