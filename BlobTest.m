% Uses IrisDetector.m and AltGenerateBlinkVideos.m to determine full and
% partial blinks and print them to a CSV file

clf; clear all; close all;

start = tic;

% generates blink videos from an entire patient video
%filepath = 'C:\Users\esimons\Dropbox (Blur PD)\sam_partial_blinks\NEWPARTIALBLINK'; % change to actual location
filepath = 'C:\Users\esimons\Documents\MATLAB\Test';

%[blinkFrameList,firstframe,allmeanGray] = AltGenerateBlinkVideos(filepath); %generates videos for each blink

fileList = dir([filepath,'\*.avi']);

c = cell(numel(fileList),2);
out = [];
begin = 0;
allmeanGray = [];

% run loop for every file (blink video) in filepath
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
            allmeanGray = [allmeanGray; mean(eye(:))];
        end
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        % figure(1)
        %figure(2)
        counter =1;
        while hasFrame(clip)
            eye = readFrame(clip);
            saturation = 10;
            eye = rgb2gray(eye).^(exp(-0.1*saturation));
            meanGray = mean(eye(:));
            % only want to analyze frame with max gray level (fullest
            % blink)
            if meanGray == max(allmeanGray(:))
                eye = imsharpen(eye);
                saturation = 10;
                eye = adapthisteq(eye,'clipLimit',0.02,'Distribution','rayleigh');
                eye = imgaussfilt(eye,.9);
                [out,irisIsolated,irisArea,centroid,avgPixelx,avgPixely,pixelList] = IrisDetector(eye);
                %             video = adapthisteq(eye,'clipLimit',0.02,'Distribution','rayleigh');
                %             [out2,centers,radii,mask,eye2] = PupilOverlay(video,0,oldcenter);
                %                 if out == 0
                %                     fprintf('what is happening')
                %                     break
                if out == 1
%                     eye = imcrop(eye,[400 150 950 500]);
                    figure(1)
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
                    
%                     subplot(2,2,4)
%                     imshow(BW);
%                     title(fileList(fileNo).name)
                    colormap gray
                    set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
                end
                
            end
        end
        if out == 0
            fprintf('Full Blink\n')
            c{fileNo, 3} = 'Full';
            toc
        end
        if out == 1
            fprintf('Partial Blink\n')
            c{fileNo, 3} = 'Partial';
            toc
        end
        
    end
    % want space between each batch of blink videos in CSV file
    index = strfind(filepath,'Blink9');
    if ~isempty(index)
        c{fileNo+1,1} = ' ';
    end
end

% writes data to CSV file "Blinks.csv"
T = cell2table(c,'VariableNames',{'File_Name','Blink_Type','MATLAB_Outcome'});
writetable(T,'Blinks.csv')
elapsed = toc(start);
fprintf('Total elapsed time is %f seconds.\n',elapsed);