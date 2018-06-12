 
%% Download video 
tic
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\SampleVideos'
clip = VideoReader('V0000000006_RAW_Blink3.avi');
%eye = imread('missedblink3.PNG');
%figure(1)
% imshow(eye)
% eye = rgb2gray(eye);
% eye = imadjust(eye);
% figure(2)
%imshow(eye)
cd 'C:\Users\dnacharaju\Documents\GitKraken\blink\Blink'
oldcenter = [];
%PupilOverlay(eye,1,oldcenter)
Switch = 0;
figure(1)
newmask =[];
while hasFrame(clip)
    video = readFrame(clip);
 
    video = imgaussfilt(video,2);
 
    image(video);

    pause(1/clip.FrameRate);
    mask = newmask;
    [out,centers,radii,newmask] = PupilOverlay(video,1,oldcenter);
    oldcenter = centers;
    h = viscircles(centers,radii);
    pause(0.5);
    if out == 0 && Switch == 0
 % Apply Masks
 %mask = rgb2gray(mask);
 videomask = rgb2gray(video);
 %videomask = video;
 videomask(mask==0)=0;
 figure(1)
 clf
 mask = rgb2gray(mask);
 imagesc(mask)
 figure(2)
 clf
 imagesc(videomask)
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