#!/bin/bash

mkdir -p weights
mkdir -p test

## download weights
wget https://pjreddie.com/media/files/yolov3.weights -P weights
wget https://pjreddie.com/media/files/yolov3-tiny.weights -P weights

## download test
youtube-dl -f 136 -o test/test.720p.mp4 https://www.youtube.com/watch?v=3hAvZLndSWg
youtube-dl -f 135 -o test/test.480p.mp4 https://www.youtube.com/watch?v=3hAvZLndSWg
youtube-dl -f 134 -o test/test.360p.mp4 https://www.youtube.com/watch?v=3hAvZLndSWg
youtube-dl -f 133 -o test/test.240p.mp4 https://www.youtube.com/watch?v=3hAvZLndSWg

## build & push the image
docker build -t pangzineng/realpixel:dev . && 
docker push pangzineng/realpixel:dev