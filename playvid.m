function playvid(video)
clip = VideoReader(video);
while hasFrame(clip)
    video = readFrame(clip);
    image(video);
    pause(1/clip.FrameRate);
end
end