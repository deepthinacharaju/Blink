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
out3 = 5;
begin = 0;
alleyesum = [];
% run loop for every file (blink video) in filepath
for fileNo = 1:size(fileList,1);
    allmeanGray = [];
    if ~strcmp(fileList(fileNo).name(end-6:end),'RAW.avi') %allows original file to be skipped
        tic
        c{fileNo, 1} = fileList(fileNo).name;
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        fprintf(fileList(fileNo).name)
        fprintf('\n')
        numframe = 0;
        while hasFrame(clip)
            eye = readFrame(clip);
            eye = rgb2gray(eye);
            allmeanGray = [allmeanGray; mean(eye(:))];
            numframe = numframe + 1;
            
        end
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        
        counter = 1;
        while hasFrame(clip)
            eye = readFrame(clip);
            saturation = 10;
            eye1 = rgb2gray(eye);
            meanGray = mean(eye1(:));
            %se = strel('line',15,175);
            se = strel('disk',10);
            eye1 = imopen(eye1,se);
%             imshow(eye1)
%             pause()
            % only want to analyze frame with max gray level (fullest
            % blink)
            if meanGray == max(allmeanGray(:))
                eye1 = imsharpen(eye1);
                saturation = 10;
                eye1 = adapthisteq(eye1,'clipLimit',0.015,'Distribution','rayleigh');
                %eye1 = imgaussfilt(eye1,.9);
                figure(20)
                h_im = imshow(eye1);
                e = imellipse(gca,[250 150 1250 650]);
                BW = createMask(e,h_im);
                eye1(BW==0)=150;
                set(gcf,'Visible','off');
                [out,irisLabeled,totalArea,totalXCentroid] = IrisDetector(eye1);
                binaryThresh = .185-mean(allmeanGray)/1000;
                eye = im2bw(eye1,binaryThresh);
                eyesum = 832*1664 - sum(eye(:));
                %alleyesum = [alleyesum; eyesum];
                fprintf('%Number of Black Pixels: d\n',eyesum);
                if eyesum >= 500 %(max(alleyesum)-3*mean(alleyesum))
                    out2 = 1;
                    fprintf('Binary: Partial\n');
                else
                    out2 = 0;
                    fprintf('Binary: Full\n');
                end
                counter = counter + 1;
                %eye = imsharpen(eye);
                saturation = 10;
                %eye = adapthisteq(eye,'clipLimit',0.02,'Distribution','rayleigh');
                %eye = imgaussfilt(eye,.9);
                
                %                     [out,irisIsolated,irisArea,centroid,avgPixelx,avgPixely,pixelList] = IrisDetector(eye);
                %             video = adapthisteq(eye,'clipLimit',0.02,'Distribution','rayleigh');
                %             [out2,centers,radii,mask,eye2] = PupilOverlay(video,0,oldcenter);
                %                 if out == 0
                %                     fprintf('what is happening')
                %                     break
                
                if out == 1 || out2 == 1
                    %                     eye = imcrop(eye,[400 150 950 500]);
                    figure()
                    RI = imref2d(size(irisLabeled));
                    subplot(2,2,1)
                    imshow(eye1,RI)
                    title(fileList(fileNo).name)
                    subplot(2,2,2)
                    RI = imref2d(size(eye));
                    imshow(eye,RI);
                    subplot(2,2,3)
                    imshow(irisLabeled,RI);
                    
                    %                         subplot(2,2,1)
                    %                         imshow(irisIsolated);
                    %                         hold on
                    %                         scatter(centroid(1),centroid(2),'r');
                    %                         scatter(avgPixelx,avgPixely,'y');
                    %                         hold off
                    
                    %                         subplot(2,2,2)
                    %                         imshow(eye);
                    
                    %                         subplot(2,2,3)
                    %                         fuse = imfuse(eye,irisIsolated);
                    %                         imshow(fuse,RI);
                    
                    %                         subplot(2,2,4)
                    %                         imshow(bw)
                    
                    %                     subplot(2,2,4)
                    %                     imshow(BW);
                    %                     title(fileList(fileNo).name)
                    colormap gray
                    set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
                end
            end
            if meanGray >= max(allmeanGray(:))-0.01*max(allmeanGray(:)) && ...
                    meanGray <= max(allmeanGray(:))+0.01*max(allmeanGray(:)) && ...
                    meanGray ~= max(allmeanGray(:))
                eye1 = imsharpen(eye1);
                saturation = 10;
                eye1 = adapthisteq(eye1,'clipLimit',0.015,'Distribution','rayleigh');
                eye1 = imgaussfilt(eye1,.9);
                figure(20)
                h_im = imshow(eye1);
                e = imellipse(gca,[250 150 1250 650]);
                BW = createMask(e,h_im);
                eye1(BW==0)=150;
                set(gcf,'Visible','off');
                [out3,irisLabeled,totalArea,totalXCentroid] = IrisDetector(eye1);
%                     if out3 == 1
%                         figure()
%                         RI = imref2d(size(irisLabeled));
%                         subplot(2,2,1)
%                         imshow(eye1,RI)
%                         title(fileList(fileNo).name)
%                         subplot(2,2,2)
%                         RI = imref2d(size(eye));
%                         imshow(eye,RI);
%                         subplot(2,2,3)
%                         imshow(irisLabeled,RI);
%                         colormap gray
%                         set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
%                     end
            end
        end
        if (out == 1) && (out3 == 1)
            fprintf('Partial Blink\n')
            c{fileNo, 3} = 'Partial';
            toc
        else
            fprintf('Full Blink\n')
            fprintf('Max Frame: %d\n',out);
            if isempty(out3) == false
                fprintf('Other Frame: %d\n',out3);
            end
            c{fileNo, 3} = 'Full';
            toc
        end
        fprintf('\n')
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