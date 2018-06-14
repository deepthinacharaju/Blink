clf; clear all;

start = tic;

filepath = 'C:\Users\esimons\Documents\MATLAB\Test'; % change to actual location

%GenerateBlinkVideos(filepath); %generates videos for each blink

fileList = dir([filepath,'\*.avi']);

c = cell(numel(fileList),2);
out = [];
oldcenter = [];

for fileNo = 1:size(fileList,1);
    if ~strcmp(fileList(fileNo).name(end-6:end),'RAW.avi') %allows original file to be skipped
        tic
        c{fileNo, 1} = fileList(fileNo).name;
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        fprintf(fileList(fileNo).name)
        fprintf('\n')
        
        while hasFrame(clip)
            eye = readFrame(clip);
            eye = rgb2gray(eye);
            eye = imsharpen(eye);
            %eye = adapthisteq(eye,'clipLimit',0.005,'Distribution','rayleigh'); 
            [out,irisIsolated,irisArea,centroid,avgPixelx,avgPixely] = IrisDetector(eye);
%             video = adapthisteq(eye,'clipLimit',0.02,'Distribution','rayleigh'); 
%             [out2,centers,radii,mask,eye2] = PupilOverlay(video,0,oldcenter);
            if out == 0
                break
            else
                RI = imref2d(size(irisIsolated));
                subplot(2,2,1)
                imshow(irisIsolated);
                hold on
                scatter(centroid(1),centroid(2),'r');
                scatter(avgPixelx,avgPixely,'y');
                hold off
                subplot(2,2,2)
                imshow(eye);
                subplot(2,2,3)
                fuse = imfuse(eye,irisIsolated);
                imshow(fuse,RI);
%                 subplot(2,2,4)
%                 imshow(eye2);
                pause(.5)
                colormap gray
                set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
            end
        end
    end
    if out == 0
        fprintf('Full Blink\n')
        c{fileNo, 2} = 'Full';
        toc
    end
    if out == 1
        fprintf('Partial Blink\n')
        c{fileNo, 2} = 'Partial'; 
        toc
    end
end    

T = cell2table(c,'VariableNames',{'File_Name','Partial_or_Full'});
writetable(T,'Blinks.csv')
elapsed = toc(start);
fprintf('Total elapsed time is %f seconds.\n',elapsed);