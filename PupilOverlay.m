function [out] = PupilOverlay(eye,plot)
out = 1;
%eye =rgb2gray(eye);
eye2=eye;
eye3 = eye2;
if plot ==1
    figure()
    clf
    subplot(1,3,1)
    imshow(eye)
    subplot(1,3,2)
    imshow(eye)
end
%tic
[centers,radii]=imfindcircles(eye,[130, 175],'ObjectPolarity','dark','Sensitivity',0.96,'EdgeThreshold',0.05,'Method','twostage');
%toc
if size(radii) == [0 0]
    fprintf('No Visible Pupil \n')
    out = 0;
    return
end
%%
if plot == 1
    h = viscircles(centers,radii);
    imagesizex = size(eye,1);
    imagesizey = size(eye,2);
    [colImage, rowImage] = meshgrid(1:imagesizex,1:imagesizey);
    circlepixels = zeros(size(eye));
    z = circlepixels;
    centerY = ceil(centers(1));
    centerX = ceil(centers(2));
    ind = sub2ind(size(eye),centerX,centerY);
    radius = radii(1);
    circlepixels((rowImage- centerY).^2 + (colImage-centerX).^2 <= radius^2) =1;
    %% 
    h = fspecial('disk',radius);
    thresh = 10000000;
    h(h~=0) = thresh;
    hsize = size(h);
    eye(ceil(centerX-hsize(1)./2):ceil(centerX+hsize(1)./2)-1,ceil(centerY-hsize(2)./2):ceil(centerY+hsize(2)./2)-1)= h;
    subplot(1,3,3)
    eye2(eye==255)= 255;
    imshow(eye2)
    axis tight
    colormap gray
    figure()
    eye3(eye~=255)=0;
    imshow(eye3)
end
end