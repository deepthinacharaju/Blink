clf; clear all;

filepath = 'C:\Users\esimons\Documents\MATLAB\Test'; % change to actual location

%GenerateBlinkVideos(filepath); %generates videos for each blink

fileList = dir([filepath,'\*.avi']);

c = cell(numel(fileList),2);
Full = 0;
Partial = 0;
oldcenter = [];

for fileNo = 1:size(fileList,1);
    if ~strcmp(fileList(fileNo).name(end-6:end),'RAW.avi') %allows original file to be skipped
        c{fileNo, 1} = fileList(fileNo).name;
        tic
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        Switch = 0;
        fprintf(fileList(fileNo).name)
        fprintf('\n')
        
        while hasFrame(clip) && Switch == 0
            video = readFrame(clip);
            video = imgaussfilt(video,2);
            image(video);
            [out,centers,radii] = PupilOverlay(video,0,oldcenter);
            oldcenter = centers;
            h = viscircles(centers,radii);
            
            if out == 0
                fprintf('Full Blink \n')
                Switch = 1;
                toc
                Full = Full + 1;
            end
        end
        
        if Switch == 0
            fprintf('Partial Blink \n')
            Partial = Partial + 1;
            toc
        end
        
        if Switch == 0
            c{fileNo, 2} = 'Partial'; %full or partial
        else
            c{fileNo, 2} = 'Full';
        end
    end
end
    
T = cell2table(c,'VariableNames',{'File_Name','Partial_or_Full'});
writetable(T,'Blinks.csv')