#!/bin/bash

res=$1
net=$2

docker run -d --rm --name=realpixel \
 -v $(pwd)/cfg:/cfg -v $(pwd)/data:/data -v $(pwd)/weights:/weights -v $(pwd)/test:/test \
 --network=${net} \
 realpixel:dev \
 test/test.${res}.mp4 test/test.${res}.log