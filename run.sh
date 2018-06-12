#!/bin/bash


docker build -t realpixel:v2 . && 
docker run --rm \
 -v $(pwd)/cfg:/cfg -v $(pwd)/data:/data -v $(pwd)/weights:/weights -v $(pwd)/test:/test \
 realpixel:v2 \
 data/coco.names cfg/yolov3.cfg weights/yolov3.weights test/test.mp4 >> test/test.log