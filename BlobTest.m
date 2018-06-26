% Uses initialIris.m, IrisDetector.m and AltGenerateBlinkVideos.m to 
% determine full and partial blinks and print them to a CSV file

clear all; close all;
debug = true;
writeVideos = false;

start = tic;

%filepath = 'C:\Users\esimons\Dropbox (Blur PD)\sam_partial_blinks\NEWPARTIALBLINK'; % change to correct location
filepath = 'C:\Users\esimons\Documents\MATLAB\Test';

% generates blink videos from an entire patient video
if writeVideos == true
    AltGenerateBlinkVideos(filepath); %generates videos for each blink
end

fileList = dir([filepath,'\*.avi']);
c = cell(numel(fileList),2);
out = 2;
out3 = 2;

% run loop for every file (blink video) in filepath
for fileNo = 1:size(fileList,1);
    allmeanGray = [];
    if ~strcmp(fileList(fileNo).name(end-6:end),'RAW.avi') %allows original file to be skipped
        %tic
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
            
        [eyeOpenRow,eyeOpenCol] = find(allmeanGray(:) == min(allmeanGray(:)),1);
        eyeOpenValue = allmeanGray(eyeOpenRow);
        
        counter = 1;       
        while hasFrame(clip)
            eye = readFrame(clip);
            saturation = 10;
            eye1 = rgb2gray(eye);
            meanGray = mean(eye1(:));
            se = strel('disk',10);
            eye1 = imopen(eye1,se);
            
            % Find iris when eye is open
            if meanGray == eyeOpenValue && counter == 1
                [initialEye,initialArea,initialXCentroid,initialYCentroid,equivDiaSq,initialMeanGL] = initialIris(eye1,fileList,fileNo);
                %fprintf('Initial Area: %f\n',initialArea);
                counter = counter + 1;
            end
        end
        
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        while hasFrame(clip)
            eye = readFrame(clip);
            eye1 = rgb2gray(eye);
            meanGray = mean(eye1(:));
%             figure(70)
%             imshow(eye1);
%             pause()

            % Look at fullest blink and determine if iris is in same place
            
            if meanGray == max(allmeanGray(:))
                eye1 = adapthisteq(eye1,'clipLimit',0.015,'Distribution','rayleigh');
                [out,irisLabeled,totalArea,totalXCentroid,totalYCentroid,newMeanGL] = ...
                    IrisDetector(eye1,initialXCentroid,initialYCentroid,equivDiaSq,initialMeanGL);
                fprintf(1,'Initial GL: %5.3f Final GL: %5.3f\n',initialMeanGL, newMeanGL);
                % if we find a full blink, we don't need to look any
                % further
                if out == 0
                    break
                end
                if debug == true
                    if out == 1
                        figure()
                        RI = imref2d(size(irisLabeled));
                        subplot(2,2,1)
                        imshow(eye1,RI)
                        title(fileList(fileNo).name)
                        subplot(2,2,2)
                        RI = imref2d(size(eye));
                        imshow(eye,RI);
                        title('Original Image - Max Gray Frame')
                        subplot(2,2,3)
                        imshow(irisLabeled,RI);
                        title('Blob(s) Found')
                        subplot(2,2,4)
                        fuse = imfuse(irisLabeled,eye1);
                        imshow(fuse,RI);                        
                        title('Blob(s) Overlayed on Edited Image')
                        colormap gray
                        set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
                    end
                end    
            end
        end
            
        % if another frame has a gray level close to max level, also
        % look at that frame and see if it has a full blink
        out3 = 2;
        altFrameCounter = 1;
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        while hasFrame(clip)
            eye = readFrame(clip);
            eye1 = rgb2gray(eye);
            meanGray = mean(eye1(:));
%             figure(70)
%             imshow(eye1);
%             pause()
            if meanGray >= max(allmeanGray(:))-0.025*max(allmeanGray(:)) && ...
                    meanGray ~= max(allmeanGray(:)) % previously 1%, now 2.5%
                fprintf('Found frame with comparable gray levels, frame %i\n',altFrameCounter);
                eye1 = adapthisteq(eye1,'clipLimit',0.015,'Distribution','rayleigh');
                [out3,irisLabeled,totalArea,totalXCentroid,totalYCentroid,newMeanGL] = ...
                    IrisDetector(eye1,initialXCentroid,initialYCentroid,equivDiaSq,initialMeanGL);
                fprintf(1,'Initial GL: %5.3f Final GL: %5.3f\n',initialMeanGL, newMeanGL);
                if debug == true
                    if out3 == 1
                        figure()
                        RI = imref2d(size(irisLabeled));
                        subplot(2,2,1)
                        imshow(eye1,RI)
                        title(fileList(fileNo).name)
                        subplot(2,2,2)
                        RI = imref2d(size(eye));
                        imshow(eye,RI);
                        title('Original Image - Non-Max Gray Frame')
                        subplot(2,2,3)
                        imshow(irisLabeled,RI);
                        title('Blob(s) Found')
                        subplot(2,2,4)
                        fuse = imfuse(irisLabeled,eye1);
                        imshow(fuse,RI);
                        title('Blob(s) Overlayed on Edited Image')
                        colormap gray
                        set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
                    end
                end
                % if we find a full blink in an additional high-gray level 
                % frame, then we can call it a full blink
                if out3 == 0
                    break
                end
                altFrameCounter = altFrameCounter + 1;
            end
        end
                
        % print outcome and read to CSV file
        if out == 0 || out3 == 0
            fprintf('Full Blink\n')
            if out3 == 0 && debug == true
                fprintf('Max Gray Frame: out = %d\n',out);
                fprintf('Other Frame: out = %d\n',out3);
            end
            c{fileNo, 3} = 'Full';
            %toc
        elseif out == 1
            fprintf('Partial Blink\n')
            c{fileNo, 3} = 'Partial';
            %toc
        else
            fprintf('Error\n')
            c{fileNo, 3} = 'Error';
            %toc
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
system('C:\Users\esimons\Documents\MATLAB\Blink-Classifier2\Blink\Blinks.csv');