function [out,centers,radii,mask,eye2] = PupilOverlay(eye,plot,oldcenter)
out = 1;
%eye = rgb2gray(eye);
%eye = adapthisteq(eye,'clipLimit',0.02,'Distribution','rayleigh'); 
eye2 = eye;
mask = eye2;
counter = 0;
centers = [];
radii = [];
centerThresh = 250;
 
if plot ==1
    figure()
    clf
    subplot(1,3,1)
    imshow(eye)
    subplot(1,3,2)
    imshow(eye)
end
 
%tic
[allcenters1,allradii1] = imfindcircles(eye,[160, 235],'ObjectPolarity','dark',...
    'Sensitivity',0.95,'EdgeThreshold',0.05,'Method','twostage');
[allcenters2,allradii2] = imfindcircles(eye,[235, 310],'ObjectPolarity','dark',...
    'Sensitivity',0.95,'EdgeThreshold',0.05,'Method','twostage');
allcenters = vertcat(allcenters1,allcenters2);
allradii = vertcat(allradii1,allradii2);
%toc
%whos allcenters

if numel(oldcenter)>0
    for k = 1:1:size(allcenters,1)
        if sqrt((allcenters(k,1)-oldcenter(1)).^2 + (allcenters(k,2)-oldcenter(2)).^2) < 75
           centers = [centers; allcenters(k,1), allcenters(k,2)];
           radii = [radii; allradii(k)];
           fprintf('Center within Range\n')
        end
    end
else
     centers = allcenters;
     radii = allradii;
end

if numel(centers) >= 2
    for k = 1:size(centers(:,1))
        if centers(k,1) < 832+centerThresh && centers(k,1) > 832-centerThresh %...
%                && centers(k,2) <= (832-200)
           continue
        else
            centers(k,:) = [0];
            fprintf('Omitted Off-Center Circle\n')
        end
    end
end

while numel(centers) > 2 && counter < 5
    [centers1,radii1] = imfindcircles(eye,[160, 235],'ObjectPolarity','dark',...
        'Sensitivity',0.95-(counter+1)*0.01,'EdgeThreshold',0.05,'Method','twostage');
    [centers2,radii2] = imfindcircles(eye,[235, 310],'ObjectPolarity','dark',...
        'Sensitivity',0.95-(counter+1)*0.01,'EdgeThreshold',0.05,'Method','twostage');
    centers = vertcat(centers1,centers2);
    radii = vertcat(radii1,radii2);
    counter = counter + 1;
    fprintf('counter = %d\n',counter)
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
    eye(ceil(centerX-hsize(1)./2):ceil(centerX+hsize(1)./2)-1,ceil(centerY-hsize(2)./2):ceil(centerY+hsize(2)./2)-1) = h;
    subplot(1,3,3)
    eye2(eye==255)= 255;
    imshow(eye2)
    axis tight
    colormap gray
    figure()
    mask(eye~=255)=0;
    %mask = rgb2gray(mask);
    imshow(mask)
end
 
end