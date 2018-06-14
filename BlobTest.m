clf; clear all; close all;

start = tic;

filepath = 'C:\Users\esimons\Documents\MATLAB\Test'; % change to actual location

AltGenerateBlinkVideos(filepath); %generates videos for each blink

fileList = dir([filepath,'\*.avi']);

c = cell(numel(fileList),2);
out = [];
oldcenter = [];

for fileNo = 1:size(fileList,1);
    if ~strcmp(fileList(fileNo).name(end-6:end),'RAW.avi') %allows original file to be skipped
        %pause()
        tic
        c{fileNo, 1} = fileList(fileNo).name;
        clip = VideoReader([filepath,'\',fileList(fileNo).name]);
        fprintf(fileList(fileNo).name)
        fprintf('\n')
        % figure(1)
        oldcenter = [];
        meanGray =[];
        frames = 0;
        hold on
        while hasFrame(clip)
            video = readFrame(clip);
            video=rgb2gray(video);
            newmean = mean(video(:));
            meanGray = [meanGray; newmean];
            frames = frames + 1;
        end
        %         plot(1:1:frames,meanGray)
        %         %pause(1)
        %         title('Mean Gray Values')
        %         xlabel('Frame Number')
        %         ylabel('Gray')
        % Locate first frame with open eye
        begin =0;
        framefind = 1;
        while begin == 0
            if meanGray(framefind) < ((max(meanGray)-min(meanGray))*.25+min(meanGray))
                startframe = framefind;
                begin = 1;
                %line([startframe startframe],[min(meanGray) max(meanGray)+.1*max(meanGray)])
                %axis tight
            end
            framefind = framefind + 1;
            if framefind > numel(meanGray)
                fprintf('Cant locate start frame\n')
                c{fileNo, 3} = ':(';
                begin = 2;
            end
        end
        if begin == 1
            clip2 = VideoReader([filepath,'\',fileList(fileNo).name]);
            %figure(2)
            counter =0;
            while hasFrame(clip2)
                eye = readFrame(clip2);
                counter = counter + 1;
                if counter < startframe
                    continue
                else
                    if meanGray(counter) == max(meanGray(startframe:end))
                        eye = rgb2gray(eye);
                        eye = imsharpen(eye);
                        %eye = adapthisteq(eye,'clipLimit',0.005,'Distribution','rayleigh');
                        [out,irisIsolated,irisArea,centroid,avgPixelx,avgPixely,pixelList] = IrisDetector(eye);
                        %             video = adapthisteq(eye,'clipLimit',0.02,'Distribution','rayleigh');
                        %             [out2,centers,radii,mask,eye2] = PupilOverlay(video,0,oldcenter);
                        if out == 0
                            break
                        else
                            %RI = imref2d(size(irisIsolated));
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
                            %                 subplot(2,2,4)
                            %                 imshow(eye2);
                            %title(fileList(fileNo).name)
                            %pause()
                            %                         colormap gray
                            %                         set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
                        end
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
    end
    index = strfind(filepath,'Blink9');
    if ~isempty(index)
        c{fileNo+1,1} = ' ';
    end
end
T = cell2table(c,'VariableNames',{'File_Name','Blink_Type','MATLAB_Outcome'});
writetable(T,'Blinks.csv')
elapsed = toc(start);
fprintf('Total elapsed time is %f seconds.\n',elapsed);