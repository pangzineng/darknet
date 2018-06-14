#!/bin/bash

res=$1

docker run --rm \
 -v $(pwd)/cfg:/cfg -v $(pwd)/data:/data -v $(pwd)/weights:/weights -v $(pwd)/test:/test \
 realpixel:v2 \
 data/coco.names cfg/yolov3.cfg weights/yolov3.weights test/test.${res}.mp4 >> test/test.${res}.log