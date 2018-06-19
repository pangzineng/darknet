#!/bin/bash

data=${1}
result=${2}
ts=${3:-$(date +%s)}
job=${4:-standard}

echo "[REALPIXEL] start ${job} realpixel job for ${data}"

if [[ "$job" == "standard" ]]
then
    service filebeat start &&
    echo "[REALPIXEL] ./uselib data/coco.names cfg/yolov3-tiny.cfg weights/yolov3-tiny.weights ${data} ${ts} 2>> ${result}.error 1>> ${result}" &&
    ./uselib data/coco.names cfg/yolov3-tiny.cfg weights/yolov3-tiny.weights ${data} ${ts} 2>> ${result}.error 1>> ${result} &&
    echo "[REALPIXEL] result at: ${result}"
elif [[ "$job" == "full" ]]
then
    service filebeat start &&
    echo "[REALPIXEL] ./uselib data/coco.names cfg/yolov3.cfg weights/yolov3.weights ${data} ${ts} 2>> ${result}.error 1>> ${result}" &&
    ./uselib data/coco.names cfg/yolov3.cfg weights/yolov3.weights ${data} ${ts} 2>> ${result}.error 1>> ${result} &&
    echo "[REALPIXEL] result at: ${result}"
fi

echo "[REALPIXEL] finish ${job} realpixel job for ${data}"
