#!/bin/bash

res=$1
net=$2

docker run -d --rm --name=realpixel \
 -v $(pwd)/test:/test \
 --network=${net} \
 pangzineng/realpixel:dev \
 test/test.${res}.mp4 test.${res}.log