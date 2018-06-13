function [out,centers,radii,mask] = PupilOverlaywithGray(eye,plot)
out = 1;
centers = [];
radii = [];
counter = 0;
centerThresh = 250;

eye2 = eye;
mask = eye2;

if plot == 1
     figure()
     clf
     subplot(1,3,1)
     imshow(eye)
     subplot(1,3,2)
     imshow(eye)
end

[centers,radii]=imfindcircles(eye,[200, 300],'ObjectPolarity','dark','Sensitivity',0.96,'EdgeThreshold',0.05,'Method','twostage');

if numel(centers) >= 2
    for k = 1:size(centers(:,1))
        if centers(k,1) > 832+centerThresh || centers(k,1) < 832+centerThresh
           centers(k,:) = [0];
        else
            continue
        end
    end
end

while numel(centers) > 2 && counter < 5
    [centers,radii]=imfindcircles(eye,[200, 300],'ObjectPolarity','dark','Sensitivity',0.95-counter*0.01,'EdgeThreshold',0.05,'Method','twostage');
    counter = counter + 1;
end

if counter > 4
    fprintf('Number of Circles Error\n')
    out = 0;
    return
end

if numel(centers) < 2
    fprintf('No Visible Iris\n')
    out = 0;
    return
end


%%
 
if plot == 1
    figure()
    clf
    subplot(1,3,1)
    imshow(eye)
    subplot(1,3,2)
    imshow(eye)
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
    mask(eye~=255)=0;
    mask = rgb2gray(mask);
    imshow(mask)

end
end