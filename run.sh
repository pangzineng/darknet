#!/bin/bash

res=$1
net=$2
ts=$(date +%s)

docker run --rm --name=realpixel \
 -v $(pwd)/cfg:/cfg -v $(pwd)/data:/data -v $(pwd)/weights:/weights -v $(pwd)/test:/test \
 -e LOGSTASH_HOSTS=logstash:5044 -e KIBANA_HOSTS=kibana:5601 \
 --network=${net} \
 realpixel:dev \
 data/coco.names cfg/yolov3-tiny.cfg weights/yolov3-tiny.weights test/test.${res}.mp4 ${ts} >> test/test.${res}.log